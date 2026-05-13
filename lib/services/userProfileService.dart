import 'package:dio/dio.dart';

import '../config/environment.dart';
import 'apiClient.dart';
import '../models/userModel.dart';
import '../utils/json_helpers.dart';

class UserSearchResult {
  final String id;
  final String username;
  final String fullName;
  final String? profilePictureUrl;
  final bool isVerified;
  final String? location;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePictureUrl,
    this.isVerified = false,
    this.location,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      profilePictureUrl:
          (json['profilePictureUrl'] ?? json['ProfilePictureUrl'])?.toString(),
      isVerified: UserProfileResponse._parseBool(
        json['isVerified'] ?? json['IsVerified'],
      ),
      location: (json['location'] ?? json['Location'])?.toString(),
    );
  }
}

class UserProfileResponse<T> {
  final bool success;
  final String message;
  final T? data;

  UserProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final dataRaw =
        json['data'] ?? json['Data'] ?? json['result'] ?? json['Result'];
    return UserProfileResponse(
      success: _parseBool(json['success'] ??
              json['Success'] ??
              json['isSuccess'] ??
              json['IsSuccess']) ||
          dataRaw != null,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      data: dataRaw != null ? fromJsonT(dataRaw) : null,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == null) {
      return false;
    }

    final normalized = value.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}

class UserProfileService {
  final ApiClient _apiClient = ApiClient();

  String get _userProfileBaseUrl =>
      '${Environment.userServiceBaseUrl}/userprofile';

  User? _parseUserResponse(dynamic rawData) {
    if (rawData == null) {
      return null;
    }

    final mapData = asJsonMap(rawData);
    if (mapData != null) {
      final hasEnvelope = mapData.containsKey('success') ||
          mapData.containsKey('Success') ||
          mapData.containsKey('data') ||
          mapData.containsKey('Data') ||
          mapData.containsKey('message') ||
          mapData.containsKey('Message');

      if (hasEnvelope) {
        final parsed = UserProfileResponse<User>.fromJson(
          mapData,
          (json) => User.fromJson(asJsonMap(json) ?? const <String, dynamic>{}),
        );

        if (parsed.success && parsed.data != null) {
return parsed.data;
        }

        throw Exception(parsed.message.isEmpty
            ? 'Failed to load profile data.'
            : parsed.message);
      }

      return User.fromJson(mapData);
    }

    throw Exception('Invalid profile response format.');
  }

  Future<User?> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('$_userProfileBaseUrl/me');
      return _parseUserResponse(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<User?> getProfileByUsername(String username) async {
    try {
      final response = await _apiClient.dio.get(
        '$_userProfileBaseUrl/username/${Uri.encodeComponent(username)}',
      );
      return _parseUserResponse(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<UserSearchResult>> searchUsersByUsername(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$_userProfileBaseUrl/search',
        queryParameters: {
          'q': query,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final body = asJsonMap(response.data);
      if (body == null) {
        throw Exception('Invalid search response format.');
      }

      final success = UserProfileResponse._parseBool(
        body['success'] ?? body['Success'] ?? body['isSuccess'] ?? body['IsSuccess'],
      );
      if (!success) {
        throw Exception((body['message'] ?? body['Message'] ?? 'Search failed').toString());
      }

      final data = asJsonMap(body['data'] ?? body['Data']) ?? <String, dynamic>{};
      final rawItems = asJsonList(data['items'] ?? data['Items']) ?? const <dynamic>[];

      return rawItems
          .map((item) => UserSearchResult.fromJson(asJsonMap(item) ?? <String, dynamic>{}))
          .where((item) => item.username.trim().isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<User?> updateMyProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _apiClient.dio.put(
        _userProfileBaseUrl,
        data: updateData,
      );
      return _parseUserResponse(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> uploadProfilePicture(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
'$_userProfileBaseUrl/upload-profile-picture',
        data: formData,
      );

      final body = asJsonMap(response.data);
      if (body != null) {
        final url = (body['data'] ?? body['Data'])?.toString();
        if ((url ?? '').isNotEmpty) {
          return url!;
        }
        throw Exception((body['message'] ??
                body['Message'] ??
                'Upload profile picture failed.')
            .toString());
      }

      throw Exception('Invalid upload response format.');
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> uploadCoverPhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        '$_userProfileBaseUrl/upload-cover-photo',
        data: formData,
      );

      final body = asJsonMap(response.data);
      if (body != null) {
        final url = (body['data'] ?? body['Data'])?.toString();
        if ((url ?? '').isNotEmpty) {
          return url!;
        }
        throw Exception(
            (body['message'] ?? body['Message'] ?? 'Upload cover photo failed.')
                .toString());
      }

      throw Exception('Invalid upload response format.');
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}