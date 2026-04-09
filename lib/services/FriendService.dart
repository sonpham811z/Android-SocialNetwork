import 'package:dio/dio.dart';

import '../models/friendModel.dart';
import 'apiClient.dart';
import '../config/environment.dart';

class FriendService {
  final Dio _dio;

  FriendService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: Environment.friendServiceBaseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 50),
            receiveTimeout: const Duration(seconds: 50),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await ApiClient().secureStorage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Exception _mapError(Object e, [String fallback = 'Friend service error']) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = (data['message'] ?? data['Message'] ?? fallback).toString();
        return Exception(msg);
      }
      return Exception(e.message ?? fallback);
    }

    return Exception(e.toString());
  }

  Future<FriendApiResponse<PaginatedResponse<FriendshipModel>>> getMyFriends({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/friends',
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
      throw _mapError(e, 'Failed to load friends');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendshipModel>>>
      getFriendsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/friends/$userId',
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
      throw _mapError(e, 'Failed to load user friends');
    }
  }

  Future<FriendApiResponse<List<String>>> getFriendIds() async {
    try {
      final response = await _dio.get('/friends/ids');

      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => (raw as List<dynamic>).map((e) => e.toString()).toList(),
      );
    } catch (e) {
      throw _mapError(e, 'Failed to load friend IDs');
    }
  }

  Future<FriendApiResponse<dynamic>> unfriend(String targetUserId) async {
    try {
      final response = await _dio.delete('/friends/$targetUserId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to unfriend');
    }
  }

  Future<FriendApiResponse<SocialSummaryModel>> getSocialSummary(
    String userId,
  ) async {
    try {
      final response = await _dio.get('/friends/summary/$userId');
      return FriendApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => SocialSummaryModel.fromJson(raw as Map<String, dynamic>),
      );
    } catch (e) {
      throw _mapError(e, 'Failed to load social summary');
    }
  }

  Future<FriendApiResponse<dynamic>> sendFriendRequest(
      String receiverId) async {
    try {
      final response = await _dio.post(
        '/friends/requests',
        data: {'receiverId': receiverId},
      );

      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to send friend request');
    }
  }

  Future<FriendApiResponse<dynamic>> acceptRequest(String requestId) async {
    try {
      final response = await _dio.put('/friends/requests/$requestId/accept');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to accept request');
    }
  }

  Future<FriendApiResponse<dynamic>> declineRequest(String requestId) async {
    try {
      final response = await _dio.put('/friends/requests/$requestId/decline');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to decline request');
    }
  }

  Future<FriendApiResponse<dynamic>> cancelRequest(String requestId) async {
    try {
      final response = await _dio.delete('/friends/requests/$requestId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to cancel request');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendRequestModel>>>
      getSentRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/friends/requests/sent',
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
      throw _mapError(e, 'Failed to load sent requests');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FriendRequestModel>>>
      getReceivedRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/friends/requests/received',
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
      throw _mapError(e, 'Failed to load received requests');
    }
  }

  Future<FriendApiResponse<dynamic>> follow(String followeeId) async {
    try {
      final response = await _dio.post('/follows/$followeeId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to follow user');
    }
  }

  Future<FriendApiResponse<dynamic>> unfollow(String followeeId) async {
    try {
      final response = await _dio.delete('/follows/$followeeId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to unfollow user');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FollowModel>>> getFollowers(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/follows/followers/$userId',
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
      throw _mapError(e, 'Failed to load followers');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<FollowModel>>> getFollowing(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/follows/following/$userId',
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
      throw _mapError(e, 'Failed to load following users');
    }
  }

  Future<FriendApiResponse<dynamic>> blockUser(String blockedId) async {
    try {
      final response = await _dio.post('/blocks/$blockedId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to block user');
    }
  }

  Future<FriendApiResponse<dynamic>> unblockUser(String blockedId) async {
    try {
      final response = await _dio.delete('/blocks/$blockedId');
      return FriendApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (raw) => raw,
      );
    } catch (e) {
      throw _mapError(e, 'Failed to unblock user');
    }
  }

  Future<FriendApiResponse<PaginatedResponse<BlockModel>>> getBlockedUsers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/blocks',
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
      throw _mapError(e, 'Failed to load blocked users');
    }
  }
}
