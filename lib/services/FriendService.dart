import 'package:dio/dio.dart';

import '../models/friendModel.dart';
import 'apiClient.dart';
import '../config/environment.dart';

class FriendService {
  final ApiClient _apiClient = ApiClient();
  final String _baseUrl = Environment.friendServiceBaseUrl;

  // Xài chung hàm parse lỗi siêu việt từ ApiClient cho đồng bộ nha bro
  Exception _mapError(Object e) {
    if (e is DioException) {
      return Exception(ApiClient.buildReadableErrorMessage(e));
    }
    return Exception(e.toString());
  }

  Future<FriendApiResponse<PaginatedResponse<FriendshipModel>>> getMyFriends({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/friends',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FriendshipModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendshipModel>>>
      getFriendsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/friends/$userId',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FriendshipModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<List<String>>> getFriendIds() async {
    try {
      final response = await _apiClient.dio.get('$_baseUrl/friends/ids');

      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => (raw as List<dynamic>).map((e) => e.toString()).toList(),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> unfriend(String targetUserId) async {
    try {
      final response = await _apiClient.dio.delete('$_baseUrl/friends/$targetUserId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<SocialSummaryModel>> getSocialSummary(
    String userId,
  ) async {
    try {
      final response = await _apiClient.dio.get('$_baseUrl/friends/summary/$userId');
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => SocialSummaryModel.fromJson(raw as Map<String, dynamic>),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> sendFriendRequest(
      String receiverId) async {
    try {
      final response = await _apiClient.dio.post(
        '$_baseUrl/friends/requests',
        data: {'receiverId': receiverId},
      );

      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> acceptRequest(String requestId) async {
    try {
      final response = await _apiClient.dio.put('$_baseUrl/friends/requests/$requestId/accept');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> declineRequest(String requestId) async {
    try {
      final response = await _apiClient.dio.put('$_baseUrl/friends/requests/$requestId/decline');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> cancelRequest(String requestId) async {
    try {
      final response = await _apiClient.dio.delete('$_baseUrl/friends/requests/$requestId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendRequestModel>>>
      getSentRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/friends/requests/sent',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FriendRequestModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendRequestModel>>>
      getReceivedRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/friends/requests/received',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FriendRequestModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> follow(String followeeId) async {
    try {
      final response = await _apiClient.dio.post('$_baseUrl/follows/$followeeId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> unfollow(String followeeId) async {
    try {
      final response = await _apiClient.dio.delete('$_baseUrl/follows/$followeeId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FollowModel>>> getFollowers(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/follows/followers/$userId',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FollowModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FollowModel>>> getFollowing(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/follows/following/$userId',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          FollowModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> blockUser(String blockedId) async {
    try {
      final response = await _apiClient.dio.post('$_baseUrl/blocks/$blockedId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<dynamic>> unblockUser(String blockedId) async {
    try {
      final response = await _apiClient.dio.delete('$_baseUrl/blocks/$blockedId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<FriendApiResponse<PaginatedResponse<BlockModel>>> getBlockedUsers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_baseUrl/blocks',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => PaginatedResponse.fromJson(
          raw as Map<String, dynamic>,
          BlockModel.fromJson,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
  }
}