import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/authProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../../widgets/feed/postCard.dart';
import 'userProfileScreen.dart';

/// Hiển thị danh sách các bài viết người dùng đã lưu (bookmark).
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadSavedPosts(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F0F10) : AppTheme.slate50;
    final appBarBg = isDark ? const Color(0xFF0F0F10) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final currentUserId = context.watch<AuthProvider>().user?.id ?? '';
    final currentAvatar = context.watch<UserProfileProvider>().profile?.avatar;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bài viết đã lưu',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          final posts = provider.savedPosts;

          if (provider.isLoadingSaved && posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.violetPrimary),
            );
          }

          if (provider.error != null && posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(provider.error!, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadSavedPosts(forceRefresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border,
                      color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                      size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có bài viết nào được lưu',
                    style: TextStyle(
                        color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhấn biểu tượng bookmark trên bài viết để lưu lại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.violetPrimary,
            onRefresh: () => provider.loadSavedPosts(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: PostCard(
                    post: post,
                    currentUserAvatar: currentAvatar,
                    onToggleLike: () =>
                        context.read<PostProvider>().toggleLike(post),
                    onAuthorTap: post.userId == currentUserId
                        ? null
                        : () => UserProfileScreen.open(
                              context,
                              post.userId,
                              displayName: post.user.name,
                              avatarUrl: post.user.avatar,
                            ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
