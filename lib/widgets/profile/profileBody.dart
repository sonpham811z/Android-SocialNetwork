import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../models/userModel.dart';
import '../../providers/userProfileProvider.dart';
import '../feed/postCard.dart';
import '../../screens/settings/settingsScreen.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    Future.microtask(
      () => context.read<UserProfileProvider>().loadMyProfile(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final myPosts = MockData.posts; 

    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading && profileProvider.profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.error != null &&
            profileProvider.profile == null) {
          return Center(
            child: Text(
              profileProvider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final user = profileProvider.profile;

        if (user == null) {
          return const Center(
            child: Text('Không tìm thấy thông tin người dùng'),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(isDark, user),
            ),

        SliverPersistentHeader(
          delegate: _SliverAppBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: isDark ? Colors.white : AppTheme.violetPrimary,
              labelColor: isDark ? Colors.white : AppTheme.slate900,
              unselectedLabelColor: AppTheme.slate500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              dividerColor: isDark ? AppTheme.slate800 : AppTheme.slate200,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on_rounded), text: "Posts"),
                Tab(icon: Icon(Icons.bookmark_border_rounded), text: "Saved"),
                Tab(icon: Icon(Icons.favorite_border_rounded), text: "Liked"),
                Tab(icon: Icon(Icons.alternate_email_rounded), text: "Mentions"),
              ],
            ),
            isDark,
          ),
          pinned: true,
        ),

        SliverPadding(
          padding: const EdgeInsets.only(top: 16, bottom: 100), // Bottom padding cho Dock
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Demo: Tab đầu tiên hiện List Post, các tab khác hiện Placeholder
                if (_tabController.index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: PostCard(
                      post: myPosts[index % myPosts.length], // Loop data cho dài
                      onToggleComments: () {}, // Xử lý sau
                    ),
                  );
                } else {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Text(
                      "Chưa có dữ liệu",
                      style: TextStyle(color: AppTheme.slate500),
                    ),
                  );
                }
              },
              childCount: myPosts.length, // Số lượng bài post
            ),
          ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isDark, User user) {
    final coverUrl = user.avatar ??
        'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=800&h=400&fit=crop';

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(coverUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F10) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(isDark, Icons.edit, "Edit Profile"),
                  const SizedBox(width: 8),
                  _buildIconOnlyButton(isDark, Icons.share_outlined, onTap: () {}),
                  const SizedBox(width: 8),
                  // NÚT SETTINGS MỚI THÊM NÈ BRO
                  _buildIconOnlyButton(
                    isDark, 
                    Icons.settings_outlined, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ),
              Text(
                '@${user.email.split('@').first}',
                style: const TextStyle(color: AppTheme.slate500, fontSize: 14),
              ),

              const SizedBox(height: 12),

              Text(
                'Bio đang cập nhật...',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.slate800,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.slate500),
                  const SizedBox(width: 4),
                  const Text('Đang cập nhật',
                      style: TextStyle(
                          color: AppTheme.slate500, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.slate500),
                  const SizedBox(width: 4),
                  const Text("Joined Jan 2023", style: TextStyle(color: AppTheme.slate500, fontSize: 13)),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _buildStatItem(isDark, '0', "Posts"),
                  const SizedBox(width: 24),
                  _buildStatItem(isDark, '0', "Followers"),
                  const SizedBox(width: 24),
                  _buildStatItem(isDark, '0', "Following"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isDark, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : AppTheme.slate200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.slate700 : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOnlyButton(bool isDark, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? AppTheme.slate700 : Colors.transparent),
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
      )
    );
  }

  Widget _buildStatItem(bool isDark, String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.slate500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Delegate để làm Sticky TabBar (Header dính)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this._tabBar, this.isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF0F0F10) : Colors.white, // Nền đè lên nội dung khi cuộn
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}