import 'package:dio/dio.dart';

import '../config/environment.dart';
import 'apiClient.dart';
import '../models/userModel.dart';

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
    final dataRaw = json['data'] ?? json['Data'] ?? json['result'] ?? json['Result'];
    return UserProfileResponse(
      success: _parseBool(json['success'] ?? json['Success'] ?? json['isSuccess'] ?? json['IsSuccess']) || dataRaw != null,
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

  String get _userProfileBaseUrl => '${Environment.userServiceBaseUrl}/userprofile';

  User? _parseUserResponse(dynamic rawData) {
    if (rawData == null) {
      return null;
    }

    if (rawData is Map<String, dynamic>) {
      final hasEnvelope = rawData.containsKey('success') ||
          rawData.containsKey('Success') ||
          rawData.containsKey('data') ||
          rawData.containsKey('Data') ||
          rawData.containsKey('message') ||
          rawData.containsKey('Message');

      if (hasEnvelope) {
        final parsed = UserProfileResponse<User>.fromJson(
          rawData,
          (json) => User.fromJson((json as Map).cast<String, dynamic>()),
        );

        if (parsed.success && parsed.data != null) {
          return parsed.data;
        }

        throw Exception(parsed.message.isEmpty ? 'Failed to load profile data.' : parsed.message);
      }

      return User.fromJson(rawData);
    }

    if (rawData is Map) {
      return User.fromJson(rawData.cast<String, dynamic>());
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

      final body = response.data;
      if (body is Map<String, dynamic>) {
        final url = (body['data'] ?? body['Data'])?.toString();
        if ((url ?? '').isNotEmpty) {
          return url!;
        }
        throw Exception((body['message'] ?? body['Message'] ?? 'Upload profile picture failed.').toString());
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

      final body = response.data;
      if (body is Map<String, dynamic>) {
        final url = (body['data'] ?? body['Data'])?.toString();
        if ((url ?? '').isNotEmpty) {
          return url!;
        }
        throw Exception((body['message'] ?? body['Message'] ?? 'Upload cover photo failed.').toString());
      }

      throw Exception('Invalid upload response format.');
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}