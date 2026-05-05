import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:facebio_flutter/src/config/api_config.dart';
import 'package:facebio_flutter/src/models/register_response.dart';
import 'package:facebio_flutter/src/models/verify_response.dart';

class FaceApiException implements Exception {
  final String message;

  const FaceApiException(this.message);

  @override
  String toString() => message;
}

class FaceApiService {
  String get _basicAuthorization {
    if (ApiConfig.basicAuthHeaderOverride.trim().isNotEmpty) {
      return ApiConfig.basicAuthHeaderOverride.trim();
    }

    final raw = '${ApiConfig.basicAuthUsername}:${ApiConfig.basicAuthPassword}';
    return 'Basic ${base64Encode(utf8.encode(raw))}';
  }

  Future<RegisterResponse> registerFace({
    required String userId,
    required String imagePath,
    bool isAuthorized = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/img/register').replace(
      queryParameters: <String, String>{
        'user_id': userId,
        'is_authorized': isAuthorized.toString(),
      },
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(<String, String>{
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: _basicAuthorization,
      })
      ..files.add(await http.MultipartFile.fromPath('source_file', imagePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw FaceApiException(
        'Register request failed (${response.statusCode}): $body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return RegisterResponse.fromJson(decoded);
  }

  Future<VerifyResponse> verifyFace({
    required String userId,
    required String imagePath,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/img/verify',
    ).replace(queryParameters: <String, String>{'user_id': userId});

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(<String, String>{
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: _basicAuthorization,
      })
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw FaceApiException(
        'Verify request failed (${response.statusCode}): $body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return VerifyResponse.fromJson(decoded);
  }
}
