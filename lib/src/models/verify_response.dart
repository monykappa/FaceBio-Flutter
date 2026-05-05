class VerifyResponse {
  final String status;
  final int code;
  final String message;
  final VerifyData data;

  const VerifyResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
  });

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      status: json['status'] as String,
      code: json['code'] as int,
      message: json['message'] as String,
      data: VerifyData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class VerifyData {
  final String userId;
  final double similarity;
  final bool match;

  const VerifyData({
    required this.userId,
    required this.similarity,
    required this.match,
  });

  factory VerifyData.fromJson(Map<String, dynamic> json) {
    return VerifyData(
      userId: json['user_id'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      match: json['match'] as bool,
    );
  }
}
