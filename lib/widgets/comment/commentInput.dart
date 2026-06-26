import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/friendModel.dart';
import '../../providers/friendProvider.dart';
import '../../utils/mention_utils.dart';
import '../common/mentionSuggestionList.dart';

class CommentInput extends StatefulWidget {
  final String? avatarUrl;
  final String? replyingToUser;
  final VoidCallback? onCancelReply;
  final Future<bool> Function(String content) onSubmit;
  final FocusNode? focusNode;

  const CommentInput({
    super.key,
    this.avatarUrl,
    this.replyingToUser,
    this.onCancelReply,
    required this.onSubmit,
    this.focusNode,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late TextEditingController _controller;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    // Nạp danh sách bạn bè để gợi ý @mention (nếu chưa có).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fp = context.read<FriendProvider>();
      if (fp.friends.isEmpty) fp.loadMyFriends();
    });
  }

  void _onMentionSelected(UserLite user) {
    final mention = activeMentionQuery(_controller.value);
    if (mention == null) return;
    _controller.value = applyMention(_controller.value, mention, user.userName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final success = await widget.onSubmit(text);
      if (success && mounted) {
        _controller.clear();
        widget.onCancelReply?.call();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _controller.text.trim().isNotEmpty;

    // Gợi ý @mention theo bạn bè
    final mention = activeMentionQuery(_controller.value);
    final friends = context
        .watch<FriendProvider>()
        .friends
        .map((f) => f.friend)
        .toList();
    final mentionSuggestions = mention == null
        ? const <UserLite>[]
        : filterMentionCandidates(friends, mention.query);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.slate200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gợi ý @mention
            if (mentionSuggestions.isNotEmpty)
              MentionSuggestionList(
                suggestions: mentionSuggestions,
                onSelected: _onMentionSelected,
              ),

            // Reply indicator
            if (widget.replyingToUser != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark
                    ? AppTheme.violetPrimary.withOpacity(0.1)
                    : AppTheme.violetPrimary.withOpacity(0.06),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: AppTheme.violetPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang trả lời ${widget.replyingToUser}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.violetPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2E) : AppTheme.slate200,
                      backgroundImage:
                          (widget.avatarUrl ?? '').trim().isNotEmpty
                              ? NetworkImage(widget.avatarUrl!.trim())
                              : null,
                      child: (widget.avatarUrl ?? '').trim().isEmpty
                          ? Icon(
                              Icons.person,
                              size: 16,
                              color: isDark ? Colors.white54 : AppTheme.slate500,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2E)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: widget.focusNode,
                              maxLines: 5,
                              minLines: 1,
                              textInputAction: TextInputAction.newline,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppTheme.slate900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Viết bình luận...',
                                hintStyle: TextStyle(
                                  color: AppTheme.slate400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          // Send button
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 4,
                              bottom: 4,
                            ),
                            child: GestureDetector(
                              onTap: hasText && !_isSending
                                  ? _handleSubmit
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: hasText && !_isSending
                                      ? AppTheme.violetPrimary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: _isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                          color: hasText
                                              ? Colors.white
                                              : AppTheme.slate400,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
