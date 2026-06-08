import 'package:flutter/foundation.dart';

import '../models/userSettingsModel.dart';
import '../services/userProfileService.dart';

class UserSettingsProvider with ChangeNotifier {
  final UserProfileService _service = UserProfileService();

  UserSettings _settings = const UserSettings();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void clear() {
    _settings = const UserSettings();
    _isLoading = false;
    _isSaving = false;
    _error = null;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getMySettings();
      if (result != null) _settings = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotificationSettings(NotificationSettings notif) async {
    return _update({'notificationSettings': notif.toJson()}, (s) => s.copyWith(notificationSettings: notif));
  }

  Future<bool> updateTheme(String theme) async {
    return _update({'theme': theme}, (s) => s.copyWith(theme: theme));
  }

  Future<bool> updateLanguage(String language) async {
    return _update({'language': language}, (s) => s.copyWith(language: language));
  }

  Future<bool> updatePrivacySettings(PrivacySettings privacy) async {
    return _update({'privacySettings': privacy.toJson()}, (s) => s.copyWith(privacySettings: privacy));
  }

  Future<bool> _update(
    Map<String, dynamic> data,
    UserSettings Function(UserSettings) optimisticUpdate,
  ) async {
    final previous = _settings;
    _settings = optimisticUpdate(_settings);
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.updateSettings(data);
      if (result != null) _settings = result;
      return true;
    } catch (e) {
      _settings = previous;
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
