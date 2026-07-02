import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/friendModel.dart';

/// TextEditingController tô sáng `@username` ngay trong ô nhập bình luận.
/// Ký tự username khớp regex backend `@([A-Za-z0-9_.]+)`.
class MentionHighlightController extends TextEditingController {
  MentionHighlightController({super.text});

  static final RegExp _mentionRegex = RegExp(r'@([A-Za-z0-9_.]+)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final mentionStyle = base.copyWith(
      color: AppTheme.violetPrimary,
      fontWeight: FontWeight.w700,
    );

    final txt = text;
    final children = <InlineSpan>[];
    int last = 0;

    for (final m in _mentionRegex.allMatches(txt)) {
      if (m.start > last) {
        children.add(TextSpan(text: txt.substring(last, m.start), style: base));
      }
      children.add(TextSpan(text: m.group(0), style: mentionStyle));
      last = m.end;
    }
    if (last < txt.length) {
      children.add(TextSpan(text: txt.substring(last), style: base));
    }

    return TextSpan(style: base, children: children);
  }
}

class CommentInput extends StatefulWidget {
  final String? avatarUrl;
  final String? replyingToUser;
  final VoidCallback? onCancelReply;
  final Future<bool> Function(String content) onSubmit;
  final FocusNode? focusNode;

  /// Danh sách bạn bè dùng để gợi ý khi người dùng gõ `@` trong bình luận.
  final List<UserLite> mentionSuggestions;

  const CommentInput({
    super.key,
    this.avatarUrl,
    this.replyingToUser,
    this.onCancelReply,
    required this.onSubmit,
    this.focusNode,
    this.mentionSuggestions = const <UserLite>[],
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late TextEditingController _controller;
  bool _isSending = false;

  // ── @mention autocomplete state ──
  // Ký tự hợp lệ cho username (khớp regex backend @([A-Za-z0-9_.]+)).
  static final RegExp _usernameChar = RegExp(r'[A-Za-z0-9_.]');
  int? _mentionStart; // vị trí ký tự '@' đang gõ dở
  List<UserLite> _mentionMatches = <UserLite>[];

  @override
  void initState() {
    super.initState();
    _controller = MentionHighlightController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    _updateMentionMatches();
    setState(() {});
  }

  /// Tìm token `@...` mà con trỏ đang nằm trong đó và lọc danh sách bạn bè.
  void _updateMentionMatches() {
    _mentionStart = null;
    _mentionMatches = const <UserLite>[];

    if (widget.mentionSuggestions.isEmpty) return;

    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return;

    final text = _controller.text;
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final before = text.substring(0, cursor);
    final atIndex = before.lastIndexOf('@');
    if (atIndex < 0) return;

    // '@' phải ở đầu chuỗi hoặc ngay sau khoảng trắng.
    if (atIndex > 0 && !RegExp(r'\s').hasMatch(before[atIndex - 1])) return;

    final query = before.substring(atIndex + 1);
    // Token phải toàn ký tự username hợp lệ (không có khoảng trắng/emoji…).
    if (query.isNotEmpty && !query.split('').every(_usernameChar.hasMatch)) {
      return;
    }

    final q = query.toLowerCase();
    final matches = widget.mentionSuggestions.where((u) {
      if (q.isEmpty) return true;
      return u.userName.toLowerCase().contains(q) ||
          u.name.toLowerCase().contains(q);
    }).take(6).toList();

    if (matches.isEmpty) return;

    _mentionStart = atIndex;
    _mentionMatches = matches;
  }

  /// Chèn `@username ` thay cho token đang gõ dở khi chọn một gợi ý.
  void _selectMention(UserLite user) {
    final start = _mentionStart;
    if (start == null) return;

    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final replacement = '@${user.userName} ';
    final newText =
        text.substring(0, start) + replacement + text.substring(cursor);
    final newCursor = start + replacement.length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    // _onTextChanged sẽ tự chạy và xoá danh sách gợi ý.
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
            // Friend mention suggestions
            if (_mentionMatches.isNotEmpty) _buildMentionSuggestions(isDark),

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

  Widget _buildMentionSuggestions(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.slate200,
          ),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _mentionMatches.length,
        itemBuilder: (context, index) {
          final user = _mentionMatches[index];
          final avatar = (user.avatarUrl ?? '').trim();
          return InkWell(
            onTap: () => _selectMention(user),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2E) : AppTheme.slate200,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color:
                                isDark ? Colors.white54 : AppTheme.slate500,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.slate900,
                          ),
                        ),
                        if (user.userName.isNotEmpty)
                          Text(
                            '@${user.userName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
