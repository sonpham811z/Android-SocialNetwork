import 'package:flutter/material.dart';

enum NotificationType {
  friendRequestSent,
  friendRequestAccepted,
  userFollowed,
  postLiked,
  commentCreated,
  messageReceived,
}

enum NotificationStatus { unread, read }

class NotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final NotificationType type;
  final NotificationStatus status;
  final String message;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.type,
    required this.status,
    required this.message,
    this.referenceId,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => status == NotificationStatus.read;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      actorId: json['actorId'] as String,
      type: _parseType(json['type'] as String? ?? ''),
      status: (json['status'] as String? ?? '') == 'Read'
          ? NotificationStatus.read
          : NotificationStatus.unread,
      message: json['message'] as String? ?? '',
      referenceId: json['referenceId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'FriendRequestSent':
        return NotificationType.friendRequestSent;
      case 'FriendRequestAccepted':
        return NotificationType.friendRequestAccepted;
      case 'UserFollowed':
        return NotificationType.userFollowed;
      case 'PostLiked':
        return NotificationType.postLiked;
      case 'CommentCreated':
        return NotificationType.commentCreated;
      case 'MessageReceived':
        return NotificationType.messageReceived;
      default:
        return NotificationType.messageReceived;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.friendRequestSent:
      case NotificationType.friendRequestAccepted:
        return Icons.person_add_alt_1;
      case NotificationType.userFollowed:
        return Icons.person_add;
      case NotificationType.postLiked:
        return Icons.favorite;
      case NotificationType.commentCreated:
        return Icons.comment;
      case NotificationType.messageReceived:
        return Icons.chat_bubble;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.friendRequestSent:
      case NotificationType.friendRequestAccepted:
      case NotificationType.userFollowed:
        return const Color(0xFF2D88FF);
      case NotificationType.postLiked:
        return const Color(0xFFEF4444);
      case NotificationType.commentCreated:
        return const Color(0xFF10B981);
      case NotificationType.messageReceived:
        return const Color(0xFF8B5CF6);
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần';
    return '${(diff.inDays / 30).floor()} tháng';
  }
}
