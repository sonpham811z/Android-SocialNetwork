import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chatModel.dart';
import '../models/friendModel.dart';
import '../services/FriendService.dart';
import '../services/messageService.dart';
import '../services/signalRService.dart';

class ConversationProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  final FriendService _friendService = FriendService();
  final SignalRService _signalR = SignalRService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> _conversations = [];
  List<FriendshipModel> _friends = [];
  String? _currentUserId;

  StreamSubscription<MessageModel>? _messageSubscription;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize(String currentUserId) async {
    if (_isInitialized) return;
    _currentUserId = currentUserId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load friends and conversations in parallel
      final results = await Future.wait([
        _friendService.getMyFriends(pageSize: 100),
        _messageService.getConversations(),
      ]);

      final friendsResult = results[0] as FriendApiResponse<PaginatedResponse<FriendshipModel>>;
      _friends = friendsResult.data?.items ?? [];
      _conversations = results[1] as List<ConversationModel>;

      // Connect to SignalR hub
      await _signalR.connect();

      // Join all existing conversation groups for real-time updates
      for (final conv in _conversations) {
        await _signalR.joinConversation(conv.id);
      }

      // Subscribe to incoming messages to keep conversation list live
      _messageSubscription = _signalR.messageStream.listen(_onNewMessage);

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Returns the existing or newly created conversation for a friend
  Future<ConversationModel> openConversation(String friendId) async {
    // Check if we already have it locally
    final existing = _conversations.where((c) {
      return c.isOneToOne && c.members.contains(friendId);
    }).firstOrNull;
    if (existing != null) return existing;

    // Create via API
    final conv = await _messageService.createOrGetOneToOne(friendId);

    // Add to local list and join the SignalR group
    if (!_conversations.any((c) => c.id == conv.id)) {
      _conversations.insert(0, conv);
      await _signalR.joinConversation(conv.id);
    }

    notifyListeners();
    return conv;
  }

  // Builds the sorted combined list: conversations first (by time), then friends without
  List<ConversationListItem> buildList() {
    final uid = _currentUserId ?? '';
    final items = <ConversationListItem>[];
    final friendsWithConvs = <String>{};

    // Map friendId → FriendshipModel for quick lookup
    final friendMap = {for (final f in _friends) f.friend.id: f};

    // Sort conversations newest-first
    final sorted = List.of(_conversations)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final conv in sorted) {
      final otherId = conv.members.firstWhere(
        (m) => m != uid,
        orElse: () => '',
      );
      final friend = friendMap[otherId];
      friendsWithConvs.add(otherId);

      items.add(ConversationListItem(
        conversationId: conv.id,
        userId: otherId,
        name: friend?.friend.name ?? 'Unknown',
        avatarUrl: friend?.friend.avatarUrl,
        lastMessagePreview: conv.lastMessage?.content,
        lastMessageTime: conv.lastMessage?.timestamp ?? conv.updatedAt,
        isLastMessageByMe: conv.lastMessage?.senderId == uid,
      ));
    }

    // Friends without any conversation — sorted by name
    final noConv = _friends
        .where((f) => !friendsWithConvs.contains(f.friend.id))
        .toList()
      ..sort((a, b) => a.friend.name.compareTo(b.friend.name));

    for (final f in noConv) {
      items.add(ConversationListItem(
        userId: f.friend.id,
        name: f.friend.name,
        avatarUrl: f.friend.avatarUrl,
      ));
    }

    return items;
  }

  // ── Incoming message handler ──────────────────────────────────────────────

  void _onNewMessage(MessageModel message) {
    final idx = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx == -1) return;

    final conv = _conversations[idx];

    // Rebuild conversation with updated LastMessage and UpdatedAt
    final updated = ConversationModel(
      id: conv.id,
      type: conv.type,
      members: conv.members,
      groupName: conv.groupName,
      lastMessage: LastMessageModel(
        messageId: message.id,
        senderId: message.senderId,
        content: message.content,
        timestamp: message.timestamp,
      ),
      updatedAt: message.timestamp,
    );

    _conversations.removeAt(idx);
    _conversations.insert(0, updated); // Move to top
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
