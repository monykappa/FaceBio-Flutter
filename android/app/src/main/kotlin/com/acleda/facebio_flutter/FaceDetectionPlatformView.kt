package com.acleda.facebio_flutter

import android.content.Context
import android.graphics.Bitmap
import android.view.View
import androidx.lifecycle.LifecycleOwner
import com.acleda.facebioflutter.camera.FaceDetectionView
import com.acleda.facebioflutter.face.faceliveness.FaceLivenessSDK
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class FaceDetectionPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    private val lifecycleOwner: LifecycleOwner?,
    args: Any?
) : PlatformView {

    private val appContext = context
    private val cameraView = FaceDetectionView(context)
    private val livenessSDK = FaceLivenessSDK.create(context)
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var lastState: String? = null
    private var lastMessage: String? = null

    init {
        (args as? Map<*, *>)?.get("maskColor")?.let { color ->
            cameraView.setMaskColor((color as Number).toInt())
        }
        EventChannel(messenger, "face_detection_events_$viewId")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    startCamera(sink)
                }
                override fun onCancel(args: Any?) {
                    cameraView.stopCamera()
                }
            })
    }

    private fun startCamera(sink: EventChannel.EventSink) {
        val owner = lifecycleOwner ?: run {
            sink.error("NO_LIFECYCLE", "Lifecycle not available", null)
            return
        }
        lastState = null
        lastMessage = null
        cameraView.startCamera(
            lifecycleOwner = owner,
            onStateChanged = { state, message, _, _, _, _, _ ->
                if (lastState == state.name && lastMessage == message) {
                    return@startCamera
                }
                lastState = state.name
                lastMessage = message
                sink.success(mapOf(
                    "event"   to "state",
                    "state"   to state.name,
                    "message" to message
                ))
            },
            onImageCaptured = { bitmap ->
                scope.launch {
                    val imagePath = saveImageToCache(bitmap)
                    if (imagePath == null) {
                        sink.error("IMAGE_SAVE_ERROR", "Failed to save captured image", null)
                        return@launch
                    }

                    val result = livenessSDK.detectLiveness(bitmap)
                    sink.success(mapOf(
                        "event"      to "liveness_result",
                        "prediction" to (result.model?.prediction ?: "Spoof"),
                        "confidence" to (result.model?.confidence ?: 0f),
                        "status"     to (result.model?.status ?: "fail"),
                        "message"    to (result.model?.message ?: ""),
                        "imagePath"  to imagePath
                    ))
                }
            },
            onError = { e ->
                sink.error("CAMERA_ERROR", e.message, null)
            }
        )
    }

    private fun saveImageToCache(bitmap: Bitmap): String? {
        val outputFile = File(appContext.cacheDir, "face_${System.currentTimeMillis()}.jpg")
        return try {
            FileOutputStream(outputFile).use { output ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 95, output)
                output.flush()
            }
            outputFile.absolutePath
        } catch (_: IOException) {
            null
        }
    }

    override fun getView(): View = cameraView

    override fun dispose() {
        cameraView.stopCamera()
        scope.launch { livenessSDK.closeResources() }
        scope.cancel()
    }
}
