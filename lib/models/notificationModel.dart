import 'package:flutter/material.dart';

enum NotificationType {
  friendRequestSent,
  friendRequestAccepted,
  userFollowed,
  postLiked,
  commentCreated,
  messageReceived,
  mentioned,
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

  // Enriched on the client from the User service (actor = người gây ra thông báo)
  final String? actorName;
  final String? actorAvatarUrl;

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
    this.actorName,
    this.actorAvatarUrl,
  });

  bool get isRead => status == NotificationStatus.read;

  NotificationModel copyWith({
    NotificationStatus? status,
    DateTime? readAt,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      actorId: actorId,
      type: type,
      status: status ?? this.status,
      message: message,
      referenceId: referenceId,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      actorName: actorName ?? this.actorName,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
    );
  }

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
      case 'Mentioned':
        return NotificationType.mentioned;
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
      case NotificationType.mentioned:
        return Icons.alternate_email;
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
      case NotificationType.mentioned:
        return const Color(0xFFF59E0B);
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
