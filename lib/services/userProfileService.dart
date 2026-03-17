import 'package:dio/dio.dart';

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
    return UserProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class UserProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<User?> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/userprofile/me');

      final parsed = UserProfileResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (parsed.success && parsed.data != null) {
        return parsed.data;
      }

      throw Exception(parsed.message);
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<User?> updateMyProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _apiClient.dio.put(
        '/userprofile',
        data: updateData,
      );

      final parsed = UserProfileResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (parsed.success && parsed.data != null) {
        return parsed.data;
      }

      throw Exception(parsed.message);
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

