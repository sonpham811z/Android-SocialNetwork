import '../utils/json_helpers.dart';

// ── Server API models ─────────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final int type; // 0 = OneToOne, 1 = Group
  final List<String> members;
  final String? groupName;
  final LastMessageModel? lastMessage;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.members,
    this.groupName,
    this.lastMessage,
    required this.updatedAt,
  });

  bool get isOneToOne => type == 0;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = asJsonList(json['members'] ?? json['Members']) ?? [];
    return ConversationModel(
      id: asText(json['id'] ?? json['Id']),
      type: asInt(json['type'] ?? json['Type']),
      members: rawMembers.map((e) => asText(e)).toList(),
      groupName: (json['groupName'] ?? json['GroupName'])?.toString(),
      lastMessage: () {
        final raw = asJsonMap(json['lastMessage'] ?? json['LastMessage']);
        return raw != null ? LastMessageModel.fromJson(raw) : null;
      }(),
      updatedAt: asDateTime(json['updatedAt'] ?? json['UpdatedAt']) ?? DateTime.now(),
    );
  }
}

class LastMessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;

  const LastMessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      messageId: asText(json['messageId'] ?? json['MessageId']),
      senderId: asText(json['senderId'] ?? json['SenderId']),
      content: asText(json['content'] ?? json['Content']),
      timestamp: asDateTime(json['timestamp'] ?? json['Timestamp']) ?? DateTime.now(),
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final int type; // 0=Text, 1=Image, 2=File, 3=System
  final DateTime timestamp;
  final List<ReadReceiptModel> readBy;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.readBy,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawReadBy = asJsonList(json['readBy'] ?? json['ReadBy']) ?? [];
    return MessageModel(
      id: asText(json['id'] ?? json['Id']),
      conversationId: asText(json['conversationId'] ?? json['ConversationId']),
      senderId: asText(json['senderId'] ?? json['SenderId']),
      content: asText(json['content'] ?? json['Content']),
      type: asInt(json['type'] ?? json['Type']),
      timestamp: asDateTime(json['timestamp'] ?? json['Timestamp']) ?? DateTime.now(),
      readBy: rawReadBy
          .map((e) => ReadReceiptModel.fromJson(asJsonMap(e) ?? {}))
          .toList(),
    );
  }

  bool isReadBy(String userId) => readBy.any((r) => r.userId == userId);
}

class ReadReceiptModel {
  final String userId;
  final DateTime readAt;

  const ReadReceiptModel({required this.userId, required this.readAt});

  factory ReadReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReadReceiptModel(
      userId: asText(json['userId'] ?? json['UserId']),
      readAt: asDateTime(json['readAt'] ?? json['ReadAt']) ?? DateTime.now(),
    );
  }
}

class MessagePageResult {
  final List<MessageModel> messages;
  final String? nextCursor;
  final bool hasMore;

  const MessagePageResult({
    required this.messages,
    this.nextCursor,
    required this.hasMore,
  });

  factory MessagePageResult.fromJson(Map<String, dynamic> json) {
    final rawMessages = asJsonList(json['messages'] ?? json['Messages']) ?? [];
    return MessagePageResult(
      messages: rawMessages
          .map((e) => MessageModel.fromJson(asJsonMap(e) ?? {}))
          .toList(),
      nextCursor: (json['nextCursor'] ?? json['NextCursor'])?.toString(),
      hasMore: asBool(json['hasMore'] ?? json['HasMore']),
    );
  }
}

// ── UI model for the conversation list ───────────────────────────────────────

class ConversationListItem {
  final String? conversationId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageTime;
  final bool isLastMessageByMe;

  const ConversationListItem({
    this.conversationId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageTime,
    this.isLastMessageByMe = false,
  });

  bool get hasConversation => conversationId != null;
}

// ── Time formatting helper ────────────────────────────────────────────────────

String formatMessageTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:$m $period';
  }
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }
  return '${time.month}/${time.day}';
}
