import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../common/mentionText.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final bool isReply;
  final bool isOwnComment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final Future<bool> Function(String content)? onEdit;
  final VoidCallback? onLike;
  final VoidCallback? onAvatarTap;
  final bool isNew;

  const CommentItem({
    super.key,
    required this.comment,
    this.isReply = false,
    this.isOwnComment = false,
    this.onReply,
    this.onDelete,
    this.onEdit,
    this.onLike,
    this.onAvatarTap,
    this.isNew = false,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isEditing = false;
  late TextEditingController _editController;

  // Like heart bounce
  bool _heartBouncing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    if (widget.isNew) {
      _fadeController.forward();
    } else {
      _fadeController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    setState(() => _heartBouncing = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _heartBouncing = false);
    });
    widget.onLike?.call();
  }

  void _showOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (widget.isOwnComment) ...[
              ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: isDark ? Colors.white70 : AppTheme.slate700),
                title: Text('Chỉnh sửa bình luận',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.slate900)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isEditing = true);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Xóa bình luận',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.reply_outlined,
                  color: isDark ? Colors.white70 : AppTheme.slate700),
              title: Text('Trả lời',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.slate900)),
              onTap: () {
                Navigator.pop(context);
                widget.onReply?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comment = widget.comment;
    final isLiked = comment.isLikedByCurrentUser;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.isReply ? 44 : 0,
          bottom: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──
            GestureDetector(
              onTap: widget.onAvatarTap,
              onLongPress: () => _showOptions(context),
              child: CircleAvatar(
                radius: widget.isReply ? 14 : 18,
                backgroundColor:
                    isDark ? const Color(0xFF2A2A2E) : AppTheme.slate200,
                backgroundImage: comment.user.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(comment.user.avatar)
                    : null,
                child: comment.user.avatar.isEmpty
                    ? Icon(Icons.person,
                        size: widget.isReply ? 14 : 18,
                        color: isDark ? Colors.white54 : AppTheme.slate500)
                    : null,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Comment bubble ──
                  GestureDetector(
                    onLongPress: () => _showOptions(context),
                    onDoubleTap: _handleLike,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2E)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _isEditing
                          ? _buildEditMode(isDark)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username
                                Text(
                                  comment.user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.slate900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Content
                                MentionText(
                                  comment.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : AppTheme.slate900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── Action row ──
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 5),
                    child: Row(
                      children: [
                        // Timestamp
                        Text(
                          comment.timestamp,
                          style: TextStyle(
                              color: AppTheme.slate500, fontSize: 11),
                        ),
                        const SizedBox(width: 14),

                        // ── LIKE BUTTON ──
                        GestureDetector(
                          onTap: _handleLike,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: _heartBouncing ? 1.4 : 1.0,
                                duration:
                                    const Duration(milliseconds: 200),
                                curve: Curves.elasticOut,
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey(isLiked),
                                    size: 13,
                                    color: isLiked
                                        ? Colors.redAccent
                                        : AppTheme.slate500,
                                  ),
                                ),
                              ),
                              if (comment.likesCount > 0) ...[
                                const SizedBox(width: 3),
                                AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Text(
                                    '${comment.likesCount}',
                                    key: ValueKey(comment.likesCount),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isLiked
                                          ? Colors.redAccent
                                          : AppTheme.slate500,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              Text(
                                isLiked ? 'Đã thích' : 'Thích',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isLiked
                                      ? Colors.redAccent
                                      : AppTheme.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // ── REPLY BUTTON ──
                        GestureDetector(
                          onTap: widget.onReply,
                          child: Text(
                            'Trả lời',
                            style: TextStyle(
                              color: AppTheme.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Edited tag
                        if (comment.updatedAt != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            '• Đã sửa',
                            style: TextStyle(
                              color: AppTheme.slate400,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildEditMode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _editController,
          autofocus: true,
          maxLines: null,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppTheme.slate900),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Chỉnh sửa bình luận...',
            hintStyle: TextStyle(color: AppTheme.slate400),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                _editController.text = widget.comment.content;
                setState(() => _isEditing = false);
              },
              child: Text('Hủy',
                  style: TextStyle(
                      color: AppTheme.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final newContent = _editController.text.trim();
                if (newContent.isEmpty ||
                    newContent == widget.comment.content) {
                  setState(() => _isEditing = false);
                  return;
                }
                final success =
                    await widget.onEdit?.call(newContent) ?? false;
                if (success && mounted) setState(() => _isEditing = false);
              },
              child: Text('Lưu',
                  style: TextStyle(
                      color: AppTheme.violetPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
