import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import '../models/agoraModel.dart';

class AgoraService {
  final _storage = const FlutterSecureStorage();

  Future<AgoraTokenResponse> getCallToken(String channelName, {bool isVideo = false}) async {
    final authToken = await _storage.read(key: 'accessToken');
    final uri = Uri.parse(
      '${Environment.messageServiceBaseUrl}/call/token'
      '?channelName=${Uri.encodeComponent(channelName)}&isVideo=$isVideo',
    );

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $authToken',
    });

    if (response.statusCode != 200) {
      throw Exception('Không thể lấy Agora token: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AgoraTokenResponse.fromJson(body['data'] as Map<String, dynamic>);
  }
}
