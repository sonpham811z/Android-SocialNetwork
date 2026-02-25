import 'package:flutter/foundation.dart';
import '../services/authService.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  UserData? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserData? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = await _authService.isAuthenticated();

    if (_isAuthenticated) {
      final userData = await _authService.getCurrentUser();
      if(userData != null)
      {
        _user = UserData(
          id: userData['sub']?.toString() ?? userData['id']?.toString() ?? '',
          email: userData['email'] ?? '',
          firstName: userData['firstName'] ?? '',
          lastName: userData['lastName'] ?? '',
          isEmailConfirmed: userData['isEmailConfirmed'] ?? false,
        );
      }

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

  Future<bool> googleLogin(String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.googleLogin(idToken);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
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
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh user data from token
  Future<void> refreshUserData() async {
    final userData = await _authService.getCurrentUser();
    if (userData != null) {
      _user = UserData(
        id: userData['sub']?.toString() ?? userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        firstName: userData['firstName'] ?? '',
        lastName: userData['lastName'] ?? '',
        isEmailConfirmed: userData['isEmailConfirmed'] ?? false,
      );
      notifyListeners();
    }
  }
}  

