import 'package:flutter/material.dart';
import '../friends/friends_screen.dart';
import '../campusBoard/campusBoardScreen.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/notificationProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../../providers/postProvider.dart';
import '../../widgets/feed/statusInput.dart';
import '../../widgets/feed/storiesSection.dart';
import '../../widgets/feed/postCard.dart';
import '../../widgets/feed/floatingDock.dart';
import '../../widgets/feed/createPostModal.dart';
import '../../widgets/messages/messageListBody.dart';
import '../../widgets/profile/profileBody.dart';
import 'notificationScreen.dart';
import 'userProfileScreen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _showCreateModal = false;
  int _currentTabIndex = 0;

  final ScrollController _feedScrollController = ScrollController();
  bool _isDockVisible = true;
  double _lastScrollOffset = 0;
  static const double _scrollThreshold = 15.0;

  @override
  void initState() {
    super.initState();
    _feedScrollController.addListener(_onFeedScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isCheckingAuth) {
        late final VoidCallback listener;
        listener = () {
          if (!authProvider.isCheckingAuth) {
            authProvider.removeListener(listener);
            if (mounted) {
              context.read<PostProvider>().loadFeed();
              context.read<NotificationProvider>().init();
            }
          }
        };
        authProvider.addListener(listener);
      } else {
        context.read<PostProvider>().loadFeed();
        context.read<NotificationProvider>().init();
      }
    });
  }

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    final currentOffset = _feedScrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    if (delta > _scrollThreshold && _isDockVisible) {
      setState(() => _isDockVisible = false);
    } else if (delta < -_scrollThreshold && !_isDockVisible) {
      setState(() => _isDockVisible = true);
    }

    if (currentOffset <= 0 && !_isDockVisible) {
      setState(() => _isDockVisible = true);
    }

    _lastScrollOffset = currentOffset;
  }

  void _toggleCreateModal() {
    setState(() => _showCreateModal = !_showCreateModal);
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentTabIndex = index;
      _isDockVisible = true;
    });
  }

  Future<void> _showEditPostDialog(PostProvider postProvider, Post post) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: post.content);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          title: Text(
            'Chỉnh sửa bài viết',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
            decoration: InputDecoration(
              hintText: 'Nội dung bài viết',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : AppTheme.slate500,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) return;

    final success = await context.read<PostProvider>().updatePost(
      postId: post.id,
      content: controller.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Đã cập nhật bài viết.'
            : (postProvider.error ?? 'Không thể cập nhật bài viết.')),
      ),
    );
  }

  Future<void> _confirmDeletePost(PostProvider postProvider, Post post) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          title: Text(
            'Xóa bài viết',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
          ),
          content: Text(
            'Bạn có chắc muốn xóa bài viết này không?',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.slate700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<PostProvider>().deletePost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Đã xóa bài viết.'
            : (postProvider.error ?? 'Không thể xóa bài viết.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final postProvider = context.watch<PostProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id ?? '';
    final currentAvatar = context.watch<UserProfileProvider>().profile?.avatar;
    final feedPosts = postProvider.feedPosts;
    final notificationBadge =
        context.watch<NotificationProvider>().unreadCount;

    int getStackIndex(int tabIndex) {
      if (tabIndex == 0) return 0;
      if (tabIndex == 1) return 5;
      if (tabIndex == 2) return 4;
      if (tabIndex == 3) return 2;
      if (tabIndex == 4) return 3;
      if (tabIndex == 5) return 1;
      return 0;
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F10) : Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: getStackIndex(_currentTabIndex),
              children: [
                // INDEX 0: FEED
                SingleChildScrollView(
                  controller: _feedScrollController,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stories + mini header (ở trên cùng, không có gì trước nó)
                            StoriesSection(onCreatePost: _toggleCreateModal),
                            const SizedBox(height: 16),
                            StatusInput(
                              onTap: _toggleCreateModal,
                              avatarUrl: currentAvatar,
                            ),
                            const SizedBox(height: 24),
                            if (postProvider.isLoadingFeed && feedPosts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if ((postProvider.error ?? '').isNotEmpty &&
                                feedPosts.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Text(
                                      postProvider.error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : AppTheme.slate700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () => context
                                          .read<PostProvider>()
                                          .loadFeed(forceRefresh: true),
                                      child: const Text('Tải lại bài viết'),
                                    ),
                                  ],
                                ),
                              )
                            else if (feedPosts.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Chưa có bài viết nào trong bảng tin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : AppTheme.slate700,
                                  ),
                                ),
                              )
                            else
                              ...feedPosts.map(
                                (post) => Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: PostCard(
                                    post: post,
                                    currentUserAvatar: currentAvatar,
                                    canManage: post.userId == currentUserId,
                                    onToggleLike: () => context
                                        .read<PostProvider>()
                                        .toggleLike(post),
                                    onEditPost: () => _showEditPostDialog(
                                        postProvider, post),
                                    onDeletePost: () => _confirmDeletePost(
                                        postProvider, post),
                                    onAuthorTap: post.userId == currentUserId
                                        ? null
                                        : () => UserProfileScreen.open(
                                              context,
                                              post.userId,
                                              displayName: post.user.name,
                                              avatarUrl: post.user.avatar,
                                            ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // INDEX 1: PROFILE
                const ProfileBody(),
                // INDEX 2: MESSAGE
                const MessageListBody(),
                // INDEX 3: NOTIFICATION
                const NotificationScreen(),
                // INDEX 4: FRIENDS
                const FriendsScreen(),
                // INDEX 5: CAMPUS BOARD
                const CampusBoardScreen(),
              ],
            ),
          ),

          if (!isKeyboardVisible)
            FloatingDock(
              activeIndex: _currentTabIndex,
              onTabSelected: _handleTabChange,
              avatarUrl: currentAvatar,
              isVisible: _isDockVisible,
              notificationBadge: notificationBadge,
            ),

          if (_showCreateModal)
            CreatePostModal(onClose: _toggleCreateModal),
        ],
      ),
    );
  }
}
