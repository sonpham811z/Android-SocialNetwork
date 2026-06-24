import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chatModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../services/messageService.dart';
import '../../services/signalRService.dart';
import 'callScreen.dart';

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
  final _imagePicker = ImagePicker();

  String? _conversationId;
  String? _currentUserId;
  List<MessageModel> _messages = [];
  // Ảnh đang được upload/gửi — hiển thị ngay (optimistic) kèm vòng tròn loading,
  // bị gỡ khi tin nhắn ảnh thật được server broadcast trở lại (khớp theo URL).
  final List<_PendingImage> _pendingImages = [];
  bool _isInitializing = true;
  bool _isSending = false;
  bool _hasMore = false;
  String? _nextCursor;
  bool _isLoadingMore = false;
  String? _error;
  bool _isNotFriend = false;

  StreamSubscription<MessageModel>? _messageSub;
  ConversationProvider? _convProvider;

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
      _convProvider?.leaveConversation(_conversationId!);
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

      // Mark as read (server + xoá badge unread ở dock)
      _signalR.markAsRead(_conversationId!);
      if (mounted) {
        _convProvider = context.read<ConversationProvider>();
        _convProvider!.enterConversation(_conversationId!);
      }

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
    setState(() {
      _messages.insert(0, message);
      // Ảnh thật đã về → gỡ placeholder loading tương ứng (khớp theo URL đã upload).
      if (message.type == 1) {
        _pendingImages.removeWhere((p) => p.url != null && p.url == message.content);
      }
    });
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
        // Khôi phục nội dung để người dùng không mất tin đã gõ
        _textController.text = content;
        _showError(_friendlyChatError(e));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Chuyển lỗi kỹ thuật của server thành thông báo dễ hiểu cho người dùng.
  String _friendlyChatError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('non-friend') ||
        raw.contains('not a friend') ||
        raw.contains('friend')) {
      return 'Bạn chỉ có thể nhắn tin với bạn bè.';
    }
    if (raw.contains('not connected') || raw.contains('connection')) {
      return 'Mất kết nối tới máy chủ. Vui lòng thử lại.';
    }
    if (raw.contains('not a member') || raw.contains('access denied')) {
      return 'Bạn không có quyền nhắn trong cuộc trò chuyện này.';
    }
    return 'Không gửi được tin nhắn. Vui lòng thử lại.';
  }

  // ── Send image ──────────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage() async {
    if (_conversationId == null) return;

    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } catch (e) {
      if (mounted) _showError('Không mở được thư viện ảnh: $e');
      return;
    }
    if (picked == null) return;

    // Hiển thị ngay ảnh tạm với vòng tròn loading (optimistic, kiểu Messenger).
    final pending = _PendingImage(path: picked.path);
    setState(() => _pendingImages.insert(0, pending));
    await _uploadAndSendPending(pending);
  }

  /// Upload ảnh rồi gửi. Placeholder sẽ tự bị gỡ khi tin ảnh thật broadcast về
  /// (xem [_onIncomingMessage]). Có thể gọi lại để thử lại khi thất bại.
  Future<void> _uploadAndSendPending(_PendingImage pending) async {
    if (mounted) setState(() => pending.failed = false);
    try {
      // Đã upload thành công ở lần trước thì không upload lại (chỉ gửi lại).
      pending.url ??= await _messageService.uploadImage(pending.path);
      await _signalR.sendMessage(_conversationId!, pending.url!, type: 1); // 1 = Image
    } catch (e) {
      if (mounted) {
        setState(() => pending.failed = true);
        _showError(_friendlyChatError(e));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  /// Opens an image attachment full-screen with pinch-to-zoom.
  void _openImageViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // ── Call ──────────────────────────────────────────────────────────────────

  void _startCall({required bool isVideo}) {
    if (_conversationId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          conversationId:   _conversationId!,
          calleeName:       widget.friendName,
          calleeAvatarUrl:  widget.friendAvatarUrl,
          isVideo:          isVideo,
        ),
      ),
    );
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
          onPressed: _conversationId == null ? null : () => _startCall(isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: AppTheme.violetPrimary),
          onPressed: _conversationId == null ? null : () => _startCall(isVideo: true),
        ),
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

    // Messages are newest-first — reverse so newest is at the bottom.
    // Pending image uploads sit at the very bottom (indices before the real messages).
    final pendingCount = _pendingImages.length;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      reverse: true,
      itemCount: pendingCount + _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 1) Pending (optimistic) image placeholders — newest at the bottom
        if (index < pendingCount) {
          return _buildPendingBubble(_pendingImages[index]);
        }
        final mIndex = index - pendingCount;

        // 2) "Load older" spinner at the very top
        if (mIndex == _messages.length) {
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

        // 3) Real messages
        return _buildBubble(_messages[mIndex]);
      },
    );
  }

  /// Optimistic placeholder for an image that is still uploading/sending.
  /// Shows the locally-picked file with a spinner overlay (Messenger style);
  /// on failure, tapping retries the upload+send.
  Widget _buildPendingBubble(_PendingImage pending) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(4),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: pending.failed ? () => _uploadAndSendPending(pending) : null,
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.62,
                        maxHeight: 280,
                      ),
                      child: Image.file(File(pending.path), fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: pending.failed
                            ? const Icon(Icons.refresh,
                                color: Colors.white, size: 34)
                            : const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              pending.failed ? 'Gửi thất bại — chạm để thử lại' : 'Đang gửi…',
              style: TextStyle(
                color: pending.failed ? Colors.redAccent : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubble(String url, BorderRadius radius) {
    return GestureDetector(
      onTap: () => _openImageViewer(url),
      child: ClipRRect(
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.62,
            maxHeight: 280,
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 180,
                height: 180,
                color: AppTheme.slate800.withValues(alpha: 0.3),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.violetPrimary),
              );
            },
            errorBuilder: (context, error, stack) => Container(
              width: 180,
              height: 120,
              color: AppTheme.slate800.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 36),
            ),
          ),
        ),
      ),
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

    final isImage = message.type == 1;
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 20),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isImage)
              _buildImageBubble(message.content, bubbleRadius)
            else
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.violetPrimary : receivedBubbleBg,
                  borderRadius: bubbleRadius,
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
              icon: const Icon(Icons.add_photo_alternate,
                  color: AppTheme.violetPrimary),
              tooltip: 'Gửi ảnh',
              onPressed: _pickAndSendImage,
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

/// Local-only state for an image being uploaded/sent (optimistic UI).
/// [url] is filled once the upload succeeds; [failed] flags an upload/send error.
class _PendingImage {
  final String path;
  String? url;
  bool failed = false;

  _PendingImage({required this.path});
}
