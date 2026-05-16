import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/userProfileProvider.dart';
import 'commentInput.dart';
import 'commentList.dart';

class CommentBottomSheet extends StatefulWidget {
  final Post post;

  const CommentBottomSheet({super.key, required this.post});

  /// Helper to show the bottom sheet from any screen.
  static void show(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(post: post),
    );
  }

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoading = true;
  String? _error;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  final Set<String> _newCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<PostProvider>().loadComments(widget.post.id);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.parentCommentId ?? comment.id;
      _replyingToUserName = comment.user.name;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Future<bool> _handleSubmit(String content) async {
    final postProvider = context.read<PostProvider>();
    final success = await postProvider.createComment(
      widget.post.id,
      content,
      parentCommentId: _replyingToCommentId,
    );

    if (success && mounted) {
      // Find the ID of the newly added comment for animation
      final updatedPost = postProvider.feedPosts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      );
      final allComments = updatedPost.commentsList ?? [];
      if (allComments.isNotEmpty) {
        setState(() {
          _newCommentIds.add(allComments.last.id);
        });
      }

      // Cancel reply mode
      _cancelReply();

      // Scroll to bottom after a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    return success;
  }

  Future<bool> _handleEdit(String commentId, String content) async {
    return await context
        .read<PostProvider>()
        .updateComment(widget.post.id, commentId, content);
  }

  void _handleDelete(String commentId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa bình luận',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.slate900,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa bình luận này?',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppTheme.slate600,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.slate500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<PostProvider>()
          .deleteComment(widget.post.id, commentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final currentUserId = context.watch<AuthProvider>().user?.id ?? '';
    final currentAvatar =
        context.watch<UserProfileProvider>().profile?.avatar;

    // Get the latest post data from provider
    final postProvider = context.watch<PostProvider>();
    final currentPost = postProvider.feedPosts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    final comments = currentPost.commentsList ?? [];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, sheetScrollController) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // ─── Handle bar ───
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ─── Header ───
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bình luận',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.slate900,
                        ),
                      ),
                      Row(
                        children: [
                          if (comments.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                '${comments.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : AppTheme.slate100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark
                                    ? Colors.white70
                                    : AppTheme.slate600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color:
                      isDark ? Colors.white.withOpacity(0.06) : AppTheme.slate200,
                ),

                // ─── Comment list ───
                Expanded(
                  child: CommentList(
                    comments: comments,
                    isLoading: _isLoading,
                    errorMessage: _error,
                    currentUserId: currentUserId,
                    scrollController: _scrollController,
                    newCommentIds: _newCommentIds,
                    onReply: _handleReply,
                    onEdit: _handleEdit,
                    onDelete: _handleDelete,
                    onLike: (commentId) {
                      context.read<PostProvider>().toggleCommentLike(
                            widget.post.id,
                            commentId,
                          );
                    },
                    onRetry: _loadComments,
                  ),
                ),

                // ─── Comment input ───
                AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: CommentInput(
                    avatarUrl: currentAvatar,
                    replyingToUser: _replyingToUserName,
                    onCancelReply: _cancelReply,
                    focusNode: _inputFocusNode,
                    onSubmit: _handleSubmit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
