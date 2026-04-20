import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaceLivenessResult {
  final String prediction;
  final double confidence;
  final String status;
  final String message;

  const FaceLivenessResult({
    required this.prediction,
    required this.confidence,
    required this.status,
    required this.message,
  });

  bool get isLive => status == 'pass';

  @override
  String toString() =>
      'FaceLivenessResult(prediction: $prediction, confidence: ${(confidence * 100).toStringAsFixed(1)}%, status: $status)';
}

class FaceBioView extends StatefulWidget {
  final void Function(FaceLivenessResult result) onResult;
  final void Function(String state, String message)? onStateChanged;
  final void Function(String code, String? message)? onError;
  final Color maskColor;

  const FaceBioView({
    super.key,
    required this.onResult,
    this.onStateChanged,
    this.onError,
    this.maskColor = Colors.black,
  });

  @override
  State<FaceBioView> createState() => _FaceBioViewState();
}

class _FaceBioViewState extends State<FaceBioView> {
  EventChannel? _eventChannel;

  void _onPlatformViewCreated(int viewId) {
    _eventChannel = EventChannel('face_detection_events_$viewId');
    _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        final map = Map<String, dynamic>.from(event as Map);
        switch (map['event'] as String) {
          case 'state':
            widget.onStateChanged?.call(
              map['state'] as String,
              map['message'] as String,
            );
            break;
          case 'liveness_result':
            widget.onResult(FaceLivenessResult(
              prediction: map['prediction'] as String,
              confidence: (map['confidence'] as num).toDouble(),
              status: map['status'] as String,
              message: map['message'] as String? ?? '',
            ));
            break;
        }
      },
      onError: (dynamic error) {
        if (error is PlatformException) {
          widget.onError?.call(error.code, error.message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: AndroidView(
          viewType: 'face_detection_view',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {'maskColor': widget.maskColor.toARGB32()},
        ),
      );
    }
    if (Platform.isIOS) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: UiKitView(
          viewType: 'face_detection_view',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {'maskColor': widget.maskColor.toARGB32()},
        ),
      );
    }
    return const Center(child: Text('Platform not supported'));
  }
}
