import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/feedModel.dart';
import '../../providers/authProvider.dart';
import '../../services/postService.dart';
import '../../widgets/feed/postCard.dart';
import 'userProfileScreen.dart';

/// Hiển thị một bài viết đơn lẻ — dùng khi mở từ thông báo like / comment.
class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  static void open(BuildContext context, String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
  }

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();

  Post? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _postService.getPostById(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = p;
        _loading = false;
        _error = p == null ? 'Bài viết không tồn tại hoặc đã bị xoá.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được bài viết.';
      });
    }
  }

  Future<void> _toggleLike() async {
    final p = _post;
    if (p == null) return;
    try {
      if (p.isLikedByCurrentUser) {
        await _postService.unlikePost(p.id);
      } else {
        await _postService.likePost(p.id);
      }
      await _load();
    } catch (_) {/* bỏ qua, giữ trạng thái cũ */}
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      appBar: AppBar(
        title: const Text(
          'Bài viết',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF242526),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(currentUserId),
    );
  }

  Widget _buildBody(String? currentUserId) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D88FF)),
      );
    }

    if (_error != null || _post == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Không tải được bài viết.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final post = _post!;
    return RefreshIndicator(
      color: const Color(0xFF2D88FF),
      backgroundColor: const Color(0xFF242526),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          PostCard(
            post: post,
            canManage: post.userId == currentUserId,
            onToggleLike: _toggleLike,
            onAuthorTap: post.userId == currentUserId
                ? null
                : () => UserProfileScreen.open(
                      context,
                      post.userId,
                      displayName: post.user.name,
                      avatarUrl: post.user.avatar,
                    ),
          ),
        ],
      ),
    );
  }
}
