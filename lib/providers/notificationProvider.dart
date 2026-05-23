import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notificationModel.dart';
import '../services/notificationService.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _page = 1;
  StreamSubscription<NotificationModel>? _sub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await _service.connect();
    _sub = _service.stream.listen(_onRealTime);
    await Future.wait([
      loadNotifications(refresh: true),
      _refreshCount(),
    ]);
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getNotifications(page: _page, pageSize: 20);
      if (data != null && data['success'] == true) {
        final raw = (data['data']?['items'] as List?) ?? [];
        final items = raw
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (refresh) {
          _notifications = items;
        } else {
          _notifications = [..._notifications, ...items];
        }
        final total = (data['data']?['totalCount'] as int?) ?? 0;
        _hasMore = _notifications.length < total;
        _page++;
      } else {
        _error = 'Không tải được thông báo';
      }
    } catch (e) {
      _error = 'Lỗi kết nối';
      debugPrint('[NotificationProvider] loadNotifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;
    await _service.markAsRead(id);
    _unreadCount = (_unreadCount - 1).clamp(0, 99999);
    notifyListeners();
    // Reload to get server-side updated status
    await loadNotifications(refresh: true);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _unreadCount = 0;
    notifyListeners();
    await loadNotifications(refresh: true);
  }

  Future<bool> registerDeviceToken(String fcmToken, String platform) {
    return _service.registerDeviceToken(fcmToken, platform);
  }

  Future<void> _refreshCount() async {
    _unreadCount = await _service.getUnreadCount();
    notifyListeners();
  }

  void _onRealTime(NotificationModel notification) {
    _notifications = [notification, ..._notifications];
    _unreadCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.disconnect();
    super.dispose();
  }
}
