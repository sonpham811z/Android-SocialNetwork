import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chatModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../services/messageService.dart';
import '../../services/signalRService.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatarUrl;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageService = MessageService();
  final _signalR = SignalRService();

  String? _conversationId;
  String? _currentUserId;
  List<MessageModel> _messages = [];
  bool _isInitializing = true;
  bool _isSending = false;
  bool _hasMore = false;
  String? _nextCursor;
  bool _isLoadingMore = false;
  String? _error;
  bool _isNotFriend = false;

  StreamSubscription<MessageModel>? _messageSub;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _currentUserId = context.read<AuthProvider>().user?.id;
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    if (_conversationId != null) {
      _signalR.leaveConversation(_conversationId!);
    }
    super.dispose();
  }

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      // Get or create the conversation
      if (_conversationId == null) {
        final conv = await context
            .read<ConversationProvider>()
            .openConversation(widget.friendId);
        _conversationId = conv.id;
      }

      // Connect SignalR if not already connected, join conversation group
      await _signalR.connect();
      await _signalR.joinConversation(_conversationId!);

      // Load message history
      await _loadMessages();

      // Mark as read
      _signalR.markAsRead(_conversationId!);

      // Subscribe to real-time incoming messages
      _messageSub = _signalR.messageStream
          .where((msg) => msg.conversationId == _conversationId)
          .listen(_onIncomingMessage);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        final notFriend = msg.toLowerCase().contains('non-friend') ||
            msg.toLowerCase().contains('not a friend');
        setState(() {
          _isNotFriend = notFriend;
          _error = notFriend ? null : msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final result = await _messageService.getMessages(_conversationId!);
    if (mounted) {
      setState(() {
        _messages = result.messages; // newest-first from server
        _hasMore = result.hasMore;
        _nextCursor = result.nextCursor;
      });
    }
  }

  // ── Pagination — load older messages when scrolled to top ────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_conversationId == null || !_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _messageService.getMessages(
        _conversationId!,
        beforeMessageId: _nextCursor,
      );
      setState(() {
        _messages.addAll(result.messages); // append older messages at end of list
        _hasMore = result.hasMore;
        _nextCursor = result.nextCursor;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  // ── Incoming real-time message ────────────────────────────────────────────

  void _onIncomingMessage(MessageModel message) {
    if (!mounted) return;
    // De-duplicate by ID
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages.insert(0, message));
    _signalR.markAsRead(_conversationId!);
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _conversationId == null || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await _signalR.sendMessage(_conversationId!, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F0F10) : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (!_isNotFriend) _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? const Color(0xFF0F0F10) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final shadowColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final avatarBg = isDark ? AppTheme.slate800 : AppTheme.slate200;

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 1,
      shadowColor: shadowColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarBg,
            backgroundImage: widget.friendAvatarUrl != null
                ? NetworkImage(widget.friendAvatarUrl!)
                : null,
            child: widget.friendAvatarUrl == null
                ? Text(
                    widget.friendName.isNotEmpty
                        ? widget.friendName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.friendName,
              style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.call, color: AppTheme.violetPrimary),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.violetPrimary),
            onPressed: () {}),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.violetPrimary),
      );
    }

    if (_isNotFriend) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = Theme.of(context).colorScheme.onSurface;
      final avatarBg = isDark ? AppTheme.slate800 : AppTheme.slate200;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: avatarBg,
                backgroundImage: widget.friendAvatarUrl != null
                    ? NetworkImage(widget.friendAvatarUrl!)
                    : null,
                child: widget.friendAvatarUrl == null
                    ? Text(
                        widget.friendName.isNotEmpty
                            ? widget.friendName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.friendName,
                style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.slate800 : AppTheme.slate200).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: Colors.grey, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Chỉ có thể nhắn tin với bạn bè.',
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy kết bạn để bắt đầu trò chuyện.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitializing = true;
                  });
                  _init();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = Theme.of(context).colorScheme.onSurface;
      final avatarBg = isDark ? AppTheme.slate800 : AppTheme.slate200;

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: avatarBg,
              backgroundImage: widget.friendAvatarUrl != null
                  ? NetworkImage(widget.friendAvatarUrl!)
                  : null,
              child: widget.friendAvatarUrl == null
                  ? Text(
                      widget.friendName.isNotEmpty
                          ? widget.friendName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.friendName,
              style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Say hello!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Messages are newest-first — reverse so newest is at the bottom
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      reverse: true,
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.violetPrimary),
              ),
            ),
          );
        }
        return _buildBubble(_messages[index]);
      },
    );
  }

  Widget _buildBubble(MessageModel message) {
    final isMe = message.senderId == _currentUserId;
    final time = formatMessageTime(message.timestamp);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedBubbleBg = isDark
        ? AppTheme.slate800.withOpacity(0.6)
        : AppTheme.slate200;
    final receivedTextColor = isDark ? Colors.white : AppTheme.slate900;
    final timeColor = isDark ? Colors.grey : AppTheme.slate500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.violetPrimary
                    : receivedBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                    color: isMe ? Colors.white : receivedTextColor,
                    fontSize: 15),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(color: timeColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF0F0F10) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2A2A2D) : AppTheme.slate100;
    final inputTextColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : AppTheme.slate200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: AppTheme.violetPrimary),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: inputTextColor, fontSize: 16),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.violetPrimary,
              radius: 20,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
