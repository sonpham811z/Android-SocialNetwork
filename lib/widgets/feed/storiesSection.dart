import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../providers/themeProvider.dart';

class StoriesSection extends StatelessWidget {
  final VoidCallback onCreatePost;

  const StoriesSection({super.key, required this.onCreatePost});

  static const _storyGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini header: logo + actions
        Row(
          children: [
            Text(
              'Zest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: isDark ? Colors.white : AppTheme.slate900,
              ),
            ),
            const Spacer(),
            _iconButton(
              icon: Icons.search_rounded,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(width: 6),
            _iconButton(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              isDark: isDark,
              onTap: () => themeProvider.toggleTheme(),
            ),
            const SizedBox(width: 6),
            _iconButton(
              icon: Icons.add_rounded,
              isDark: isDark,
              onTap: onCreatePost,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Story circles
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _buildAddStoryItem(isDark),
              const SizedBox(width: 16),
              ...MockData.stories.map(
                (story) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStoryItem(isDark, story),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : AppTheme.slate100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppTheme.slate400 : AppTheme.slate700,
        ),
      ),
    );
  }

  Widget _buildAddStoryItem(bool isDark) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.slate800 : AppTheme.slate200,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      MockData.currentUser.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 32,
                        color: isDark ? Colors.white54 : AppTheme.slate500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.violetPrimary,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F0F10) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Của bạn',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.slate400 : AppTheme.slate600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(bool isDark, Story story) {
    final hasUnseenStory = !story.isSeen;

    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnseenStory ? _storyGradient : null,
                color: hasUnseenStory
                    ? null
                    : (isDark ? AppTheme.slate700 : AppTheme.slate300),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F0F10) : Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    story.user.avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.slate800,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.user.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    hasUnseenStory ? FontWeight.w600 : FontWeight.normal,
                color: isDark
                    ? (hasUnseenStory ? Colors.white : AppTheme.slate400)
                    : (hasUnseenStory ? AppTheme.slate900 : AppTheme.slate500),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
