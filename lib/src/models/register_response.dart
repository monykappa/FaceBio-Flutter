class RegisterResponse {
  final String status;
  final int code;
  final String message;
  final RegisterData data;

  const RegisterResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      status: json['status'] as String,
      code: json['code'] as int,
      message: json['message'] as String,
      data: RegisterData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class RegisterData {
  final String userId;
  final List<double> embedding;

  const RegisterData({required this.userId, required this.embedding});

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    final rawEmbedding = json['embedding'] as List<dynamic>;
    return RegisterData(
      userId: json['user_id'] as String,
      embedding: rawEmbedding
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
    );
  }
}
