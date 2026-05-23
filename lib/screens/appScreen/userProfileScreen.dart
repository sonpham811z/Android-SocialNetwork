import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../models/userModel.dart';
import '../../models/friendModel.dart';
import '../../providers/authProvider.dart';
import '../../services/userProfileService.dart';
import '../../services/FriendService.dart';
import '../../services/postService.dart';
import '../../widgets/feed/postCard.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  static void open(
    BuildContext context,
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  User? _profile;
  SocialSummaryModel? _summary;
  List<Post> _posts = [];
  bool _loadingProfile = true;
  bool _loadingPosts = false;
  bool _actionLoading = false;
  String? _profileError;

  final UserProfileService _profileService = UserProfileService();
  final FriendService _friendService = FriendService();
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadSummary(), _loadPosts()]);
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _profileService.getProfileByUserId(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) setState(() => _profileError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _friendService.getSocialSummary(widget.userId);
      if (mounted) setState(() => _summary = res.data);
    } catch (_) {}
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final result = await _postService.getUserPosts(widget.userId);
      if (mounted) setState(() => _posts = result.posts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _toggleFriend() async {
    if (_summary == null) return;
    setState(() => _actionLoading = true);
    try {
      if (_summary!.isFriend) {
        // unfriend not in scope — send to friend provider
      } else if (_summary!.hasPendingRequest) {
        // cancel pending — find request id via sentRequests
        final sentRes = await _friendService.getSentRequests();
        final sentList = sentRes.data?.items ?? [];
        final req = sentList.cast<FriendRequestModel?>().firstWhere(
          (r) => r?.receiver.id == widget.userId,
          orElse: () => null,
        );
        if (req != null) {
          await _friendService.cancelRequest(req.id);
        }
      } else {
        await _friendService.sendFriendRequest(widget.userId);
      }
      await _loadSummary();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_summary == null) return;
    setState(() => _actionLoading = true);
    try {
      if (_summary!.isFollowing) {
        await _friendService.unfollow(widget.userId);
      } else {
        await _friendService.follow(widget.userId);
      }
      await _loadSummary();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null && _profile == null
              ? _buildErrorState(isDark)
              : _buildBody(context, isDark, currentUserId),
    );
  }

  Widget _coverPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF2D1B69)]
              : [const Color(0xFFE8EAF0), const Color(0xFFCDD0DB)],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_outlined,
              size: 56, color: isDark ? Colors.white38 : AppTheme.slate400),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy profile',
            style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.slate700,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _loadingProfile = true;
                _profileError = null;
              });
              _loadAll();
            },
            child: const Text('Thử lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, String currentUserId) {
    final profile = _profile!;
    final name = profile.displayName;
    final avatar = profile.avatar ?? widget.avatarUrl ?? '';
    final cover = profile.coverPhotoUrl ?? '';

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF111214) : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: cover.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverPlaceholder(isDark),
                      ),
                      // Subtle gradient only when real cover photo exists
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _coverPlaceholder(isDark),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildProfileInfo(context, isDark, profile, name, avatar, currentUserId),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : AppTheme.slate900,
              unselectedLabelColor: AppTheme.slate500,
              indicatorColor: AppTheme.violetPrimary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Bài viết'),
                Tab(text: 'Giới thiệu'),
              ],
              onTap: (_) => setState(() {}),
            ),
            isDark,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(isDark, currentUserId),
          _buildAboutTab(isDark, profile),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(
    BuildContext context,
    bool isDark,
    User profile,
    String name,
    String avatar,
    String currentUserId,
  ) {
    final friendsCount = _summary?.friendsCount ?? profile.friendsCount;
    final followersCount = _summary?.followersCount ?? profile.followersCount;
    final followingCount = _summary?.followingCount ?? profile.followingCount;

    return Container(
      color: isDark ? const Color(0xFF111214) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.translate(
                offset: const Offset(0, -32),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF111214) : Colors.white,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2E)
                        : AppTheme.slate200,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Icon(Icons.person,
                            size: 44,
                            color: isDark ? Colors.white54 : AppTheme.slate500)
                        : null,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.userId != currentUserId)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildActionButtons(isDark),
                ),
            ],
          ),

          // Name + verified
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.slate900,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 18, color: Colors.blue),
                    ],
                  ],
                ),
                if ((profile.username ?? '').isNotEmpty)
                  Text(
                    '@${profile.username}',
                    style: TextStyle(
                        color: AppTheme.slate500, fontSize: 13),
                  ),
                if ((profile.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.slate700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    _buildStat(isDark, friendsCount, 'Bạn bè'),
                    const SizedBox(width: 24),
                    _buildStat(isDark, followersCount, 'Người theo dõi'),
                    const SizedBox(width: 24),
                    _buildStat(isDark, followingCount, 'Đang theo dõi'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(bool isDark, int count, String label) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.slate900,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.slate500, fontSize: 11),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _buildActionButtons(bool isDark) {
    if (_summary == null && _actionLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final isFriend = _summary?.isFriend ?? false;
    final isPending = _summary?.hasPendingRequest ?? false;
    final isFollowing = _summary?.isFollowing ?? false;

    return Row(
      children: [
        // Friend button
        _buildOutlineButton(
          isDark: isDark,
          label: isFriend
              ? 'Bạn bè'
              : isPending
                  ? 'Đã gửi'
                  : 'Kết bạn',
          icon: isFriend
              ? Icons.people_rounded
              : isPending
                  ? Icons.hourglass_top_rounded
                  : Icons.person_add_alt_1_rounded,
          filled: !isFriend && !isPending,
          onTap: _actionLoading ? null : _toggleFriend,
        ),
        const SizedBox(width: 8),
        // Follow button
        _buildOutlineButton(
          isDark: isDark,
          label: isFollowing ? 'Đang theo dõi' : 'Theo dõi',
          icon: isFollowing
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded,
          filled: false,
          onTap: _actionLoading ? null : _toggleFollow,
        ),
      ],
    );
  }

  Widget _buildOutlineButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? AppTheme.violetPrimary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.slate100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled
                ? AppTheme.violetPrimary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.slate300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppTheme.slate700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppTheme.slate700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(bool isDark, String currentUserId) {
    if (_loadingPosts && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 48,
                color: isDark ? Colors.white24 : AppTheme.slate300),
            const SizedBox(height: 12),
            Text(
              'Chưa có bài viết nào',
              style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.slate500,
                  fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: PostCard(
            post: post,
            canManage: false,
            onToggleLike: () {},
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(bool isDark, User profile) {
    final rows = <_InfoRow>[];

    if ((profile.location ?? profile.city ?? '').isNotEmpty) {
      final loc = profile.location ?? profile.city ?? '';
      rows.add(_InfoRow(Icons.location_on_outlined, 'Địa điểm', loc));
    }
    if ((profile.website ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.link_rounded, 'Website', profile.website!));
    }
    if ((profile.dateOfBirth ?? '').isNotEmpty) {
      rows.add(_InfoRow(
          Icons.cake_outlined, 'Sinh nhật', profile.dateOfBirth!));
    }
    if ((profile.createdAt ?? '').isNotEmpty) {
      rows.add(_InfoRow(
          Icons.calendar_today_outlined, 'Tham gia', _formatDate(profile.createdAt!)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rows.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'Chưa có thông tin',
                style: TextStyle(
                    color: isDark ? Colors.white38 : AppTheme.slate400,
                    fontSize: 14),
              ),
            ),
          )
        else
          ...rows.map((r) => _buildInfoTile(isDark, r)),
      ],
    );
  }

  Widget _buildInfoTile(bool isDark, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(row.icon,
              size: 20,
              color: isDark ? Colors.white38 : AppTheme.slate400),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style:
                    TextStyle(color: AppTheme.slate500, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                row.value,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.slate800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = [
        'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
        'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
        'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  const _TabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF111214) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
