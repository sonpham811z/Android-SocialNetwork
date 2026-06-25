import 'package:flutter/foundation.dart';
import '../services/authService.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  bool _isLoading = false;
  bool _shouldShowIntro = false;
  String? _error;
  UserData? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoading => _isLoading;
  bool get shouldShowIntro => _shouldShowIntro;
  String? get error => _error;
  UserData? get user => _user;

  UserData _mapUserData(Map<String, dynamic> userData) {
    return UserData(
      id: userData['sub']?.toString() ?? userData['id']?.toString() ?? '',
      email: userData['email'] ?? '',
      firstName: userData['firstName'] ?? '',
      lastName: userData['lastName'] ?? '',
      isEmailConfirmed: userData['isEmailConfirmed'] ?? false,
      // JWT không chứa firstLogin → mặc định false (sẽ lấy chính xác từ /auth/me).
      firstLogin: false,
      // JWT có claim "isAdmin" (chuỗi "true"/"false").
      isAdmin: userData['isAdmin'] == 'true' || userData['isAdmin'] == true,
    );
  }

  // Quyết định hiển thị giới thiệu dựa trên cờ firstLogin (lưu trên DB).
  void _loadIntroVisibilityForCurrentUser() {
    _shouldShowIntro = _user?.firstLogin ?? false;
  }

  Future<void> markIntroAsSeen() async {
    _shouldShowIntro = false;
    notifyListeners();

    // Cập nhật server (set FirstLogin = false) để không hiện lại ở thiết bị khác / cold boot.
    try {
      await _authService.completeIntro();
    } catch (_) {
      // Bỏ qua lỗi mạng — phiên hiện tại đã ẩn giới thiệu.
    }
  }

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isAuthenticated();

      if (_isAuthenticated) {
        // Ưu tiên lấy user tươi từ server (có cờ firstLogin chính xác).
        final me = await _authService.getMe();
        if (me != null) {
          _user = me;
          _loadIntroVisibilityForCurrentUser();
        } else {
          // Offline / lỗi mạng → fallback decode JWT, không hiện giới thiệu.
          final userData = await _authService.getCurrentUser();
          if (userData != null) {
            _user = _mapUserData(userData);
          }
          _shouldShowIntro = false;
        }
      } else {
        _user = null;
        _shouldShowIntro = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _shouldShowIntro = false;
    } finally {
      // BẮT BUỘC PHẢI CÓ: Chạy xong thì tắt cờ loading và báo UI cập nhật
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  void cleanError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final registerData = RegisterData(email: email, password: password, firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth, gender: gender);

      final response = await _authService.register(registerData);

      if(response.success && response.data!= null) 
      {
        _user = response.data!.user;
        _isAuthenticated = true;
        _loadIntroVisibilityForCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      } 
    } on ApiError catch (e)
    {
      _error = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        _error = e.errors!.join(', ');
      }

      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final changePasswordData = ChangePasswordData(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final response = await _authService.changePassword(changePasswordData);
      
      if(response) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Đổi mật khẩu thất bại, vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiError catch (e) {
      _error = (e.errors != null && e.errors!.isNotEmpty) 
          ? e.errors!.join('\n') 
          : e.message;
          
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      // Bắt các lỗi vặt khác (mất mạng, sập app...)
      _error = 'Đã xảy ra lỗi hệ thống: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
  }
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loginData = LoginData(
        email: email,
        password: password,
      );

      final response = await _authService.login(loginData);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _loadIntroVisibilityForCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiError catch (e) {
      _error = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        _error = e.errors!.join(', ');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gọi qua AuthService
      final success = await _authService.forgotPassword(email);
      
      _isLoading = false;
      notifyListeners();
      return success;
      
    } on ApiError catch (e) {
      _error = (e.errors != null && e.errors!.isNotEmpty) 
          ? e.errors!.join('\n') 
          : e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi hệ thống: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.googleLogin(idToken);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _loadIntroVisibilityForCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiError catch (e) {
      _error = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        _error = e.errors!.join(', ');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isAuthenticated = false;
      _user = null;
      _shouldShowIntro = false;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  
   Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(token, newPassword);

      _isLoading = false;
      notifyListeners();
      return success;
    } on ApiError catch (e) {
      _error = (e.errors != null && e.errors!.isNotEmpty)
        ? e.errors!.join('\n')
        : e.message;
        _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi hệ thống: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    }

  // Refresh user data from token
  Future<void> refreshUserData() async {
    final userData = await _authService.getCurrentUser();
    if (userData != null) {
      _user = _mapUserData(userData);
      _loadIntroVisibilityForCurrentUser();
      notifyListeners();
    }
  }
}  

