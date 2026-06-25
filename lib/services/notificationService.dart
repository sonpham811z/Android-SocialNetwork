import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';
import '../config/environment.dart';
import '../models/notificationModel.dart';
import '../utils/json_helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _storage = FlutterSecureStorage();
  HubConnection? _connection;

  final _controller = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get stream => _controller.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Future<String?> _token() => _storage.read(key: 'accessToken');

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── REST API ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await _token();
    if (token == null) return null;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification'
        '?page=$page&pageSize=$pageSize',
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[NotificationService] getNotifications error: $e');
    }
    return null;
  }

  Future<int> getUnreadCount() async {
    final token = await _token();
    if (token == null) return 0;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/unread-count',
      );
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (body['data'] as int?) ?? 0;
      }
    } catch (e) {
      debugPrint('[NotificationService] getUnreadCount error: $e');
    }
    return 0;
  }

  Future<void> markAsRead(String id) async {
    final token = await _token();
    if (token == null) return;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/$id/read',
      );
      await http.patch(uri, headers: _headers(token));
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _token();
    if (token == null) return;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/read-all',
      );
      await http.patch(uri, headers: _headers(token));
    } catch (e) {
      debugPrint('[NotificationService] markAllAsRead error: $e');
    }
  }

  Future<bool> registerDeviceToken(String fcmToken, String platform) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/device-token',
      );
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'token': fcmToken, 'platform': platform}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] registerDeviceToken error: $e');
      return false;
    }
  }

  Future<void> removeDeviceToken(String fcmToken) async {
    final token = await _token();
    if (token == null) return;
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/device-token',
      );
      final req = http.Request('DELETE', uri);
      req.headers.addAll(_headers(token));
      req.body = jsonEncode({'token': fcmToken, 'platform': 'android'});
      await req.send();
    } catch (e) {
      debugPrint('[NotificationService] removeDeviceToken error: $e');
    }
  }

  /// Trả về tập userId đang online trong số [userIds] truyền vào.
  Future<Set<String>> getPresence(List<String> userIds) async {
    if (userIds.isEmpty) return <String>{};
    final token = await _token();
    if (token == null) return <String>{};
    try {
      final uri = Uri.parse(
        '${Environment.notificationServiceBaseUrl}/notification/presence',
      );
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'userIds': userIds}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] ?? body['Data'];
        if (data is List) {
          return data.map((e) => e.toString()).toSet();
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] getPresence error: $e');
    }
    return <String>{};
  }

  // ── SignalR Hub ───────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (isConnected) return;
    final token = await _token();
    if (token == null) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          Environment.notificationHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveNotification', _onReceive);

    _connection!.onclose(({Exception? error}) {
      debugPrint('[NotificationHub] closed: $error');
    });

    try {
      await _connection!.start();
      debugPrint('[NotificationHub] connected');
    } catch (e) {
      debugPrint('[NotificationHub] connect error: $e');
      _connection = null;
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  void _onReceive(List<Object?>? args) {
    if (args == null || args.isEmpty || args[0] == null) return;
    try {
      final data = asJsonMap(args[0]) ?? {};
      _controller.add(NotificationModel.fromJson(data));
    } catch (e) {
      debugPrint('[NotificationHub] parse error: $e');
    }
  }

  void dispose() {
    _controller.close();
    _connection?.stop();
  }
}
