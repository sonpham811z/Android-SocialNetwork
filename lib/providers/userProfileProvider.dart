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

  /// Reset all cached state — call on logout / account switch.
  void clear() {
    _profile = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

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

  Future<bool> uploadProfilePicture(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uploadedUrl = await _service.uploadProfilePicture(filePath);
      if (_profile != null) {
        final map = _profile!.toJson();
        map['profilePictureUrl'] = uploadedUrl;
        _profile = User.fromJson(map);
      } else {
        _profile = await _service.getMyProfile();
      }

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

  Future<bool> uploadCoverPhoto(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uploadedUrl = await _service.uploadCoverPhoto(filePath);
      if (_profile != null) {
        final map = _profile!.toJson();
        map['coverPhotoUrl'] = uploadedUrl;
        _profile = User.fromJson(map);
      } else {
        _profile = await _service.getMyProfile();
      }

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

  Future<bool> deleteCoverPhoto() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _service.deleteCoverPhoto();
      if (ok && _profile != null) {
        final map = _profile!.toJson();
        map['coverPhotoUrl'] = null;
        _profile = User.fromJson(map);
      }

      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Xóa mềm tài khoản hiện tại.
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _service.deleteMyAccount();
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}