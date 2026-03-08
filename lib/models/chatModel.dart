import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

class ChatRoom {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final List<ChatMessage> messages;

  ChatRoom({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.messages,
  });
}

// Mock Data
class ChatMockData {
  static List<ChatRoom> chatRooms = [
    ChatRoom(
      id: '1',
      name: 'Anna Williams',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      lastMessage: 'Let\'s catch up tomorrow!',
      time: '10:30 AM',
      unreadCount: 2,
      isOnline: true,
      messages: [
        ChatMessage(text: 'Hey! How have you been?', isMe: false, time: '10:20 AM'),
        ChatMessage(text: 'I\'m doing great! Just working on a Flutter app.', isMe: true, time: '10:25 AM'),
        ChatMessage(text: 'Let\'s catch up tomorrow!', isMe: false, time: '10:30 AM'),
      ],
    ),
    ChatRoom(
      id: '2',
      name: 'David Chen',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      lastMessage: 'Got the files, thanks bro',
      time: 'Yesterday',
      isOnline: false,
      messages: [
        ChatMessage(text: 'Did you send the design files?', isMe: false, time: 'Yesterday'),
        ChatMessage(text: 'Yes, just sent them to your email.', isMe: true, time: 'Yesterday'),
        ChatMessage(text: 'Got the files, thanks bro', isMe: false, time: 'Yesterday'),
      ],
    ),
    ChatRoom(
      id: '3',
      name: 'Sarah Connor',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      lastMessage: 'Are we still on for the meeting?',
      time: 'Mon',
      unreadCount: 1,
      isOnline: true,
      messages: [
        ChatMessage(text: 'Are we still on for the meeting?', isMe: false, time: 'Mon'),
      ],
    ),
  ];
}