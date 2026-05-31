import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/boardModel.dart';
import 'apiClient.dart';

class BoardService {
  final ApiClient _apiClient = ApiClient();

  String get _base => '${Environment.postServiceBaseUrl}/board';

  Future<BoardPostsResult> getPosts({
    String? tag,
    String sort = 'hot',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        _base,
        queryParameters: {
          if (tag != null) 'tag': tag,
          'sort': sort,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _extractResult(response.data);
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<BoardPost?> createPost({
    required String tag,
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        _base,
        data: {'tag': tag, 'content': content, 'isAnonymous': isAnonymous},
      );
      final data = _readData(response.data);
      if (data is Map<String, dynamic>) return BoardPost.fromJson(data);
      return null;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<bool> vote(String postId, String voteType) async {
    try {
      await _apiClient.dio.post(
        '$_base/$postId/vote',
        data: {'voteType': voteType},
      );
      return true;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<bool> deleteVote(String postId) async {
    try {
      await _apiClient.dio.delete('$_base/$postId/vote');
      return true;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _apiClient.dio.delete('$_base/$postId');
      return true;
    } on DioException catch (e) {
      throw Exception(ApiClient.buildReadableErrorMessage(e));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  BoardPostsResult _extractResult(dynamic raw) {
    if (raw is! Map) return const BoardPostsResult(posts: [], total: 0);
    final map = raw.cast<String, dynamic>();
    final data = map['data'] ?? map['Data'];
    if (data is! Map) return const BoardPostsResult(posts: [], total: 0);
    final dataMap = data.cast<String, dynamic>();
    final items = dataMap['items'] ?? dataMap['Items'];
    final total = (dataMap['totalItems'] ?? dataMap['TotalItems'] ?? 0) as int;
    if (items is! List) return BoardPostsResult(posts: [], total: total);
    final posts = items
        .whereType<Map>()
        .map((e) => BoardPost.fromJson(e.cast<String, dynamic>()))
        .toList();
    return BoardPostsResult(posts: posts, total: total);
  }

  dynamic _readData(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return map['data'] ?? map['Data'];
    }
    return null;
  }
}

class BoardPostsResult {
  final List<BoardPost> posts;
  final int total;
  const BoardPostsResult({required this.posts, required this.total});
}
