import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notificationModel.dart';
import '../../providers/notificationProvider.dart';
import 'userProfileScreen.dart';
import 'postDetailScreen.dart';
import 'chatScreen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadNotifications();
    }
  }

  /// Đánh dấu đã đọc + điều hướng tới đúng nơi tuỳ loại thông báo.
  void _handleTap(NotificationModel n) {
    context.read<NotificationProvider>().markAsRead(n.id);

    switch (n.type) {
      // Kết bạn / theo dõi → mở profile của actor
      case NotificationType.friendRequestSent:
      case NotificationType.friendRequestAccepted:
      case NotificationType.userFollowed:
        if (n.actorId.isNotEmpty) {
          UserProfileScreen.open(
            context,
            n.actorId,
            displayName: n.actorName,
            avatarUrl: n.actorAvatarUrl,
          );
        }
        break;

      // Like / comment → mở bài viết liên quan
      case NotificationType.postLiked:
      case NotificationType.commentCreated:
        if (n.referenceId != null && n.referenceId!.isNotEmpty) {
          PostDetailScreen.open(context, n.referenceId!);
        }
        break;

      // Tin nhắn → mở hội thoại với người gửi
      case NotificationType.messageReceived:
        if (n.actorId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                friendId: n.actorId,
                friendName: n.actorName ?? 'Tin nhắn',
                friendAvatarUrl: n.actorAvatarUrl,
              ),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF242526),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.grey[800]),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: provider.isLoading ? null : provider.markAllAsRead,
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(color: Color(0xFF2D88FF), fontSize: 14),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D88FF)),
            );
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadNotifications(refresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      color: Colors.grey, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(color: Color(0xFFB0B3B8), fontSize: 15),
                  ),
                ],
              ),
            );
          }

          final items = provider.notifications;
          return RefreshIndicator(
            color: const Color(0xFF2D88FF),
            backgroundColor: const Color(0xFF242526),
            onRefresh: () => provider.loadNotifications(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: items.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D88FF),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return _NotificationTile(
                  notification: items[index],
                  onTap: () => _handleTap(items[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? const Color(0xFF2D88FF).withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar của actor + badge loại thông báo
            _buildAvatar(),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color:
                            isUnread ? Colors.white : const Color(0xFFB0B3B8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        if (notification.actorName != null) ...[
                          TextSpan(
                            text: notification.actorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isUnread
                                  ? Colors.white
                                  : const Color(0xFFE4E6EB),
                            ),
                          ),
                          const TextSpan(text: ' '),
                        ],
                        TextSpan(
                          text: notification.message,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      color: isUnread
                          ? const Color(0xFF2D88FF)
                          : const Color(0xFFB0B3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D88FF),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final url = notification.actorAvatarUrl;
    final hasAvatar = url != null && url.isNotEmpty;
    final name = notification.actorName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF3A3B3C),
            backgroundImage: hasAvatar ? NetworkImage(url) : null,
            child: hasAvatar
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
          // Badge loại thông báo
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: notification.iconColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF18191A), width: 2),
              ),
              child: Icon(
                notification.icon,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
