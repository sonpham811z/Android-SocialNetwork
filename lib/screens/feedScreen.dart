import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/feedModel.dart';
import '../widgets/feed/feedHeader.dart';
import '../widgets/feed/storiesSection.dart';
import '../widgets/feed/statusInput.dart';
import '../widgets/feed/postCard.dart';
import '../widgets/feed/rightSidebar.dart';
import '../widgets/feed/floatingDock.dart';
import '../widgets/feed/createPostModal.dart';
import '../widgets/feed/voicePlayer.dart';
import '../widgets/profile/profileBody.dart'; // [IMPORT MỚI]

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _showCreateModal = false;
  String? _expandedPostId;
  int _currentTabIndex = 0; // [MỚI] Biến theo dõi đang ở Feed hay Profile

  void _toggleCreateModal() {
    setState(() => _showCreateModal = !_showCreateModal);
  }

  void _toggleComments(String postId) {
    setState(() => _expandedPostId = _expandedPostId == postId ? null : postId);
  }

  // Hàm chuyển tab khi bấm Dock
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: Stack(
        children: [
          // 1. NỘI DUNG CHÍNH (Thay đổi theo tab)
          SafeArea(
            bottom: false,
            child: IndexedStack( // Dùng IndexedStack để giữ trạng thái khi chuyển tab
              index: _currentTabIndex == 5 ? 1 : 0, // Nếu index=5 (Avatar) thì hiện Profile (1), còn lại Feed (0)
              children: [
                // INDEX 0: FEED BODY (Code cũ của bro)
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

                // INDEX 1: PROFILE BODY (Code mới)
                const ProfileBody(),
              ],
            ),
          ),

          // 2. FLOATING DOCK (Luôn nổi ở trên)
          if (!isKeyboardVisible)
            FloatingDock(
              activeIndex: _currentTabIndex,
              onTabSelected: _handleTabChange, // Truyền hàm xử lý vào
            ),

          // 3. MODAL
          if (_showCreateModal)
            CreatePostModal(onClose: _toggleCreateModal),
        ],
      ),
    );
  }

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
           icon: Icon(Icons.tune, color: AppTheme.slate400),
           onPressed: () {},
        ),
      ],
    );
  }
}