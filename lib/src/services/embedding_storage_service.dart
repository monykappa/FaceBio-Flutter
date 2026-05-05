import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmbeddingStorageService {
  String _keyForUser(String userId) => 'embedding_$userId';

  Future<void> saveEmbedding({
    required String userId,
    required List<double> embedding,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = jsonEncode(embedding);
    await preferences.setString(_keyForUser(userId), payload);
  }

  Future<List<double>?> readEmbedding(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = preferences.getString(_keyForUser(userId));
    if (payload == null) {
      return null;
    }
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .map((value) => (value as num).toDouble())
        .toList(growable: false);
  }
}
