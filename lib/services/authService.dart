import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'apiClient.dart';
import '../utils/json_helpers.dart';

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

class ChangePasswordData {
  final String currentPassword;
  final String newPassword;

  ChangePasswordData({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
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
      accessToken:
          (json['accessToken'] ?? json['AccessToken'] ?? '').toString(),
      refreshToken:
          (json['refreshToken'] ?? json['RefreshToken'] ?? '').toString(),
      expiresAt: (json['expiresAt'] ?? json['ExpiresAt'] ?? '').toString(),
      user: UserData.fromJson(
          asJsonMap(json['user'] ?? json['User']) ?? const <String, dynamic>{}),
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
    final dataRaw = json['data'] ?? json['Data'];
    return AuthResponse(
      success: (json['success'] ?? json['Success'] ?? false) == true,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      data: dataRaw is Map<String, dynamic>
          ? AuthResponseData.fromJson(dataRaw)
          : dataRaw is Map
              ? AuthResponseData.fromJson(dataRaw.cast<String, dynamic>())
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
    List<String>? parsedErrors;

    if (json['errors'] != null) {
      parsedErrors = [];

      // Trường hợp 1: Backend trả về 1 mảng (List) bình thường
      if (json['errors'] is List) {
        parsedErrors = List<String>.from(json['errors']);
      }
      // Trường hợp 2: Backend trả về 1 cục Map (ví dụ lỗi Validation của ASP.NET)
      else if (json['errors'] is Map) {
        final errorMap = asJsonMap(json['errors']) ?? <String, dynamic>{};
        errorMap.forEach((key, value) {
          if (value is List) {
            // Nếu value là mảng ["lỗi 1", "lỗi 2"]
            parsedErrors!.addAll(List<String>.from(value));
          } else {
            // Nếu value chỉ là text bình thường
            parsedErrors!.add(value.toString());
          }
        });
      }
    }

    return ApiError(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An error occurred',
      errors: (parsedErrors != null && parsedErrors.isNotEmpty)
          ? parsedErrors
          : null,
    );
  }

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return 'ApiError: $message - ${errors!.join(', ')}';
    }
    return 'ApiError: $message';
  }
}

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _requireMap(dynamic value) {
    final map = asJsonMap(value);
    if (map == null) {
      throw ApiError(success: false, message: 'Invalid auth response format.');
    }
    return map;
  }

  bool _hasValidTokens(AuthResponse response) {
    final access = response.data?.accessToken.trim() ?? '';
    final refresh = response.data?.refreshToken.trim() ?? '';
    return access.isNotEmpty && refresh.isNotEmpty;
  }

  //register
  Future<AuthResponse> register(RegisterData data) async {
    try {
      final response =
          await _apiClient.dio.post('/auth/register', data: data.toJson());

      final authResponse = AuthResponse.fromJson(_requireMap(response.data));

      // Note: Backend /auth/register does not return tokens
      // It only returns user data and requires email verification
      // So we just return the response without storing tokens
      
      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiError.fromJson(responseData);
        }
        throw ApiError(success: false, message: responseData.toString());
      }
      throw ApiError(
          success: false, message: 'Registration failed: ${e.message}');
    } catch (e) {
      throw ApiError(
          success: false, message: 'Registration failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> login(LoginData data) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: data.toJson(),
      );

      final authResponse = AuthResponse.fromJson(_requireMap(response.data));

      if (authResponse.success &&
          authResponse.data != null &&
          _hasValidTokens(authResponse)) {
        // Save access token to secure storage (expires in 15 minutes)
        await _apiClient.secureStorage.write(
          key: 'accessToken',
          value: authResponse.data!.accessToken,
        );
        await _apiClient.secureStorage
            .write(key: 'refreshToken', value: authResponse.data!.refreshToken);

        // Nạp token vào RAM ngay lập tức
        _apiClient.setToken(authResponse.data!.accessToken);
      } else if (authResponse.success) {
        throw ApiError(
            success: false,
            message: 'Phản hồi đăng nhập thiếu token xác thực.');
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiError.fromJson(responseData);
        }
        throw ApiError(success: false, message: responseData.toString());
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

  // --- Nằm trong authService.dart ---
  Future<bool> changePassword(ChangePasswordData data) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/change-password',
        data: data.toJson(),
      );

      // Nếu HTTP 200 OK và success = true
      final responseData = _requireMap(response.data);
      if (responseData['success'] == true) {
        return true;
      }

      // Nếu HTTP 200 OK nhưng success = false (dù C# đang trả 400, cứ rào trước cho chắc)
      throw ApiError(
        success: false,
        message: responseData['message']?.toString() ?? 'Đổi mật khẩu thất bại',
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;

        if (responseData is Map<String, dynamic>) {
          throw ApiError(
            success: false,
            message: responseData['message'] ?? 'Mật khẩu không chính xác!',
          );
        }
        // Nếu trả về text HTML (404 Not Found, 500 Server Error)
        else {
          throw ApiError(success: false, message: responseData.toString());
        }
      }

      // Nếu sập mạng, không có response
      throw ApiError(
        success: false,
        message: 'Lỗi kết nối: ${e.message}',
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

      final authResponse = AuthResponse.fromJson(_requireMap(response.data));

      if (authResponse.success &&
          authResponse.data != null &&
          _hasValidTokens(authResponse)) {
        await _apiClient.secureStorage.write(
          key: 'accessToken',
          value: authResponse.data!.accessToken,
        );
        await _apiClient.secureStorage.write(
          key: 'refreshToken',
          value: authResponse.data!.refreshToken,
        );

        // Nạp token vào RAM ngay lập tức
        _apiClient.setToken(authResponse.data!.accessToken);
      } else if (authResponse.success) {
        throw ApiError(
            success: false,
            message: 'Phản hồi Google login thiếu token xác thực.');
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiError.fromJson(responseData);
        }
        throw ApiError(success: false, message: responseData.toString());
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
      // 1. Lấy Refresh Token từ kho ra
      final refreshToken =
          await _apiClient.secureStorage.read(key: 'refreshToken');

      await _apiClient.dio.post(
        '/auth/logout',
        data: {
          'refreshToken': refreshToken ?? '',
        },
      );
    } catch (e) {
      // Có lỗi thì in ra để debug
      print('Logout error (Nhưng không sao, vẫn cho user out): $e');
    } finally {
      // 3. Xóa sạch mọi thứ ở Local
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
    if (token == null || token.trim().isEmpty) {
      return false;
    }

    try {
      if (!Jwt.isExpired(token)) {
        return true;
      }
    } catch (_) {
      // If token payload cannot be decoded, fallback to refresh token flow.
    }

    return await tryRefreshToken();
  }

  Future<bool> tryRefreshToken() async {
    final refreshToken =
        await _apiClient.secureStorage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return false;
    }

    try {
      final response = await _apiClient.dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'_retry': true}),
      );

      final responseData = response.data;
      if (responseData is! Map) {
        return false;
      }

      final envelope = responseData.cast<String, dynamic>();
      final payloadRaw = envelope['data'] ?? envelope['Data'];
      if (payloadRaw is! Map) {
        return false;
      }

      final payload = payloadRaw.cast<String, dynamic>();
      final newAccessToken =
          (payload['accessToken'] ?? payload['AccessToken'])?.toString();
      final newRefreshToken =
          (payload['refreshToken'] ?? payload['RefreshToken'])?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return false;
      }

      await _apiClient.secureStorage
          .write(key: 'accessToken', value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _apiClient.secureStorage
            .write(key: 'refreshToken', value: newRefreshToken);
      }

      // Nạp token mới vào RAM ngay lập tức
      _apiClient.setToken(newAccessToken);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _apiClient.secureStorage.read(key: 'accessToken');
  }

  // Bắn API xin link Forgot Password
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final responseData = _requireMap(response.data);
      if (responseData['success'] == true) {
        return true;
      }

      throw ApiError(
          success: false,
          message:
              responseData['message']?.toString() ?? 'Gửi yêu cầu thất bại');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiError.fromJson(responseData);
        } else {
          throw ApiError(success: false, message: responseData.toString());
        }
      }
      throw ApiError(success: false, message: 'Lỗi kết nối: ${e.message}');
    } catch (e) {
      throw ApiError(success: false, message: e.toString());
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });

      final responseData = _requireMap(response.data);
      if (responseData['success'] == true) {
        return true;
      }

      throw ApiError(
          success: false,
          message: responseData['message']?.toString() ??
              'Đặt lại mật khẩu thất bại');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiError.fromJson(responseData);
        } else {
          throw ApiError(success: false, message: responseData.toString());
        }
      }
      throw ApiError(success: false, message: 'Lỗi kết nối: ${e.message}');
    }
  }
}
