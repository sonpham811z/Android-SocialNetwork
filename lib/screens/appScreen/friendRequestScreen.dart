import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friendModel.dart';
import '../../providers/friendProvider.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final friendProvider = context.read<FriendProvider>();
      await friendProvider.loadReceivedRequests();
      await friendProvider.loadSentRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        final receivedRequests = friendProvider.receivedRequests;
        final sentRequests = friendProvider.sentRequests;

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
                          'Lời mời',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 20),
                          onPressed: () async {
                            await friendProvider.loadReceivedRequests();
                            await friendProvider.loadSentRequests();
                          },
                        ),
                      ],
                    ),
                    _buildOptionTile(),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF2374E1),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Đã nhận (${receivedRequests.length})'),
                        Tab(text: 'Đã gửi (${sentRequests.length})'),
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
                    _buildReceivedTab(friendProvider),
                    _buildSentTab(friendProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242526),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(Icons.groups, color: Colors.white70, size: 20),
        title: Text(
          'Lời mời kết bạn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Quản lý lời mời đã nhận và đã gửi',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
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
        return _buildReceivedRequestCard(friendProvider, request);
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
        return _buildSentRequestCard(friendProvider, request);
      },
    );
  }

  Widget _buildReceivedRequestCard(
    FriendProvider friendProvider,
    FriendRequestModel request,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white12,
            backgroundImage: (request.sender.avatarUrl != null &&
                    request.sender.avatarUrl!.isNotEmpty)
                ? NetworkImage(request.sender.avatarUrl!)
                : null,
            child: (request.sender.avatarUrl == null ||
                    request.sender.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _displayName(
                          request.sender.name,
                          request.sender.userName,
                          request.sender.id,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _toRelativeTime(request.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2374E1),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            disabledBackgroundColor: const Color(0xFF2A5EA8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: friendProvider.isActionLoading
                              ? null
                              : () async {
                                  final success =
                                      await friendProvider.acceptRequest(
                                    request.id,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã chấp nhận lời mời.'),
                                      ),
                                    );
                                  }
                                },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Xác nhận',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: friendProvider.isActionLoading
                              ? null
                              : () async {
                                  final success =
                                      await friendProvider.declineRequest(
                                    request.id,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã từ chối lời mời.'),
                                      ),
                                    );
                                  }
                                },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Xóa',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
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

  Widget _buildSentRequestCard(
    FriendProvider friendProvider,
    FriendRequestModel request,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white12,
            backgroundImage: (request.receiver.avatarUrl != null &&
                    request.receiver.avatarUrl!.isNotEmpty)
                ? NetworkImage(request.receiver.avatarUrl!)
                : null,
            child: (request.receiver.avatarUrl == null ||
                    request.receiver.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(
                    request.receiver.name,
                    request.receiver.userName,
                    request.receiver.id,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã gửi ${_toRelativeTime(request.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 120,
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: friendProvider.isActionLoading
                        ? null
                        : () async {
                            final success = await friendProvider.cancelRequest(
                              request.id,
                            );
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã hủy lời mời.'),
                                ),
                              );
                            }
                          },
                    child: const Text('Hủy lời mời'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
