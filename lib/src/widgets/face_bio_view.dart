import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facebio_flutter/src/models/face_liveness_result.dart';
import 'dart:async';

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
  StreamSubscription<dynamic>? _eventSubscription;

  void _onPlatformViewCreated(int viewId) {
    _eventChannel = EventChannel('face_detection_events_$viewId');
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        final map = Map<String, dynamic>.from(event as Map);
        final eventType = map['event'] as String?;
        if (eventType == 'state') {
          widget.onStateChanged?.call(
            map['state'] as String? ?? '',
            map['message'] as String? ?? '',
          );
          return;
        }

        if (eventType == 'liveness_result') {
          widget.onResult(
            FaceLivenessResult(
              prediction: map['prediction'] as String? ?? '',
              confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
              status: map['status'] as String? ?? 'fail',
              message: map['message'] as String? ?? '',
              imagePath: map['imagePath'] as String?,
            ),
          );
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
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AspectRatio(
        aspectRatio: 1,
        child: AndroidView(
          viewType: 'face_detection_view',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: <String, dynamic>{
            'maskColor': widget.maskColor.toARGB32(),
          },
        ),
      );
    }

    if (Platform.isIOS) {
      return AspectRatio(
        aspectRatio: 1,
        child: UiKitView(
          viewType: 'face_detection_view',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: <String, dynamic>{
            'maskColor': widget.maskColor.toARGB32(),
          },
        ),
      );
    }

    return const Center(child: Text('Platform not supported'));
  }
}
