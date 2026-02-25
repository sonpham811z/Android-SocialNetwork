import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'apiClient.dart';

class RegisterData {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;

  RegisterData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
  });

   Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
  };
}

class LoginData {
  final String email;
  final String password;

  LoginData({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class UserData {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isEmailConfirmed;

  UserData({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isEmailConfirmed,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isEmailConfirmed: json['isEmailConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'isEmailConfirmed': isEmailConfirmed,
  };

  String get fullName => '$firstName $lastName';
}

class AuthResponseData {
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
  final UserData user;

  AuthResponseData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    return AuthResponseData(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresAt: json['expiresAt'] ?? '',
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final AuthResponseData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? AuthResponseData.fromJson(json['data']) 
          : null,
    );
  }
}

class ApiError {
  final bool success;
  final String message;
  final List<String>? errors;

  ApiError({
    required this.success,
    required this.message,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An error occurred',
      errors: json['errors'] != null 
          ? List<String>.from(json['errors']) 
          : null,
    );
  }
}

class AuthService {
  final ApiClient _apiClient = ApiClient();

  //register
  Future<AuthResponse> register(RegisterData data) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: data.toJson()
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if(authResponse.success && authResponse.data != null) {
        await _apiClient.secureStorage.write(key: 'accessToken', value: authResponse.data!.accessToken);
      }

      return authResponse;
    }on DioException catch (e) {
      if(e.response != null) 
      {
        throw ApiError.fromJson(e.response!.data);
      }
      throw ApiError(success: false, message: 'Registration failed: ${e.message}');
    } catch (e) {
      throw ApiError(success: false, message: 'Registration failed: ${e.toString()}');
    }
  }

   Future<AuthResponse> login(LoginData data) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: data.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        // Save access token to secure storage (expires in 15 minutes)
        await _apiClient.secureStorage.write(
          key: 'accessToken',
          value: authResponse.data!.accessToken,
        );
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiError.fromJson(e.response!.data);
      }
      throw ApiError(
        success: false,
        message: 'Login failed: ${e.message}',
      );
    } catch (e) {
      throw ApiError(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Google Login
  Future<AuthResponse> googleLogin(String idToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _apiClient.secureStorage.write(
          key: 'accessToken',
          value: authResponse.data!.accessToken,
        );
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiError.fromJson(e.response!.data);
      }
      throw ApiError(
        success: false,
        message: 'Google login failed: ${e.message}',
      );
    } catch (e) {
      throw ApiError(
        success: false,
        message: 'Google login failed: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout API
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Always clear auth data locally
      await _apiClient.clearAuth();
    }
  }

  // Get current user from JWT token
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await _apiClient.secureStorage.read(key: 'accessToken');
      
      if (token == null) return null;

      // Decode JWT token (without verification, just decode)
      final payload = Jwt.parseJwt(token);
      return payload;
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _apiClient.secureStorage.read(key: 'accessToken');
    return token != null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _apiClient.secureStorage.read(key: 'accessToken');
  }
}

