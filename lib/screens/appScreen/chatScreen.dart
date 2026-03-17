import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/chatModel.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F10),
        elevation: 1,
        shadowColor: Colors.white.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.chatRoom.avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.chatRoom.isOnline ? 'Active now' : 'Offline',
                    style: TextStyle(color: widget.chatRoom.isOnline ? Colors.green : Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: AppTheme.violetPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam, color: AppTheme.violetPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline, color: AppTheme.violetPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Khu vực hiển thị tin nhắn
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.chatRoom.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.chatRoom.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // Khu vực nhập tin nhắn
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isMe ? AppTheme.violetPrimary : AppTheme.slate800.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isMe ? 20 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 20),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10), // Trùng với màu nền của app cho tiệp màu
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: AppTheme.violetPrimary),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.camera_alt, color: AppTheme.violetPrimary),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                // Ép cứng màu nền xám đen đậm, chữ màu trắng lên là auto rõ
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2D), 
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Color.fromARGB(255, 67, 66, 66), fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true, // <-- Cực quan trọng: Giúp TextField ôm vừa khít container
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Chỉnh độ béo gầy ở đây
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.violetPrimary,
              radius: 18,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: () {
                  // TODO: Xử lý gửi tin nhắn
                  _messageController.clear();
                },
              ),
            ),
            const SizedBox(width: 8), // Cách mép phải 1 xíu cho đỡ lẹm
          ],
        ),
      ),
    );
  }
}