import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friendModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/friendProvider.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _receiverIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _reloadAll();
    });
  }

  Future<void> _reloadAll() async {
    final friendProvider = context.read<FriendProvider>();
    final myUserId = context.read<AuthProvider>().user?.id ?? '';

    final futures = <Future<void>>[
      friendProvider.loadMyFriends(),
      friendProvider.loadReceivedRequests(),
      friendProvider.loadSentRequests(),
      friendProvider.loadBlockedUsers(),
    ];

    if (myUserId.isNotEmpty) {
      futures.add(friendProvider.loadFollowers(myUserId));
      futures.add(friendProvider.loadFollowing(myUserId));
    }

    await Future.wait([
      ...futures,
    ]);
  }

  @override
  void dispose() {
    _receiverIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        final receivedRequests = friendProvider.receivedRequests;
        final sentRequests = friendProvider.sentRequests;
        final friends = friendProvider.friends;

        return Container(
          color: const Color(0xFF0F0F10),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF18191B),
                  border: Border(
                    bottom: BorderSide(color: Colors.white10, width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bạn bè',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 20),
                          onPressed: _reloadAll,
                        ),
                      ],
                    ),
                    _buildSendRequestBox(friendProvider),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: const Color(0xFF2374E1),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Bạn bè (${friends.length})'),
                        Tab(text: 'Đã nhận (${receivedRequests.length})'),
                        Tab(text: 'Đã gửi (${sentRequests.length})'),
                        const Tab(text: 'Theo dõi'),
                        const Tab(text: 'Đã chặn'),
                      ],
                    ),
                  ],
                ),
              ),
              if (friendProvider.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    friendProvider.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(friendProvider),
                    _buildReceivedTab(friendProvider),
                    _buildSentTab(friendProvider),
                    _buildFollowingTab(friendProvider),
                    _buildBlockedTab(friendProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendRequestBox(FriendProvider friendProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242526),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _receiverIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nhập userId để gửi lời mời',
                hintStyle: TextStyle(color: Colors.white54),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: friendProvider.isActionLoading
                ? null
                : () async {
                    final id = _receiverIdController.text.trim();
                    if (id.isEmpty) return;

                    final success = await friendProvider.sendFriendRequest(id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Đã gửi lời mời kết bạn.'
                              : (friendProvider.error ?? 'Không thể gửi lời mời.'),
                        ),
                      ),
                    );
                    if (success) {
                      _receiverIdController.clear();
                    }
                  },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading && friendProvider.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.friends.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa có bạn bè nào.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.friends.length,
      itemBuilder: (context, index) {
        final entry = friendProvider.friends[index];
        return _buildUserActionTile(
          user: entry.friend,
          subtitle: 'Kết bạn ${_toRelativeTime(entry.createdAt)}',
          actions: [
            _actionButton(
              label: 'Bỏ kết bạn',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.unfriend(entry.friend.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã bỏ kết bạn.' : (friendProvider.error ?? 'Không thể bỏ kết bạn.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Theo dõi',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.follow(entry.friend.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã theo dõi.' : (friendProvider.error ?? 'Không thể theo dõi.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Chặn',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.blockUser(entry.friend.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã chặn người dùng.' : (friendProvider.error ?? 'Không thể chặn.'))),
                      );
                      if (success) {
                        await _reloadAll();
                      }
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceivedTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading && friendProvider.receivedRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.receivedRequests.isEmpty) {
      return const Center(
        child: Text(
          'Không có lời mời nào.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.receivedRequests.length,
      itemBuilder: (context, index) {
        final request = friendProvider.receivedRequests[index];
        return _buildUserActionTile(
          user: request.sender,
          subtitle: 'Đã gửi ${_toRelativeTime(request.createdAt)}',
          actions: [
            _actionButton(
              label: 'Xác nhận',
              primary: true,
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.acceptRequest(request.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã chấp nhận lời mời.' : (friendProvider.error ?? 'Không thể chấp nhận lời mời.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Từ chối',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.declineRequest(request.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã từ chối lời mời.' : (friendProvider.error ?? 'Không thể từ chối lời mời.'))),
                      );
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSentTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading && friendProvider.sentRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.sentRequests.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa gửi lời mời nào.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.sentRequests.length,
      itemBuilder: (context, index) {
        final request = friendProvider.sentRequests[index];
        return _buildUserActionTile(
          user: request.receiver,
          subtitle: 'Đã gửi ${_toRelativeTime(request.createdAt)}',
          actions: [
            _actionButton(
              label: 'Hủy lời mời',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.cancelRequest(request.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã hủy lời mời.' : (friendProvider.error ?? 'Không thể hủy lời mời.'))),
                      );
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowingTab(FriendProvider friendProvider) {
    final followers = friendProvider.followers;
    final following = friendProvider.following;

    if (friendProvider.isLoading && followers.isEmpty && following.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followers.isEmpty && following.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu theo dõi.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView(
      children: [
        _buildSectionTitle('Người theo dõi (${followers.length})'),
        ...followers.map((entry) => _buildUserActionTile(
              user: entry.user,
              subtitle: 'Theo dõi bạn ${_toRelativeTime(entry.createdAt)}',
              actions: [
                _actionButton(
                  label: 'Theo dõi lại',
                  onTap: friendProvider.isActionLoading
                      ? null
                      : () async {
                          final success = await friendProvider.follow(entry.user.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Đã theo dõi lại.' : (friendProvider.error ?? 'Không thể theo dõi.'))),
                          );
                        },
                ),
              ],
            )),
        _buildSectionTitle('Bạn đang theo dõi (${following.length})'),
        ...following.map((entry) => _buildUserActionTile(
              user: entry.user,
              subtitle: 'Theo dõi ${_toRelativeTime(entry.createdAt)}',
              actions: [
                _actionButton(
                  label: 'Bỏ theo dõi',
                  onTap: friendProvider.isActionLoading
                      ? null
                      : () async {
                          final success = await friendProvider.unfollow(entry.user.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Đã bỏ theo dõi.' : (friendProvider.error ?? 'Không thể bỏ theo dõi.'))),
                          );
                        },
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildSectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBlockedTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading && friendProvider.blockedUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.blockedUsers.isEmpty) {
      return const Center(
        child: Text('Bạn chưa chặn ai.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.blockedUsers.length,
      itemBuilder: (context, index) {
        final entry = friendProvider.blockedUsers[index];
        return _buildUserActionTile(
          user: entry.blockedUser,
          subtitle: 'Đã chặn ${_toRelativeTime(entry.createdAt)}',
          actions: [
            _actionButton(
              label: 'Bỏ chặn',
              onTap: friendProvider.isActionLoading
                  ? null
                  : () async {
                      final success = await friendProvider.unblockUser(entry.blockedUser.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã bỏ chặn.' : (friendProvider.error ?? 'Không thể bỏ chặn.'))),
                      );
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserActionTile({
    required UserLite user,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white12,
            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(user.name, user.userName, user.id),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Future<void> Function()? onTap,
    bool primary = false,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? const Color(0xFF2374E1) : const Color(0xFF303136),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF303136),
        ),
        onPressed: onTap == null
            ? null
            : () async {
                await onTap();
              },
        child: Text(label),
      ),
    );
  }

  String _toRelativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '$weeks tuần';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months tháng';
    final years = (diff.inDays / 365).floor();
    return '$years năm';
  }

  String _displayName(String name, String userName, String userId) {
    final cleanName = name.trim();
    final cleanUserName = userName.trim();

    final nameIsUnknown =
        cleanName.isEmpty || cleanName.toLowerCase() == 'unknown';
    final userNameIsUnknown =
        cleanUserName.isEmpty || cleanUserName.toLowerCase() == 'unknown';

    if (!userNameIsUnknown) return cleanUserName;
    if (!nameIsUnknown) return cleanName;

    if (userId.isNotEmpty) {
      final shortId = userId.length >= 8 ? userId.substring(0, 8) : userId;
      return 'Người dùng #$shortId';
    }

    return 'Người dùng không xác định';
  }
}