import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/feedModel.dart';
import '../../providers/storyProvider.dart';
import '../../providers/userProfileProvider.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryFeedItem> feedItems;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.feedItems,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
  late AnimationController _progressController;
  Timer? _autoAdvanceTimer;
  bool _isPaused = false;

  static const _storyDuration = Duration(seconds: 5);

  StoryFeedItem get _currentGroup => widget.feedItems[_groupIndex];
  Story get _currentStory => _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _progressController = AnimationController(vsync: this, duration: _storyDuration);
    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startStory() {
    _autoAdvanceTimer?.cancel();
    _progressController.reset();

    // Mark as viewed
    final currentUserId =
        context.read<UserProfileProvider>().profile?.userId ?? '';
    if (!_currentStory.isViewedByCurrentUser) {
      context.read<StoryProvider>().markStoryViewed(
            _currentStory.id,
            currentUserId,
          );
    }

    if (!_isPaused) {
      _progressController.forward();
      _autoAdvanceTimer = Timer(_storyDuration, _next);
    }
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
    _autoAdvanceTimer?.cancel();
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    final remaining = _storyDuration * (1 - _progressController.value);
    _progressController.forward();
    _autoAdvanceTimer = Timer(remaining, _next);
  }

  void _next() {
    if (_storyIndex < _currentGroup.stories.length - 1) {
      setState(() => _storyIndex++);
    } else if (_groupIndex < widget.feedItems.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
    } else {
      Navigator.pop(context);
      return;
    }
    _isPaused = false;
    _startStory();
  }

  void _prev() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = _currentGroup.stories.length - 1;
      });
    }
    _isPaused = false;
    _startStory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _prev();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            _buildGradientOverlay(),
            _buildTopBar(),
            _buildUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final story = _currentStory;
    final url = story.mediaType == 'Video'
        ? (story.thumbnailUrl ?? story.mediaUrl ?? '')
        : (story.mediaUrl ?? '');

    if (url.isEmpty) {
      return Container(color: const Color(0xFF1A1A2E));
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 64)),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Colors.transparent, Color(0x66000000)],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final stories = _currentGroup.stories;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Column(
        children: [
          Row(
            children: List.generate(stories.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < stories.length - 1 ? 4 : 0),
                  child: _StoryProgressBar(
                    isActive: i == _storyIndex,
                    isCompleted: i < _storyIndex,
                    progressController: _progressController,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final story = _currentStory;
    final topPadding = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: topPadding + 32,
      left: 16,
      right: 56,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: story.user.avatar.isNotEmpty
                ? NetworkImage(story.user.avatar)
                : null,
            child: story.user.avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  story.createdAt,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (story.isOwner)
            _OwnerActionsButton(
              story: story,
              onDelete: () {
                context.read<StoryProvider>().deleteStory(story.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _StoryProgressBar extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final AnimationController progressController;

  const _StoryProgressBar({
    required this.isActive,
    required this.isCompleted,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: isActive
            ? AnimatedBuilder(
                animation: progressController,
                builder: (_, __) => LinearProgressIndicator(
                  value: progressController.value,
                  backgroundColor: Colors.white38,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : LinearProgressIndicator(
                value: isCompleted ? 1.0 : 0.0,
                backgroundColor: Colors.white38,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
      ),
    );
  }
}

class _OwnerActionsButton extends StatelessWidget {
  final Story story;
  final VoidCallback onDelete;

  const _OwnerActionsButton({required this.story, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1C1C1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Xóa story', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.more_vert, color: Colors.white),
    );
  }
}
