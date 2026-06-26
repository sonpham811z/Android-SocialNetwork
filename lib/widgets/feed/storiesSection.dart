import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../providers/storyProvider.dart';
import '../../providers/themeProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../../screens/appScreen/searchUserScreen.dart';
import '../../screens/story/createStoryScreen.dart';
import '../../screens/story/storyViewerScreen.dart';

class StoriesSection extends StatefulWidget {
  final VoidCallback onCreatePost;

  const StoriesSection({super.key, required this.onCreatePost});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryProvider>().loadStoryFeed();
    });
  }

  static const _storyGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
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
            _iconButton(icon: Icons.search_rounded, isDark: isDark, onTap: () => SearchUserScreen.open(context)),
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
              onTap: widget.onCreatePost,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 98,
          child: Consumer<StoryProvider>(
            builder: (context, storyProvider, _) {
              final feedItems = storyProvider.feedItems;
              final currentUserId =
                  context.read<UserProfileProvider>().profile?.userId ?? '';

              return ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  _buildAddStoryItem(isDark, currentUserId, context),
                  const SizedBox(width: 16),
                  if (storyProvider.isLoading && feedItems.isEmpty)
                    ..._buildSkeletons(isDark)
                  else
                    ...feedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildStoryGroupItem(isDark, item, feedItems, context),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSkeletons(bool isDark) {
    return List.generate(
      4,
      (_) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _StorySkeletonItem(isDark: isDark),
      ),
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

  Widget _buildAddStoryItem(bool isDark, String currentUserId, BuildContext context) {
    final profile = context.read<UserProfileProvider>().profile;
    final avatarUrl = profile?.profilePictureUrl ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
        );
      },
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
                    child: avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person,
                              size: 32,
                              color: isDark ? Colors.white54 : AppTheme.slate500,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 32,
                            color: isDark ? Colors.white54 : AppTheme.slate500,
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

  Widget _buildStoryGroupItem(
    bool isDark,
    StoryFeedItem item,
    List<StoryFeedItem> allItems,
    BuildContext context,
  ) {
    final hasUnseen = item.hasUnseenStories;

    return GestureDetector(
      onTap: () {
        final startIndex = allItems.indexOf(item);
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => StoryViewerScreen(
              feedItems: allItems,
              initialGroupIndex: startIndex,
            ),
          ),
        );
      },
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
                gradient: hasUnseen ? _storyGradient : null,
                color: hasUnseen
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
                  child: CachedNetworkImage(
                    imageUrl: item.user.avatar,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.slate800,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.user.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasUnseen ? FontWeight.w600 : FontWeight.normal,
                color: isDark
                    ? (hasUnseen ? Colors.white : AppTheme.slate400)
                    : (hasUnseen ? AppTheme.slate900 : AppTheme.slate500),
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

class _StorySkeletonItem extends StatelessWidget {
  final bool isDark;
  const _StorySkeletonItem({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.slate800 : AppTheme.slate200;
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 6),
          Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
