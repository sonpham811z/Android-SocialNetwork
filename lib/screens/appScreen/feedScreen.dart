import 'package:flutter/material.dart';
import 'package:flutter_social_app/screens/appScreen/friendRequestScreen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_social_app/screens/appScreen/homeScreen.dart';
import '../../config/theme.dart';
import '../../providers/authProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../../providers/postProvider.dart';
import '../../widgets/feed/feedHeader.dart';
import '../../widgets/feed/statusInput.dart';
import '../../widgets/feed/postCard.dart';
import '../../widgets/feed/floatingDock.dart';
import '../../widgets/feed/createPostModal.dart';
import '../../widgets/messages/messageListBody.dart';
import '../../widgets/profile/profileBody.dart'; 
import 'notificationScreen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _showCreateModal = false;
  String? _expandedPostId;
  int _currentTabIndex = 0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isCheckingAuth) {
        // Wait for auth check to complete before loading feed
        late final VoidCallback listener;
        listener = () {
          if (!authProvider.isCheckingAuth) {
            authProvider.removeListener(listener);
            if (mounted) context.read<PostProvider>().loadFeed();
          }
        };
        authProvider.addListener(listener);
      } else {
        context.read<PostProvider>().loadFeed();
      }
    });
  }

  void _toggleCreateModal() {
    setState(() => _showCreateModal = !_showCreateModal);
  }

  void _toggleComments(String postId) {
    setState(() => _expandedPostId = _expandedPostId == postId ? null : postId);
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentTabIndex = index; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final postProvider = context.watch<PostProvider>();
    final currentAvatar = context.watch<UserProfileProvider>().profile?.avatar;
    final feedPosts = postProvider.feedPosts;

    // Logic xác định trang nào hiển thị trong IndexedStack
    int getStackIndex(int tabIndex) {
        if (tabIndex == 0) return 0; // Trang chủ (Feed)
        if (tabIndex == 2) return 4; // NHẤN NÚT BẠN BÈ -> HIỆN TRANG INDEX 4
        if (tabIndex == 3) return 2; // Message
        if (tabIndex == 4) return 3; // Notification
        if (tabIndex == 5) return 1; // Profile
        return 0; // Mặc định
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack( 
              index: getStackIndex(_currentTabIndex),
              children: [
                // INDEX 0: FEED
                Column(
                  children: [
                    FeedHeader(onCreatePost: _toggleCreateModal),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 640),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFeedHeader(),
                                        const SizedBox(height: 24),
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
                                        else if ((postProvider.error ?? '').isNotEmpty && feedPosts.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Column(
                                              children: [
                                                Text(
                                                  postProvider.error!,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                                const SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () => context.read<PostProvider>().loadFeed(forceRefresh: true),
                                                  child: const Text('Tải lại bài viết'),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (feedPosts.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 24),
                                            child: Text(
                                              'Chưa có bài viết nào trong bảng tin.',
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                          )
                                        else
                                          ...feedPosts.map(
                                            (post) => Padding(
                                              padding: const EdgeInsets.only(bottom: 32),
                                              child: PostCard(
                                                post: post,
                                                isExpanded: _expandedPostId == post.id,
                                                onToggleComments: () => _toggleComments(post.id),
                                                currentUserAvatar: currentAvatar,
                                                onToggleLike: () => context.read<PostProvider>().toggleLike(post),
                                                onLoadComments: () => context.read<PostProvider>().loadComments(post.id),
                                                onSubmitComment: (content) =>
                                                    context.read<PostProvider>().createComment(post.id, content),
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
                        ),
                      ),
                    ),
                  ],
                ),
                // INDEX 1: PROFILE
                const ProfileBody(),
                // INDEX 2: MESSAGE
                const MessageListBody(),
                // INDEX 3: NOTIFICATION
                const NotificationScreen(),
                /// INDEX 4: FRIEND REQUEST
                 const FriendRequestScreen()
              ],
            ),
          ),

          if (!isKeyboardVisible)
            FloatingDock(
              activeIndex: _currentTabIndex,
              onTabSelected: _handleTabChange,
              avatarUrl: currentAvatar,
            ),

          if (_showCreateModal)
            CreatePostModal(onClose: _toggleCreateModal),
        ],
      ),
    );
  } // <--- Thêm dấu đóng hàm build ở đây

  Widget _buildFeedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Bảng tin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: AppTheme.slate400),
          onPressed: () {},
        ),
      ],
    );
  }
}