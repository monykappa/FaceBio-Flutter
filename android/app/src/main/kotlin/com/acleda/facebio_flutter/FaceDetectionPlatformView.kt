package com.acleda.facebio_flutter

import android.content.Context
import android.view.View
import androidx.lifecycle.LifecycleOwner
import com.acleda.facebioflutter.camera.FaceDetectionView
import com.acleda.facebioflutter.face.faceliveness.FaceLivenessSDK
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
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

    private val cameraView = FaceDetectionView(context)
    private val livenessSDK = FaceLivenessSDK.create(context)
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

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
        cameraView.startCamera(
            lifecycleOwner = owner,
            onStateChanged = { state, message, _, _, _, _, _ ->
                sink.success(mapOf(
                    "event"   to "state",
                    "state"   to state.name,
                    "message" to message
                ))
            },
            onImageCaptured = { bitmap ->
                scope.launch {
                    val result = livenessSDK.detectLiveness(bitmap)
                    sink.success(mapOf(
                        "event"      to "liveness_result",
                        "prediction" to (result.model?.prediction ?: "Spoof"),
                        "confidence" to (result.model?.confidence ?: 0f),
                        "status"     to (result.model?.status ?: "fail"),
                        "message"    to (result.model?.message ?: "")
                    ))
                }
            },
            onError = { e ->
                sink.error("CAMERA_ERROR", e.message, null)
            }
        )
    }

    override fun getView(): View = cameraView

    override fun dispose() {
        cameraView.stopCamera()
        scope.launch { livenessSDK.closeResources() }
        scope.cancel()
    }
}
