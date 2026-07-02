import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notificationService.dart';

/// Theo dõi trạng thái online của một tập user (vd: đối tác hội thoại).
/// Dùng polling định kỳ qua endpoint /notification/presence (dựa trên SignalR
/// connection tracker ở server).
class PresenceProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();

  Set<String> _online = <String>{};
  List<String> _watched = <String>[];
  Timer? _timer;

  bool isOnline(String userId) => _online.contains(userId);
  int get onlineCount => _online.length;
  Set<String> get online => _online;

  /// Đặt danh sách userId cần theo dõi, tải trạng thái ngay và bật polling.
  Future<void> watch(List<String> userIds) async {
    final next = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    _watched = next;
    await refresh();
    _startTimer();
  }

  Future<void> refresh() async {
    if (_watched.isEmpty) {
      if (_online.isNotEmpty) {
        _online = <String>{};
        notifyListeners();
      }
      return;
    }
    final result = await _service.getPresence(_watched);
    if (!setEquals(result, _online)) {
      _online = result;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reset — gọi khi logout.
  void clear() {
    _timer?.cancel();
    _timer = null;
    _online = <String>{};
    _watched = <String>[];
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
