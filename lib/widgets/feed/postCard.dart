import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import 'voicePlayer.dart'; 

class PostCard extends StatelessWidget {
  final Post post;
  final bool isExpanded; // Trạng thái đóng mở comment
  final VoidCallback onToggleComments;

  const PostCard({
    super.key,
    required this.post,
    this.isExpanded = false,
    required this.onToggleComments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                  color: isDark ? Colors.white : AppTheme.slate900,
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
                      color: AppTheme.slate200,
                      child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey)),
                    );
                  },
                ),
              ),
            ),

          // 4. Footer: Like, Comment, Share
          _buildPostFooter(context, isDark),

          // 5. [FIX] KHU VỰC COMMENT (Chỉ hiện khi isExpanded == true)
          if (isExpanded) 
            _buildCommentsSection(context, isDark),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  Widget _buildPostHeader(BuildContext context) {
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
                icon: Icons.favorite_border,
                label: '${post.likes}',
                color: isDark ? Colors.white : AppTheme.slate900,
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                context,
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount}',
                color: isDark ? Colors.white : AppTheme.slate900,
                onTap: onToggleComments, // Bấm vào đây để mở comment
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

  // [NEW] Widget hiển thị danh sách comment và ô nhập liệu
  Widget _buildCommentsSection(BuildContext context, bool isDark) {
    final comments = post.commentsList ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : AppTheme.slate100.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.slate200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Danh sách comment
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Chưa có bình luận nào. Hãy là người đầu tiên!",
                style: TextStyle(color: AppTheme.slate500, fontSize: 13),
              ),
            )
          else
            ...comments.map((comment) => _buildSingleComment(context, comment, isDark)),

          const SizedBox(height: 12),

          // Ô nhập comment
          Row(
            children: [
              // Avatar người dùng hiện tại (Lấy tạm user của post làm demo)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(MockData.currentUser.avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2D) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.transparent : AppTheme.slate300,
                    ),
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black, 
                      fontSize: 14
                    ),
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      hintStyle: TextStyle(
                        color: AppTheme.slate500, 
                        fontSize: 14
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: Icon(Icons.send, size: 18, color: AppTheme.violetPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [NEW] Widget hiển thị 1 dòng comment
  Widget _buildSingleComment(BuildContext context, Comment comment, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment.user.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2D) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Text(
                        comment.timestamp,
                        style: TextStyle(color: AppTheme.slate500, fontSize: 11),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Thích',
                        style: TextStyle(color: AppTheme.slate500, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Trả lời',
                        style: TextStyle(color: AppTheme.slate500, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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