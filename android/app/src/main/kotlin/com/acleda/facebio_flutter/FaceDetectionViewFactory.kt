package com.acleda.facebio_flutter

import android.content.Context
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FaceDetectionViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    var lifecycleOwner: LifecycleOwner? = null

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return FaceDetectionPlatformView(context, messenger, viewId, lifecycleOwner, args)
    }
}
