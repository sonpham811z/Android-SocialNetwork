import 'package:dio/dio.dart';

import '../config/environment.dart';
import '../models/feedModel.dart';
import 'apiClient.dart';

class PostService {
  final ApiClient _apiClient = ApiClient();

  String get _postBaseUrl => '${Environment.postServiceBaseUrl}/post';

  Future<List<Post>> getFeed({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '$_postBaseUrl/feed',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _extractPosts(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<List<Post>> getUserPosts(String userId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '$_postBaseUrl/user/$userId',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _extractPosts(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<Post?> createTextPost({required String content, String visibility = 'Public'}) async {
    try {
      final response = await _apiClient.dio.post(
        '$_postBaseUrl/text',
        data: {'content': content, 'visibility': visibility},
      );

      final payload = _readData(response.data);
      if (payload is Map<String, dynamic>) {
        return Post.fromApi(payload);
      }
      if (payload is Map) {
        return Post.fromApi(payload.cast<String, dynamic>());
      }
      return null;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<Post?> createImagePost({
    required String content,
    required String imagePath,
    String visibility = 'Public',
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': content,
        'visibility': visibility,
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.dio.post(
        '$_postBaseUrl/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _extractSinglePost(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<Post?> createVoicePost({
    required String content,
    required String audioPath,
    String visibility = 'Public',
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': content,
        'visibility': visibility,
        'audio': await MultipartFile.fromFile(audioPath),
      });

      final response = await _apiClient.dio.post(
        '$_postBaseUrl/voice',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _extractSinglePost(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _apiClient.dio.post('$_postBaseUrl/$postId/like');
      return _extractSuccess(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<bool> unlikePost(String postId) async {
    try {
      final response = await _apiClient.dio.delete('$_postBaseUrl/$postId/like');
      return _extractSuccess(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _apiClient.dio.get('$_postBaseUrl/$postId/comments');
      final payload = _readData(response.data);

      if (payload is List) {
        return payload
            .whereType<Map>()
            .map((item) => Comment.fromApi(item.cast<String, dynamic>()))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<Comment?> createComment(String postId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '$_postBaseUrl/$postId/comments',
        data: {'content': content},
      );

      final payload = _readData(response.data);
      if (payload is Map<String, dynamic>) {
        return Comment.fromApi(payload);
      }
      if (payload is Map) {
        return Comment.fromApi(payload.cast<String, dynamic>());
      }
      return null;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Post? _extractSinglePost(dynamic raw) {
    final payload = _readData(raw);
    if (payload is Map<String, dynamic>) {
      return Post.fromApi(payload);
    }
    if (payload is Map) {
      return Post.fromApi(payload.cast<String, dynamic>());
    }
    return null;
  }

  bool _extractSuccess(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final success = map['success'] ?? map['Success'];
      if (success is bool) {
        return success;
      }
    }
    return true;
  }

  List<Post> _extractPosts(dynamic raw) {
    final payload = _readData(raw);

    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => Post.fromApi(item.cast<String, dynamic>()))
            .toList();
      }
    }

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Post.fromApi(item.cast<String, dynamic>()))
          .toList();
    }

    return [];
  }

  dynamic _readData(dynamic raw) {
    if (raw is! Map) {
      return raw;
    }

    final map = raw.cast<String, dynamic>();
    if (map.containsKey('data')) {
      return map['data'];
    }
    if (map.containsKey('Data')) {
      return map['Data'];
    }
    return map;
  }
}
