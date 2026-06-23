import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chatModel.dart';
import '../../models/friendModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../services/FriendService.dart';
import '../../services/messageService.dart';
import '../../services/signalRService.dart';

class GroupChatScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final List<String> memberIds;

  const GroupChatScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
    required this.memberIds,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageService = MessageService();
  final _friendService = FriendService();
  final _signalR = SignalRService();

  String? _currentUserId;
  List<MessageModel> _messages = [];
  // userId -> UserLite for showing sender name/avatar
  Map<String, UserLite> _memberMap = {};
  bool _isInitializing = true;
  bool _isSending = false;
  bool _hasMore = false;
  String? _nextCursor;
  bool _isLoadingMore = false;
  String? _error;

  StreamSubscription<MessageModel>? _messageSub;
  ConversationProvider? _convProvider;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().user?.id.toLowerCase();
    _convProvider = context.read<ConversationProvider>();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _signalR.leaveConversation(widget.conversationId);
    _convProvider?.leaveConversation(widget.conversationId);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Load friend list to build memberMap (name/avatar lookup)
      final friendsResult = await _friendService.getMyFriends(pageSize: 100);
      final friends = friendsResult.data?.items ?? [];
      final map = <String, UserLite>{};
      for (final f in friends) {
        map[f.friend.id.toLowerCase()] = f.friend;
      }
      if (mounted) setState(() => _memberMap = map);

      // Connect SignalR and join group
      await _signalR.connect();
      await _signalR.joinConversation(widget.conversationId);

      // Load message history
      await _loadMessages();

      _signalR.markAsRead(widget.conversationId);
      _convProvider?.enterConversation(widget.conversationId);

      _messageSub = _signalR.messageStream
          .where((msg) => msg.conversationId == widget.conversationId)
          .listen(_onIncomingMessage);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadMessages() async {
    final result =
        await _messageService.getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messages = result.messages;
        _hasMore = result.hasMore;
        _nextCursor = result.nextCursor;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _messageService.getMessages(
        widget.conversationId,
        beforeMessageId: _nextCursor,
      );
      setState(() {
        _messages.addAll(result.messages);
        _hasMore = result.hasMore;
        _nextCursor = result.nextCursor;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onIncomingMessage(MessageModel message) {
    if (!mounted) return;
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages.insert(0, message));
    _signalR.markAsRead(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSending) return;
    _textController.clear();
    setState(() => _isSending = true);
    try {
      await _signalR.sendMessage(widget.conversationId, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi thất bại: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF0F0F10)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(isDark)),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final memberCount = widget.memberIds.length;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
      elevation: 1,
      shadowColor: isDark ? Colors.white10 : Colors.black12,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Group avatar icon
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.violetPrimary.withValues(alpha: 0.15),
            child: const Icon(Icons.group,
                color: AppTheme.violetPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$memberCount thành viên',
                  style: TextStyle(
                    color: isDark ? Colors.grey : AppTheme.slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    if (_isInitializing) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.violetPrimary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitializing = true;
                  });
                  _init();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.violetPrimary.withValues(alpha: 0.12),
              child: const Icon(Icons.group,
                  color: AppTheme.violetPrimary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              widget.groupName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Bắt đầu cuộc trò chuyện nhóm!',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

        final msg = _messages[index];
        final prevMsg = index < _messages.length - 1 ? _messages[index + 1] : null;
        final showSenderInfo = !isMe(msg) &&
            (prevMsg == null || prevMsg.senderId != msg.senderId);

        return _buildBubble(msg, showSenderInfo, isDark);
      },
    );
  }

  bool isMe(MessageModel msg) => msg.senderId.toLowerCase() == _currentUserId;

  Widget _buildBubble(
      MessageModel message, bool showSenderInfo, bool isDark) {
    final me = isMe(message);
    final time = formatMessageTime(message.timestamp);
    final receivedBubbleBg =
        isDark ? AppTheme.slate800.withValues(alpha: 0.7) : AppTheme.slate200;
    final receivedTextColor = isDark ? Colors.white : AppTheme.slate900;
    final timeColor = isDark ? Colors.grey : AppTheme.slate500;
    final sender = _memberMap[message.senderId.toLowerCase()];
    final senderName = sender?.name ?? 'Unknown';
    final senderAvatar = sender?.avatarUrl;
    final avatarBg = isDark ? AppTheme.slate700 : AppTheme.slate300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Sender avatar (received only)
          if (!me)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: showSenderInfo
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarBg,
                      backgroundImage: senderAvatar != null
                          ? NetworkImage(senderAvatar)
                          : null,
                      child: senderAvatar == null
                          ? Text(
                              senderName.isNotEmpty
                                  ? senderName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    )
                  : const SizedBox(width: 32),
            ),

          // Bubble
          Column(
            crossAxisAlignment:
                me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name above bubble (received, first of sequence)
              if (!me && showSenderInfo)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    senderName,
                    style: TextStyle(
                      color: AppTheme.violetPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: me ? AppTheme.violetPrimary : receivedBubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(me ? 18 : 4),
                    bottomRight: Radius.circular(me ? 4 : 18),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: me ? Colors.white : receivedTextColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(time,
                  style: TextStyle(color: timeColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    final barBg = isDark ? const Color(0xFF0F0F10) : Colors.white;
    final inputBg =
        isDark ? const Color(0xFF2A2A2D) : AppTheme.slate100;
    final inputTextColor = Theme.of(context).colorScheme.onSurface;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.slate200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
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
                  decoration: const InputDecoration(
                    hintText: 'Nhắn tin nhóm...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
