import 'package:flutter/foundation.dart';

import '../models/userModel.dart';
import '../services/userProfileService.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _service = UserProfileService();

  User? _profile;
  bool _isLoading = false;
  String? _error;

  User? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getMyProfile();
      _profile = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMyProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.updateMyProfile(updateData);
      _profile = result;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

