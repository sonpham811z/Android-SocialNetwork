import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/friendModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/friendProvider.dart';
import '../../services/userProfileService.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchUserNameController = TextEditingController();
  final Map<String, String> _busyItems = <String, String>{};
  final UserProfileService _userProfileService = UserProfileService();

  List<UserSearchResult> _searchResults = <UserSearchResult>[];
  bool _isSearchingUsers = false;
  String? _searchError;
  String _searchedKeyword = '';

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

  bool _isItemBusy(String itemKey) => _busyItems.containsKey(itemKey);

  bool _isActionBusy(String itemKey, String actionTag) =>
      _busyItems[itemKey] == actionTag;

  Future<bool?> _runItemAction({
    required String itemKey,
    required String actionTag,
    required Future<bool> Function() action,
  }) async {
    if (_isItemBusy(itemKey)) return null;

    if (mounted) {
      setState(() {
        _busyItems[itemKey] = actionTag;
      });
    } else {
      _busyItems[itemKey] = actionTag;
    }

    try {
      return await action();
    } finally {
      if (mounted) {
        setState(() {
          _busyItems.remove(itemKey);
        });
      } else {
        _busyItems.remove(itemKey);
      }
    }
  }

  @override
  void dispose() {
    _searchUserNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        final receivedRequests = friendProvider.receivedRequests;
        final sentRequests = friendProvider.sentRequests;
        final friends = friendProvider.friends;

        return Container(
          color: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18191B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : AppTheme.slate200,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bạn bè',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.slate900,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: isDark ? Colors.white : AppTheme.slate700,
                            size: 20,
                          ),
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
                      labelColor: isDark ? Colors.white : AppTheme.slate900,
                      unselectedLabelColor:
                          isDark ? Colors.grey : AppTheme.slate500,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canShowResults = _searchedKeyword.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242526) : AppTheme.slate100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : AppTheme.slate200,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchUserNameController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchUsers(friendProvider),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.slate900,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo username (vd: sonpham123)',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.slate500,
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F2022) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.slate700 : AppTheme.slate300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.slate700 : AppTheme.slate300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _isSearchingUsers ? null : () => _searchUsers(friendProvider),
                  icon: _isSearchingUsers
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white70 : AppTheme.slate600,
                            ),
                          ),
                        )
                      : const Icon(Icons.search, size: 16),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          if (canShowResults) ...[
            const SizedBox(height: 10),
            Text(
              _searchError ?? 'Kết quả cho "$_searchedKeyword"',
              style: TextStyle(
                color: _searchError != null
                    ? Colors.redAccent
                    : (isDark ? AppTheme.slate400 : AppTheme.slate600),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_searchError == null && _searchResults.isEmpty)
              Text(
                'Không tìm thấy người dùng phù hợp.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.slate700,
                  fontSize: 12,
                ),
              )
            else if (_searchError == null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                  ),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return _buildSearchResultTile(item, friendProvider);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(UserSearchResult item, FriendProvider friendProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemKey = 'search-${item.username.toLowerCase()}';
    final normalized = item.username.toLowerCase();

    final isFriend = friendProvider.friends
        .any((entry) => entry.friend.userName.toLowerCase() == normalized);
    final hasSentRequest = friendProvider.sentRequests
        .any((entry) => entry.receiver.userName.toLowerCase() == normalized);
    final hasReceivedRequest = friendProvider.receivedRequests
        .any((entry) => entry.sender.userName.toLowerCase() == normalized);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? Colors.white12 : AppTheme.slate200,
            backgroundImage: (item.profilePictureUrl ?? '').trim().isNotEmpty
                ? NetworkImage(item.profilePictureUrl!.trim())
                : null,
            child: (item.profilePictureUrl ?? '').trim().isEmpty
                ? Icon(Icons.person, color: isDark ? Colors.white70 : AppTheme.slate600, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.slate900,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (item.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.fullName.trim().isEmpty ? 'Người dùng' : item.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFriend)
            _buildRelationBadge('Bạn bè', isDark)
          else if (hasSentRequest)
            _buildRelationBadge('Đã gửi', isDark)
          else if (hasReceivedRequest)
            _buildRelationBadge('Đã nhận', isDark)
          else
            _actionButton(
              label: 'Kết bạn',
              primary: true,
              isLoading: _isActionBusy(itemKey, 'add-friend'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      await _sendFriendRequestByUsername(
                        friendProvider: friendProvider,
                        username: item.username,
                        itemKey: itemKey,
                      );
                    },
            ),
        ],
      ),
    );
  }

  Widget _buildRelationBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF303136) : AppTheme.slate200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white70 : AppTheme.slate700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _searchUsers(FriendProvider friendProvider) async {
    final query = _searchUserNameController.text.trim().replaceFirst('@', '');

    if (query.isEmpty) {
      setState(() {
        _searchedKeyword = '';
        _searchError = null;
        _searchResults = <UserSearchResult>[];
      });
      return;
    }

    setState(() {
      _isSearchingUsers = true;
      _searchedKeyword = query;
      _searchError = null;
    });

    try {
      final results = await _userProfileService.searchUsersByUsername(
        query,
        pageSize: 15,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = <UserSearchResult>[];
        _searchError = 'Không thể tìm kiếm: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingUsers = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequestByUsername({
    required FriendProvider friendProvider,
    required String username,
    required String itemKey,
  }) async {
    final success = await _runItemAction(
      itemKey: itemKey,
      actionTag: 'add-friend',
      action: () async {
        final profile = await _userProfileService.getProfileByUsername(username);
        final targetUserId = (profile?.userId ?? '').trim();
        final myUserId = (context.read<AuthProvider>().user?.id ?? '').trim();

        if (targetUserId.isEmpty) {
          throw Exception('Không lấy được userId từ username.');
        }

        if (targetUserId == myUserId) {
          throw Exception('Bạn không thể gửi lời mời cho chính mình.');
        }

        final sent = await friendProvider.sendFriendRequest(targetUserId);
        if (!sent) {
          throw Exception(friendProvider.error ?? 'Không thể gửi lời mời kết bạn.');
        }

        await friendProvider.loadSentRequests();
        return true;
      },
    );

    if (!mounted || success == null) {
      return;
    }

    final message = success
        ? 'Đã gửi lời mời kết bạn tới @$username.'
        : (friendProvider.error ?? 'Không thể gửi lời mời kết bạn.');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (success) {
      await _searchUsers(friendProvider);
    }
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading && friendProvider.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.friends.isEmpty) {
      return Center(
        child: Text(
          'Bạn chưa có bạn bè nào.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.slate700,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.friends.length,
      itemBuilder: (context, index) {
        final entry = friendProvider.friends[index];
        final itemKey = 'friend-${entry.friend.id}';
        return _buildUserActionTile(
          user: entry.friend,
          subtitle: 'Kết bạn ${_toRelativeTime(entry.createdAt)}',
          actions: [
            _actionButton(
              label: 'Bỏ kết bạn',
              isLoading: _isActionBusy(itemKey, 'unfriend'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'unfriend',
                        action: () => friendProvider.unfriend(entry.friend.id),
                      );
                      if (success == null || !mounted) return;
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã bỏ kết bạn.' : (friendProvider.error ?? 'Không thể bỏ kết bạn.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Theo dõi',
              isLoading: _isActionBusy(itemKey, 'follow'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'follow',
                        action: () => friendProvider.follow(entry.friend.id),
                      );
                      if (success == null || !mounted) return;
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã theo dõi.' : (friendProvider.error ?? 'Không thể theo dõi.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Chặn',
              isLoading: _isActionBusy(itemKey, 'block'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'block',
                        action: () => friendProvider.blockUser(entry.friend.id),
                      );
                      if (success == null || !mounted) return;
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
      return Center(
        child: Text(
          'Không có lời mời nào.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.slate700,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.receivedRequests.length,
      itemBuilder: (context, index) {
        final request = friendProvider.receivedRequests[index];
        final itemKey = 'received-${request.id}';
        return _buildUserActionTile(
          user: request.sender,
          subtitle: 'Đã gửi ${_toRelativeTime(request.createdAt)}',
          actions: [
            _actionButton(
              label: 'Xác nhận',
              primary: true,
              isLoading: _isActionBusy(itemKey, 'accept'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'accept',
                        action: () => friendProvider.acceptRequest(request.id),
                      );
                      if (success == null || !mounted) return;
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đã chấp nhận lời mời.' : (friendProvider.error ?? 'Không thể chấp nhận lời mời.'))),
                      );
                    },
            ),
            _actionButton(
              label: 'Từ chối',
              isLoading: _isActionBusy(itemKey, 'decline'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'decline',
                        action: () => friendProvider.declineRequest(request.id),
                      );
                      if (success == null || !mounted) return;
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
      return Center(
        child: Text(
          'Bạn chưa gửi lời mời nào.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.slate700,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.sentRequests.length,
      itemBuilder: (context, index) {
        final request = friendProvider.sentRequests[index];
        final itemKey = 'sent-${request.id}';
        return _buildUserActionTile(
          user: request.receiver,
          subtitle: 'Đã gửi ${_toRelativeTime(request.createdAt)}',
          actions: [
            _actionButton(
              label: 'Hủy lời mời',
              isLoading: _isActionBusy(itemKey, 'cancel'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'cancel',
                        action: () => friendProvider.cancelRequest(request.id),
                      );
                      if (success == null || !mounted) return;
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
      return Center(
        child: Text(
          'Chưa có dữ liệu theo dõi.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.slate700,
          ),
        ),
      );
    }

    return ListView(
      children: [
        _buildSectionTitle('Người theo dõi (${followers.length})'),
        ...followers.map((entry) => _buildUserActionTile(
              user: entry.user,
              subtitle: 'Theo dõi bạn ${_toRelativeTime(entry.createdAt)}',
              actions: [
                ...[
                  _actionButton(
                    label: 'Theo dõi lại',
                    isLoading:
                        _isActionBusy('follower-${entry.user.id}', 'followback'),
                    onTap: _isItemBusy('follower-${entry.user.id}')
                        ? null
                        : () async {
                            final success = await _runItemAction(
                              itemKey: 'follower-${entry.user.id}',
                              actionTag: 'followback',
                              action: () => friendProvider.follow(entry.user.id),
                            );
                            if (success == null || !mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Đã theo dõi lại.' : (friendProvider.error ?? 'Không thể theo dõi.'))),
                            );
                          },
                  ),
                ],
              ],
            )),
        _buildSectionTitle('Bạn đang theo dõi (${following.length})'),
        ...following.map((entry) => _buildUserActionTile(
              user: entry.user,
              subtitle: 'Theo dõi ${_toRelativeTime(entry.createdAt)}',
              actions: [
                _actionButton(
                  label: 'Bỏ theo dõi',
                  isLoading:
                      _isActionBusy('following-${entry.user.id}', 'unfollow'),
                  onTap: _isItemBusy('following-${entry.user.id}')
                      ? null
                      : () async {
                          final success = await _runItemAction(
                            itemKey: 'following-${entry.user.id}',
                            actionTag: 'unfollow',
                            action: () => friendProvider.unfollow(entry.user.id),
                          );
                          if (success == null || !mounted) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.slate900,
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
      return Center(
        child: Text(
          'Bạn chưa chặn ai.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.slate700,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: friendProvider.blockedUsers.length,
      itemBuilder: (context, index) {
        final entry = friendProvider.blockedUsers[index];
        final itemKey = 'blocked-${entry.blockedUser.id}';
        return _buildUserActionTile(
          user: entry.blockedUser,
          subtitle: 'Đã chặn ${_toRelativeTime(entry.createdAt)}',
          actions: [
            _actionButton(
              label: 'Bỏ chặn',
              isLoading: _isActionBusy(itemKey, 'unblock'),
              onTap: _isItemBusy(itemKey)
                  ? null
                  : () async {
                      final success = await _runItemAction(
                        itemKey: itemKey,
                        actionTag: 'unblock',
                        action: () =>
                            friendProvider.unblockUser(entry.blockedUser.id),
                      );
                      if (success == null || !mounted) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? Colors.white12 : AppTheme.slate200,
            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
              ? Icon(
                Icons.person,
                color: isDark ? Colors.white70 : AppTheme.slate600,
                )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(user.name, user.userName, user.id),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.slate900,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey : AppTheme.slate600,
                    fontSize: 12,
                  ),
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
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;
    final foregroundColor = isDark
        ? ((isDisabled || isLoading) ? Colors.white70 : Colors.white)
        : ((isDisabled || isLoading) ? AppTheme.slate500 : AppTheme.slate900);

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFF2374E1)
              : (isDark ? const Color(0xFF303136) : AppTheme.slate200),
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              isDark ? const Color(0xFF303136) : AppTheme.slate200,
          disabledForegroundColor: isDark ? Colors.white70 : AppTheme.slate500,
          minimumSize: const Size(96, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onTap == null
            ? null
            : () async {
                await onTap();
              },
        child: isLoading
          ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white70 : AppTheme.slate600,
                  ),
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foregroundColor),
              ),
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