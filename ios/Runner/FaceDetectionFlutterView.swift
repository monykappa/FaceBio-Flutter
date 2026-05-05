import FaceBioFlutter
import Flutter
import UIKit

final class FaceDetectionFlutterView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let faceView: FaceDetectionView
    private let livenessSDK: FaceLivenessSDK
    private var eventSink: FlutterEventSink?
    private var lastState: String?
    private var lastMessage: String?

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
        lastState = nil
        lastMessage = nil
        faceView.startCamera(
            onStateChanged: { [weak self] state, message in
                guard let self else { return }
                let stateValue = state.rawValue
                if lastState == stateValue, lastMessage == message {
                    return
                }
                lastState = stateValue
                lastMessage = message
                eventSink?(["event": "state", "state": stateValue, "message": message])
            },
            onImageCaptured: { [weak self] image in
                guard let self else { return }
                Task {
                    guard let imagePath = self.saveImageToTemporary(image) else {
                        await MainActor.run { [weak self] in
                            self?.eventSink?(
                                FlutterError(
                                    code: "IMAGE_SAVE_ERROR",
                                    message: "Failed to save captured image",
                                    details: nil
                                )
                            )
                        }
                        return
                    }

                    let result = await self.livenessSDK.detectLiveness(image)
                    await MainActor.run { [weak self] in
                        self?.eventSink?([
                            "event":      "liveness_result",
                            "prediction": result.model?.prediction ?? "Spoof",
                            "confidence": result.model?.confidence ?? Float(0),
                            "status":     result.model?.status ?? "fail",
                            "message":    result.model?.message ?? "",
                            "imagePath":  imagePath,
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

    private func saveImageToTemporary(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.95) else {
            return nil
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("face_\(UUID().uuidString).jpg")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            return nil
        }
    }
}
