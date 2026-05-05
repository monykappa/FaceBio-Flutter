import 'package:facebio_flutter/src/models/face_liveness_result.dart';
import 'package:facebio_flutter/src/models/scan_mode.dart';

class ScanResult {
  final ScanMode mode;
  final String userId;
  final FaceLivenessResult livenessResult;
  final bool apiSuccess;
  final String apiMessage;
  final List<double>? embedding;
  final double? similarity;
  final bool? match;

  const ScanResult({
    required this.mode,
    required this.userId,
    required this.livenessResult,
    required this.apiSuccess,
    required this.apiMessage,
    this.embedding,
    this.similarity,
    this.match,
  });

  bool get success => livenessResult.isLive && apiSuccess;
}
