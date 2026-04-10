import 'package:flutter/foundation.dart';

import '../models/profileMockData.dart';
import '../models/userModel.dart';
import '../services/userProfileService.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _service = UserProfileService();

  User? _profile;
  bool _isLoading = false;
  String? _error;
  bool _useMockData = false;

  User? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useMockData => _useMockData;

  Future<void> setUseMockData(bool value, {bool reload = true}) async {
    if (_useMockData == value) {
      return;
    }

    _useMockData = value;
    notifyListeners();

    if (reload) {
      await loadMyProfile();
    }
  }

  Future<void> loadMyProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_useMockData) {
        _profile = ProfileMockData.myProfile;
        _isLoading = false;
        notifyListeners();
        return;
      }

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
      if (_useMockData) {
        final currentMap = (_profile ?? ProfileMockData.myProfile).toJson();
        currentMap.addAll(updateData);
        _profile = User.fromJson(currentMap);
        _isLoading = false;
        notifyListeners();
        return true;
      }

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
      if (_useMockData) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

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
      if (_useMockData) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

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
}