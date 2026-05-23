import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notificationModel.dart';
import '../../providers/notificationProvider.dart';

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
                  onTap: () => provider.markAsRead(items[index].id),
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
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isUnread ? Colors.white : const Color(0xFFB0B3B8),
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
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
}
