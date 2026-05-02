import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/environment.dart';
import '../models/chatModel.dart';
import '../utils/json_helpers.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _connection;
  static const _storage = FlutterSecureStorage();

  final _messageController = StreamController<MessageModel>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream =>
      _readReceiptController.stream;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (isConnected) return;

    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          Environment.messageHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveMessage', _onReceiveMessage);
    _connection!.on('ReadReceipt', _onReadReceipt);

    _connection!.onclose(({Exception? error}) {
      debugPrint('[SignalR] Connection closed: $error');
    });

    _connection!.onreconnecting(({Exception? error}) {
      debugPrint('[SignalR] Reconnecting: $error');
    });

    _connection!.onreconnected(({String? connectionId}) {
      debugPrint('[SignalR] Reconnected: $connectionId');
    });

    try {
      await _connection!.start();
      debugPrint('[SignalR] Connected');
    } catch (e) {
      debugPrint('[SignalR] Connection error: $e');
      _connection = null;
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    debugPrint('[SignalR] Disconnected');
  }

  Future<void> joinConversation(String conversationId) async {
    if (!isConnected) return;
    try {
      await _connection!.invoke('JoinConversation', args: [conversationId]);
      debugPrint('[SignalR] Joined conversation: $conversationId');
    } catch (e) {
      debugPrint('[SignalR] JoinConversation error: $e');
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    if (!isConnected) return;
    try {
      await _connection!.invoke('LeaveConversation', args: [conversationId]);
    } catch (e) {
      debugPrint('[SignalR] LeaveConversation error: $e');
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (!isConnected) {
      throw Exception('Not connected to messaging server.');
    }
    await _connection!.invoke('SendMessage', args: [
      {'conversationId': conversationId, 'content': content, 'type': 0},
    ]);
  }

  Future<void> markAsRead(String conversationId) async {
    if (!isConnected) return;
    try {
      await _connection!.invoke('MarkAsRead', args: [conversationId]);
    } catch (_) {}
  }

  // ── Internal event handlers ───────────────────────────────────────────────

  void _onReceiveMessage(List<Object?>? args) {
    if (args == null || args.isEmpty || args[0] == null) return;
    try {
      final data = asJsonMap(args[0]) ?? {};
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    } catch (e) {
      debugPrint('[SignalR] Failed to parse ReceiveMessage: $e');
    }
  }

  void _onReadReceipt(List<Object?>? args) {
    if (args == null || args.isEmpty || args[0] == null) return;
    try {
      final data = asJsonMap(args[0]) ?? {};
      _readReceiptController.add(data);
    } catch (e) {
      debugPrint('[SignalR] Failed to parse ReadReceipt: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _readReceiptController.close();
    _connection?.stop();
  }
}
