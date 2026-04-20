import FaceBioFlutter
import Flutter
import UIKit

final class FaceDetectionFlutterView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let faceView: FaceDetectionView
    private let livenessSDK: FaceLivenessSDK
    private var eventSink: FlutterEventSink?

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.faceView = FaceDetectionView(frame: frame)
        self.livenessSDK = FaceLivenessSDK.create()

        if let params = args as? [String: Any], let colorInt = params["maskColor"] as? Int {
            let a = CGFloat((colorInt >> 24) & 0xFF) / 255.0
            let r = CGFloat((colorInt >> 16) & 0xFF) / 255.0
            let g = CGFloat((colorInt >> 8)  & 0xFF) / 255.0
            let b = CGFloat(colorInt & 0xFF) / 255.0
            faceView.maskColor = UIColor(red: r, green: g, blue: b, alpha: a)
        }

        super.init()

        FlutterEventChannel(name: "face_detection_events_\(viewId)", binaryMessenger: messenger)
            .setStreamHandler(self)
    }

    func view() -> UIView { faceView }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        faceView.startCamera(
            onStateChanged: { [weak self] state, message in
                self?.eventSink?(["event": "state", "state": state.rawValue, "message": message])
            },
            onImageCaptured: { [weak self] image in
                guard let self else { return }
                Task {
                    let result = await self.livenessSDK.detectLiveness(image)
                    await MainActor.run { [weak self] in
                        self?.eventSink?([
                            "event":      "liveness_result",
                            "prediction": result.model?.prediction ?? "Spoof",
                            "confidence": result.model?.confidence ?? Float(0),
                            "status":     result.model?.status ?? "fail",
                            "message":    result.model?.message ?? "",
                        ])
                    }
                }
            },
            onError: { [weak self] error in
                self?.eventSink?(FlutterError(code: "CAMERA_ERROR", message: error.localizedDescription, details: nil))
            }
        )
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        faceView.stopCamera()
        eventSink = nil
        return nil
    }
}
