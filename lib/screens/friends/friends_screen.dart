import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friendModel.dart';
import '../../providers/friendProvider.dart';
import '../appScreen/userProfileScreen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadMyFriends();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final provider = context.read<FriendProvider>();
    switch (_tabController.index) {
      case 0:
        provider.loadMyFriends();
        break;
      case 1:
        provider.loadReceivedRequests();
        break;
      case 2:
        provider.loadSentRequests();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      appBar: AppBar(
        title: const Text(
          'Bạn bè',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF242526),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D88FF),
          unselectedLabelColor: const Color(0xFFB0B3B8),
          indicatorColor: const Color(0xFF2D88FF),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Bạn bè'),
            Tab(text: 'Lời mời'),
            Tab(text: 'Đã gửi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsTab(),
          _ReceivedRequestsTab(),
          _SentRequestsTab(),
        ],
      ),
    );
  }
}

// ── Tab 0: Friends ────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.friends.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D88FF)),
          );
        }

        if (provider.error != null && provider.friends.isEmpty) {
          return _ErrorView(
            message: provider.error!,
            onRetry: () => provider.loadMyFriends(),
          );
        }

        if (provider.friends.isEmpty) {
          return const _EmptyView(
            icon: Icons.people_outline,
            message: 'Chưa có bạn bè nào',
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF2D88FF),
          backgroundColor: const Color(0xFF242526),
          onRefresh: () => provider.loadMyFriends(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: provider.friends.length,
            itemBuilder: (context, index) {
              final friendship = provider.friends[index];
              return _FriendTile(
                friendship: friendship,
                onUnfriend: () async {
                  final ok = await provider.unfriend(friendship.friend.id);
                  if (!context.mounted) return;
                  _showSnack(
                    context,
                    ok ? 'Đã hủy kết bạn' : (provider.error ?? 'Lỗi'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendshipModel friendship;
  final VoidCallback onUnfriend;

  const _FriendTile({required this.friendship, required this.onUnfriend});

  @override
  Widget build(BuildContext context) {
    final user = friendship.friend;
    return ListTile(
      onTap: () => UserProfileScreen.open(
        context,
        user.id,
        displayName: user.name,
        avatarUrl: user.avatarUrl,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Avatar(url: user.avatarUrl, name: user.name),
      title: Text(
        user.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        '@${user.userName}',
        style: const TextStyle(color: Color(0xFFB0B3B8), fontSize: 13),
      ),
      trailing: TextButton(
        onPressed: onUnfriend,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB0B3B8),
          backgroundColor: const Color(0xFF3A3B3C),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Hủy kết bạn', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ── Tab 1: Received Requests ──────────────────────────────────────────────────

class _ReceivedRequestsTab extends StatelessWidget {
  const _ReceivedRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.receivedRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D88FF)),
          );
        }

        if (provider.error != null && provider.receivedRequests.isEmpty) {
          return _ErrorView(
            message: provider.error!,
            onRetry: () => provider.loadReceivedRequests(),
          );
        }

        if (provider.receivedRequests.isEmpty) {
          return const _EmptyView(
            icon: Icons.person_add_outlined,
            message: 'Không có lời mời kết bạn nào',
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF2D88FF),
          backgroundColor: const Color(0xFF242526),
          onRefresh: () => provider.loadReceivedRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: provider.receivedRequests.length,
            itemBuilder: (context, index) {
              final request = provider.receivedRequests[index];
              return _ReceivedRequestTile(
                request: request,
                isActionLoading: provider.isActionLoading,
                onAccept: () async {
                  final ok = await provider.acceptRequest(request.id);
                  if (!context.mounted) return;
                  _showSnack(
                    context,
                    ok ? 'Đã chấp nhận lời mời' : (provider.error ?? 'Lỗi'),
                  );
                },
                onDecline: () async {
                  final ok = await provider.declineRequest(request.id);
                  if (!context.mounted) return;
                  _showSnack(
                    context,
                    ok ? 'Đã từ chối lời mời' : (provider.error ?? 'Lỗi'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ReceivedRequestTile extends StatelessWidget {
  final FriendRequestModel request;
  final bool isActionLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ReceivedRequestTile({
    required this.request,
    required this.isActionLoading,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final user = request.sender;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => UserProfileScreen.open(
              context,
              user.id,
              displayName: user.name,
              avatarUrl: user.avatarUrl,
            ),
            child: _Avatar(url: user.avatarUrl, name: user.name),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => UserProfileScreen.open(
                    context,
                    user.id,
                    displayName: user.name,
                    avatarUrl: user.avatarUrl,
                  ),
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Xác nhận',
                        isPrimary: true,
                        isLoading: isActionLoading,
                        onPressed: onAccept,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: 'Xóa',
                        isPrimary: false,
                        isLoading: isActionLoading,
                        onPressed: onDecline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Sent Requests ──────────────────────────────────────────────────────

class _SentRequestsTab extends StatelessWidget {
  const _SentRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.sentRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D88FF)),
          );
        }

        if (provider.error != null && provider.sentRequests.isEmpty) {
          return _ErrorView(
            message: provider.error!,
            onRetry: () => provider.loadSentRequests(),
          );
        }

        if (provider.sentRequests.isEmpty) {
          return const _EmptyView(
            icon: Icons.send_outlined,
            message: 'Chưa gửi lời mời kết bạn nào',
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF2D88FF),
          backgroundColor: const Color(0xFF242526),
          onRefresh: () => provider.loadSentRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: provider.sentRequests.length,
            itemBuilder: (context, index) {
              final request = provider.sentRequests[index];
              return _SentRequestTile(
                request: request,
                isActionLoading: provider.isActionLoading,
                onCancel: () async {
                  final ok = await provider.cancelRequest(request.id);
                  if (!context.mounted) return;
                  _showSnack(
                    context,
                    ok ? 'Đã hủy lời mời' : (provider.error ?? 'Lỗi'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  final FriendRequestModel request;
  final bool isActionLoading;
  final VoidCallback onCancel;

  const _SentRequestTile({
    required this.request,
    required this.isActionLoading,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final user = request.receiver;
    return ListTile(
      onTap: () => UserProfileScreen.open(
        context,
        user.id,
        displayName: user.name,
        avatarUrl: user.avatarUrl,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Avatar(url: user.avatarUrl, name: user.name),
      title: Text(
        user.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: const Text(
        'Đang chờ xác nhận...',
        style: TextStyle(color: Color(0xFFB0B3B8), fontSize: 13),
      ),
      trailing: TextButton(
        onPressed: isActionLoading ? null : onCancel,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB0B3B8),
          backgroundColor: const Color(0xFF3A3B3C),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Hủy lời mời', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(url!),
        backgroundColor: const Color(0xFF3A3B3C),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF3A3B3C),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? const Color(0xFF2D88FF) : const Color(0xFF3A3B3C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey, size: 64),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFB0B3B8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
