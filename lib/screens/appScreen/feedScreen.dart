import 'package:flutter/material.dart';
import 'package:flutter_social_app/screens/appScreen/friendRequestScreen.dart';
import 'package:flutter_social_app/screens/appScreen/homeScreen.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../widgets/feed/feedHeader.dart';
import '../../widgets/feed/storiesSection.dart';
import '../../widgets/feed/statusInput.dart';
import '../../widgets/feed/postCard.dart';
import '../../widgets/feed/rightSidebar.dart';
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
    final isDesktop = size.width > 1024;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                                        const StoriesSection(),
                                        const SizedBox(height: 24),
                                        StatusInput(onTap: _toggleCreateModal),
                                        const SizedBox(height: 24),
                                        ...MockData.posts.map(
                                          (post) => Padding(
                                            padding: const EdgeInsets.only(bottom: 32),
                                            child: PostCard(
                                              post: post,
                                              isExpanded: _expandedPostId == post.id,
                                              onToggleComments: () => _toggleComments(post.id),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 40),
                                  const RightSidebar(),
                                ],
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