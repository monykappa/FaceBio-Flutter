package com.acleda.facebio_flutter

import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var factory: FaceDetectionViewFactory? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        factory = FaceDetectionViewFactory(flutterEngine.dartExecutor.binaryMessenger).also {
            it.lifecycleOwner = this as LifecycleOwner
            flutterEngine.platformViewsController
                .registry
                .registerViewFactory("face_detection_view", it)
        }
    }
}
