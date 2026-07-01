import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import 'commentItem.dart';
import 'commentSkeleton.dart';

class CommentList extends StatefulWidget {
  final List<Comment> comments;
  final bool isLoading;
  final String? errorMessage;
  final String currentUserId;
  final ScrollController scrollController;
  final void Function(Comment comment)? onReply;
  final Future<bool> Function(String commentId, String content)? onEdit;
  final void Function(String commentId)? onDelete;
  final void Function(String commentId)? onLike;
  final void Function(String userId)? onAvatarTap;
  final void Function(String username)? onMentionTap;
  final VoidCallback? onRetry;
  final Set<String> newCommentIds;

  const CommentList({
    super.key,
    required this.comments,
    this.isLoading = false,
    this.errorMessage,
    required this.currentUserId,
    required this.scrollController,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onLike,
    this.onAvatarTap,
    this.onMentionTap,
    this.onRetry,
    this.newCommentIds = const {},
  });

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  // Tracks which parent comment IDs have been expanded to show all replies
  final Set<String> _expandedComments = {};

  static const int _collapsedReplyLimit = 2;

  @override
  Widget build(BuildContext context) {
    final comments = widget.comments;
    final isLoading = widget.isLoading;
    final errorMessage = widget.errorMessage;
    final currentUserId = widget.currentUserId;
    final scrollController = widget.scrollController;
    final onReply = widget.onReply;
    final onEdit = widget.onEdit;
    final onDelete = widget.onDelete;
    final onLike = widget.onLike;
    final onAvatarTap = widget.onAvatarTap;
    final onMentionTap = widget.onMentionTap;
    final onRetry = widget.onRetry;
    final newCommentIds = widget.newCommentIds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading state
    if (isLoading && comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CommentSkeleton(count: 4),
      );
    }

    // Error state
    if (errorMessage != null && comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: isDark ? Colors.white38 : AppTheme.slate400,
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể tải bình luận',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.slate700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                errorMessage,
                style: TextStyle(
                  color: AppTheme.slate500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.violetPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: isDark ? Colors.white24 : AppTheme.slate300,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có bình luận nào',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.slate500,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hãy là người đầu tiên bình luận!',
                style: TextStyle(
                  color: AppTheme.slate400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group comments: parent (no parentCommentId) and children
    final parentComments =
        comments.where((c) => c.parentCommentId == null).toList();
    final repliesMap = <String, List<Comment>>{};
    for (final c in comments) {
      final parentId = c.parentCommentId;
      if (parentId != null) {
        repliesMap.putIfAbsent(parentId, () => []).add(c);
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: parentComments.length,
      itemBuilder: (context, index) {
        final parent = parentComments[index];
        final replies = repliesMap[parent.id] ?? [];

        final isExpanded = _expandedComments.contains(parent.id);
        final hiddenCount = replies.length - _collapsedReplyLimit;
        final visibleReplies = (replies.length > _collapsedReplyLimit && !isExpanded)
            ? replies.sublist(0, _collapsedReplyLimit)
            : replies;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent comment
            CommentItem(
              comment: parent,
              isReply: false,
              isOwnComment: parent.userId == currentUserId,
              isNew: newCommentIds.contains(parent.id),
              onReply: () => onReply?.call(parent),
              onEdit: (content) async {
                return await onEdit?.call(parent.id, content) ?? false;
              },
              onDelete: () => onDelete?.call(parent.id),
              onLike: () => onLike?.call(parent.id),
              onAvatarTap: () => onAvatarTap?.call(parent.userId),
              onMentionTap: onMentionTap,
            ),
            // Visible replies
            ...visibleReplies.map(
              (reply) => CommentItem(
                comment: reply,
                isReply: true,
                isOwnComment: reply.userId == currentUserId,
                isNew: newCommentIds.contains(reply.id),
                onReply: () => onReply?.call(parent),
                onEdit: (content) async {
                  return await onEdit?.call(reply.id, content) ?? false;
                },
                onDelete: () => onDelete?.call(reply.id),
                onLike: () => onLike?.call(reply.id),
                onAvatarTap: () => onAvatarTap?.call(reply.userId),
                onMentionTap: onMentionTap,
              ),
            ),
            // Expand / collapse toggle
            if (replies.length > _collapsedReplyLimit)
              Padding(
                padding: const EdgeInsets.only(left: 56, bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedComments.remove(parent.id);
                    } else {
                      _expandedComments.add(parent.id);
                    }
                  }),
                  child: Text(
                    isExpanded
                        ? 'Ẩn bớt câu trả lời'
                        : 'Xem thêm $hiddenCount câu trả lời',
                    style: TextStyle(
                      color: AppTheme.violetPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
