class FaceLivenessResult {
  final String prediction;
  final double confidence;
  final String status;
  final String message;
  final String? imagePath;

  const FaceLivenessResult({
    required this.prediction,
    required this.confidence,
    required this.status,
    required this.message,
    required this.imagePath,
  });

  bool get isLive => status.toLowerCase() == 'pass';
}
