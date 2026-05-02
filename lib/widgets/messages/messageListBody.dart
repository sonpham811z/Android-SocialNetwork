import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chatModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../screens/appScreen/chatScreen.dart';

class MessageListBody extends StatefulWidget {
  const MessageListBody({super.key});

  @override
  State<MessageListBody> createState() => _MessageListBodyState();
}

class _MessageListBodyState extends State<MessageListBody> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback so context is ready for Provider.of
    WidgetsBinding.instance.addPostFrameCallback((_) => _initIfNeeded());
  }

  void _initIfNeeded() {
    final auth = context.read<AuthProvider>();
    final conv = context.read<ConversationProvider>();
    if (!conv.isInitialized && auth.user != null) {
      conv.initialize(auth.user!.id);
    }
  }

  void _openChat(BuildContext context, ConversationListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: item.userId,
          friendName: item.name,
          friendAvatarUrl: item.avatarUrl,
          conversationId: item.conversationId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (provider.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.violetPrimary,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit_square, color: Colors.white),
                      onPressed: () {},
                    ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.slate800.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Error banner
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),

            // Conversation + friend list
            Expanded(
              child: _buildList(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ConversationProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.violetPrimary),
      );
    }

    final items = provider.buildList();

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'No friends yet.\nAdd friends to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildTile(context, items[index]),
    );
  }

  Widget _buildTile(BuildContext context, ConversationListItem item) {
    final lastMsgText = item.lastMessagePreview != null
        ? (item.isLastMessageByMe
            ? 'You: ${item.lastMessagePreview}'
            : item.lastMessagePreview!)
        : 'Tap to start chatting';

    final timeText = item.lastMessageTime != null
        ? formatMessageTime(item.lastMessageTime!)
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _openChat(context, item),
      leading: _buildAvatar(item),
      title: Text(
        item.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        lastMsgText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: item.hasConversation && !item.isLastMessageByMe
              ? Colors.white70
              : Colors.grey,
          fontWeight: item.hasConversation && !item.isLastMessageByMe
              ? FontWeight.w500
              : FontWeight.normal,
        ),
      ),
      trailing: timeText.isNotEmpty
          ? Text(
              timeText,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            )
          : null,
    );
  }

  Widget _buildAvatar(ConversationListItem item) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.slate800,
            backgroundImage: item.avatarUrl != null
                ? NetworkImage(item.avatarUrl!)
                : null,
            child: item.avatarUrl == null
                ? Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : null,
          ),
          // Unread indicator dot — shown when conversation has messages not by me
          if (item.hasConversation && item.lastMessagePreview != null && !item.isLastMessageByMe)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.violetPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F0F10), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
