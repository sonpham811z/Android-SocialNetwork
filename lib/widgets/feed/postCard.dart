import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../comment/commentBottomSheet.dart';
import 'voicePlayer.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserAvatar;
  final bool canManage;
  final VoidCallback? onToggleLike;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserAvatar,
    this.canManage = false,
    this.onToggleLike,
    this.onEditPost,
    this.onDeletePost,
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
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(post.user.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                label: 'Share',
                color: isDark ? Colors.white : AppTheme.slate900,
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