import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import 'package:provider/provider.dart';
import '../../providers/userProfileProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../providers/storyProvider.dart';
import '../../services/signalRService.dart';
import '../comment/commentBottomSheet.dart';
import 'voicePlayer.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserAvatar;
  final bool canManage;
  final VoidCallback? onToggleLike;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;
  final VoidCallback? onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserAvatar,
    this.canManage = false,
    this.onToggleLike,
    this.onEditPost,
    this.onDeletePost,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111214) : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.slate900;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : AppTheme.slate200,
        ),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar, Tên, Time
          _buildPostHeader(context),

          // 2. Nội dung Text (Caption)
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontSize: 15,
                  color: primaryText,
                ),
              ),
            ),

          // 3. MEDIA CONTENT (Voice hoặc Ảnh)
          if (post.audioUrl != null && post.waveform != null)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
               child: VoicePlayer(
                 waveform: post.waveform!,
                 duration: post.audioDuration ?? "0:00",
               ),
             )
          else if (post.image != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                child: Image.network(
                  post.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: isDark ? const Color(0xFF151517) : AppTheme.slate100,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 3b. ORIGINAL POST PREVIEW (nếu đây là bài share)
          if (post.originalPost != null)
            _buildOriginalPostPreview(context, post.originalPost!, isDark),

          // 4. Footer: Like, Comment, Share
          _buildPostFooter(context, isDark),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  Widget _buildPostHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(post.user.avatar),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: Row(
                    children: [
                      Text(
                        post.user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.slate900,
                        ),
                      ),
                      if (post.id.contains('voice'))
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 14, color: Colors.blue),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.timestamp} • 🌍',
                  style: TextStyle(
                    color: AppTheme.slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              color: isDark ? const Color(0xFF151517) : Colors.white,
              onSelected: (value) {
                if (value == 'edit') {
                  onEditPost?.call();
                } else if (value == 'delete') {
                  onDeletePost?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Chỉnh sửa bài viết',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.slate900,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Xóa bài viết',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.slate900,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
              color: AppTheme.slate400,
            ),
        ],
      ),
    );
  }

  Widget _buildPostFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildInteractionButton(
                context,
                icon: post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                label: '${post.likes}',
                color: post.isLikedByCurrentUser
                    ? Colors.redAccent
                    : (isDark ? Colors.white : AppTheme.slate900),
                onTap: onToggleLike,
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                context,
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount}',
                color: isDark ? Colors.white : AppTheme.slate900,
                onTap: () {
                  CommentBottomSheet.show(context, post);
                },
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                context,
                icon: Icons.share_outlined,
                label: post.sharesCount > 0 ? '${post.sharesCount}' : 'Chia sẻ',
                color: isDark ? Colors.white : AppTheme.slate900,
                onTap: () => _showShareBottomSheet(context),
              ),
            ],
          ),
          Icon(
            Icons.bookmark_border, 
            color: isDark ? AppTheme.slate400 : AppTheme.slate600
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalPostPreview(BuildContext context, Post original, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1B1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của bài gốc
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[600],
                  backgroundImage: original.user.avatar.isNotEmpty
                      ? NetworkImage(original.user.avatar)
                      : null,
                  child: original.user.avatar.isEmpty
                      ? const Icon(Icons.person, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        original.user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppTheme.slate900,
                        ),
                      ),
                      Text(
                        original.timestamp,
                        style: TextStyle(color: AppTheme.slate500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nội dung bài gốc
          if (original.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                original.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppTheme.slate700,
                  height: 1.4,
                ),
              ),
            ),
          // Ảnh bài gốc
          if (original.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(
                original.image!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ShareBottomSheet(post: post),
    );
  }



  Widget _buildInteractionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding( // Thêm padding để dễ bấm hơn
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareBottomSheet extends StatefulWidget {
  final Post post;
  const _ShareBottomSheet({required this.post});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  bool _showMessengerScreen = false;
  late TextEditingController _messengerMessageController;
  late TextEditingController _captionController;
  final Set<String> _selectedContactIds = {};

  @override
  void initState() {
    super.initState();
    _messengerMessageController = TextEditingController();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _messengerMessageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildContactRow(_MessengerContact contact, bool isDark) {
    final isSelected = _selectedContactIds.contains(contact.id);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final uncheckedBorderColor = isDark ? Colors.grey[600]! : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedContactIds.remove(contact.id);
          } else {
            _selectedContactIds.add(contact.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty)
                  ? NetworkImage(contact.avatarUrl!)
                  : null,
              backgroundColor: Colors.grey[700],
              child: (contact.avatarUrl == null || contact.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                contact.name,
                style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w500),
              ),
            ),
            // Custom Facebook Messenger style checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1877F2) : uncheckedBorderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessengerMessages({bool isGroup = false}) async {
    final textContent = _messengerMessageController.text.trim();
    final postContent = widget.post.content;
    final selectedIds = List.from(_selectedContactIds);

    // Retrieve provider and messenger instances before popping context
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(isGroup ? 'Đang gửi cho nhóm...' : 'Đang gửi tin nhắn...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final signalR = SignalRService();
      await signalR.connect();

      for (final contactId in selectedIds) {
        // 1. Open conversation
        final conv = await conversationProvider.openConversation(contactId);
        // 2. Join the conversation room via SignalR
        await signalR.joinConversation(conv.id);
        // 3. Send custom typed message if present
        if (textContent.isNotEmpty) {
          await signalR.sendMessage(conv.id, textContent);
        }
        // 4. Send shared post content
        String shareMsg = 'Đã chia sẻ bài viết của ${widget.post.user.name}:\n"$postContent"';
        if (widget.post.image != null) {
          shareMsg += '\n[Hình ảnh: ${widget.post.image}]';
        }
        await signalR.sendMessage(conv.id, shareMsg);
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isGroup 
              ? 'Đã gửi cho nhóm gồm ${selectedIds.length} người thành công' 
              : 'Đã gửi riêng cho ${selectedIds.length} người thành công'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1877F2),
        ),
      );
      
      // Clear selections after sending
      setState(() {
        _selectedContactIds.clear();
        _messengerMessageController.clear();
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Không thể gửi tin nhắn: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _showAudienceScreen = false;
  String _selectedAudience = 'Công khai';

  IconData _getAudienceIcon(String audience) {
    switch (audience) {
      case 'Công khai':
        return Icons.public;
      case 'Bạn bè':
        return Icons.people_outline_rounded;
      case 'Chỉ mình tôi':
        return Icons.lock_outline_rounded;
      default:
        return Icons.public;
    }
  }

  Widget _buildDropdownSelector(IconData icon, String text, VoidCallback onTap, bool isDark) {
    final dropdownBgColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: dropdownBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 12),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: iconColor, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    final isSelected = value == _selectedAudience;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.grey[500] : const Color(0xFF64748B);
    final borderColor = isSelected ? const Color(0xFF1877F2) : (isDark ? Colors.grey[600]! : const Color(0xFFCBD5E1));

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: subColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 6.5 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final profileProvider = context.watch<UserProfileProvider>();
    final currentUserName = profileProvider.profile?.displayName ?? 'Quang Thanh Trương';
    final currentUserAvatar = profileProvider.profile?.avatar;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1F22) : Colors.white;
    final blockColor = isDark ? const Color(0xFF2B2D31) : const Color(0xFFF1F5F9);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.grey[400] : const Color(0xFF475569);
    final subtitleColor = isDark ? Colors.grey[500] : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.grey[800]! : const Color(0xFFCBD5E1);

    if (_showAudienceScreen) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
                    onPressed: () {
                      setState(() => _showAudienceScreen = false);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ai có thể xem bài viết của bạn?',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bài viết của bạn sẽ hiển thị trên Bảng feed, trang cá nhân và trong kết quả tìm kiếm.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options list
            _buildAudienceOption(
              value: 'Công khai',
              icon: Icons.public,
              title: 'Công khai',
              subtitle: 'Tất cả mọi người đều có thể xem',
              onChanged: (val) => setState(() => _selectedAudience = val),
              isDark: isDark,
            ),
            _buildAudienceOption(
              value: 'Bạn bè',
              icon: Icons.people_outline_rounded,
              title: 'Bạn bè',
              subtitle: 'Chỉ bạn bè của bạn',
              onChanged: (val) => setState(() => _selectedAudience = val),
              isDark: isDark,
            ),
            _buildAudienceOption(
              value: 'Chỉ mình tôi',
              icon: Icons.lock_outline_rounded,
              title: 'Chỉ mình tôi',
              subtitle: 'Chỉ mình bạn thấy',
              onChanged: (val) => setState(() => _selectedAudience = val),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showAudienceScreen = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showMessengerScreen) {
      final conversationProvider = context.watch<ConversationProvider>();
      final items = conversationProvider.buildList();
      final List<_MessengerContact> contacts = [];
      if (items.isNotEmpty) {
        for (final item in items) {
          contacts.add(_MessengerContact(
            id: item.userId,
            name: item.name,
            avatarUrl: item.avatarUrl,
            conversationId: item.conversationId,
          ));
        }
      } else {
        final List<Map<String, dynamic>> mockFriends = [
          {'id': 'u1', 'name': 'Trương Thanh Quang'},
          {'id': 'u2', 'name': 'Lê Gia Quyền'},
          {'id': 'u3', 'name': 'Thuy Linh'},
          {'id': 'u4', 'name': 'Nhật Minh'},
        ];
        for (final f in mockFriends) {
          contacts.add(_MessengerContact(
            id: f['id']!,
            name: f['name']!,
          ));
        }
      }

      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
                    onPressed: () {
                      setState(() => _showMessengerScreen = false);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gửi qua Messenger',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),

            // Message Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messengerMessageController,
                style: TextStyle(color: primaryTextColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Viết tin nhắn...',
                  hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1877F2)),
                  ),
                  filled: true,
                  fillColor: blockColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: dividerColor, height: 1),

            // Friends List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length,
                itemBuilder: (context, idx) {
                  return _buildContactRow(contacts[idx], isDark);
                },
              ),
            ),

            const SizedBox(height: 8),
            // Send Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedContactIds.isEmpty ? null : _sendMessengerMessages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: Colors.white,
                    disabledForegroundColor: isDark ? Colors.white38 : Colors.grey[500],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Gửi ${_selectedContactIds.isNotEmpty ? "(${_selectedContactIds.length})" : ""}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mock friends for Messenger section
    final List<Map<String, dynamic>> messengerFriends = [
      {'id': 'u1', 'name': 'Trương Thanh Qua...', 'fullName': 'Trương Thanh Quang', 'color': Colors.orangeAccent},
      {'id': 'u2', 'name': 'Lê Gia Quyền', 'fullName': 'Lê Gia Quyền', 'color': Colors.purpleAccent},
      {'id': 'u3', 'name': 'Thuy Linh', 'fullName': 'Thuy Linh', 'color': Colors.pinkAccent},
      {'id': 'u4', 'name': 'Nhật Minh', 'fullName': 'Nhật Minh', 'color': Colors.teal},
    ];

    if (_selectedContactIds.isNotEmpty) {
      // Image 2 Layout (Messenger Share Mode)
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPadding + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gửi bằng Messenger',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryTextColor, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedContactIds.clear();
                          _messengerMessageController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal scroll row of friends with checkmark overlays
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messengerFriends.map((f) {
                    final friendId = f['id']!;
                    final isSelected = _selectedContactIds.contains(friendId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContactIds.remove(friendId);
                            } else {
                              _selectedContactIds.add(friendId);
                            }
                          });
                        },
                        child: SizedBox(
                          width: 70,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: f['color'],
                                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(1.5),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1877F2),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                f['name'],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? primaryTextColor : secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Soạn tin nhắn... TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messengerMessageController,
                  style: TextStyle(color: primaryTextColor, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Soạn tin nhắn...',
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 14.5),
                    filled: true,
                    fillColor: blockColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF1877F2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Side-by-side buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _sendMessengerMessages(isGroup: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blockColor,
                            foregroundColor: primaryTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Gửi cho nhóm',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _sendMessengerMessages(isGroup: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Gửi riêng',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Image 1 Layout (Default Share Layout)
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPadding + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top notice text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: subtitleColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bài chia sẻ sẽ xuất hiện trên bảng feed của bạn.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Text input & post options block
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: (currentUserAvatar != null && currentUserAvatar.isNotEmpty)
                            ? NetworkImage(currentUserAvatar)
                            : null,
                        backgroundColor: Colors.grey[600],
                        child: (currentUserAvatar == null || currentUserAvatar.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUserName,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDropdownSelector(
                              _getAudienceIcon(_selectedAudience),
                              _selectedAudience,
                              () {
                                setState(() => _showAudienceScreen = true);
                              },
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionController,
                    style: TextStyle(color: primaryTextColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Bạn nói gì đi...',
                      hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sentiment_satisfied_alt_outlined, color: secondaryTextColor, size: 24),
                          const SizedBox(width: 14),
                          Icon(Icons.person_add_alt_1_outlined, color: secondaryTextColor, size: 24),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          String apiVisibility = 'Public';
                          if (_selectedAudience == 'Bạn bè') {
                            apiVisibility = 'Friends';
                          } else if (_selectedAudience == 'Chỉ mình tôi') {
                            apiVisibility = 'Private';
                          }

                          final caption = _captionController.text.trim();
                          final postProvider = Provider.of<PostProvider>(context, listen: false);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đang chia sẻ bài viết...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          postProvider.sharePost(
                            widget.post.id,
                            content: caption,
                            visibility: apiVisibility,
                          ).then((success) {
                            if (success) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Đã chia sẻ thành công (${_selectedAudience})'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1877F2),
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Chia sẻ thất bại. Vui lòng thử lại.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Chia sẻ ngay',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section "Gửi bằng Messenger"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Gửi bằng Messenger',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: messengerFriends.map((f) {
                  final friendId = f['id']!;
                  final isSelected = _selectedContactIds.contains(friendId);
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedContactIds.remove(friendId);
                          } else {
                            _selectedContactIds.add(friendId);
                          }
                        });
                      },
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: f['color'],
                                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: backgroundColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1877F2),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              f['name'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Section "Chia sẻ lên"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Chia sẻ lên',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShareOption(
                    context,
                    icon: Icons.add_to_photos_outlined,
                    label: 'Tin của bạn',
                    onTap: () {
                      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
                      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final currentUser = userProfileProvider.profile;
                      Navigator.pop(context);
                      if (currentUser != null) {
                        final userProfile = UserProfile(
                          id: currentUser.id,
                          name: currentUser.displayName,
                          handle: currentUser.username != null ? '@${currentUser.username}' : '@unknown',
                          avatar: currentUser.avatar ?? '',
                        );
                        storyProvider.sharePostToStoryLocally(userProfile, widget.post);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm bài viết này vào tin của bạn!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF1877F2),
                          ),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Không thể chia sẻ lên tin. Vui lòng đăng nhập lại.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    isDark: isDark,
                  ),
                  _buildMessengerShareOption(
                    context,
                    onTap: () {
                      setState(() {
                        _showMessengerScreen = true;
                      });
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final blockBgColor = isDark ? const Color(0xFF2B2D31) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: blockBgColor,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessengerShareOption(
    BuildContext context, {
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF475569);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.messenger_rounded, color: Color(0xFF1877F2), size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              'Messenger',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessengerContact {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? conversationId;
  _MessengerContact({required this.id, required this.name, this.avatarUrl, this.conversationId});
}