import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/feedModel.dart';
import '../../services/postService.dart';
import '../../widgets/comment/commentBottomSheet.dart';
import 'userProfileScreen.dart';

/// Feed video dọc kiểu Reels: vuốt lên/xuống, video tự phát & lặp.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReelsScreen()),
    );
  }

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _postService = PostService();
  final _pageController = PageController();

  final List<Post> _reels = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _postService.getReels(page: 1, pageSize: 10);
      if (!mounted) return;
      setState(() {
        _reels
          ..clear()
          ..addAll(result.posts);
        _page = 1;
        _hasMore = result.posts.length >= 10;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được Reels.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final next = _page + 1;
      final result = await _postService.getReels(page: next, pageSize: 10);
      if (!mounted) return;
      setState(() {
        _reels.addAll(result.posts);
        _page = next;
        _hasMore = result.posts.length >= 10;
      });
    } catch (_) {
      // im lặng — cuộn tiếp sẽ thử lại
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Reels',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_reels.isEmpty) {
      return const Center(
        child: Text('Chưa có video nào.',
            style: TextStyle(color: Colors.white70, fontSize: 15)),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _reels.length,
      onPageChanged: (i) {
        setState(() => _activeIndex = i);
        if (i >= _reels.length - 2) _loadMore();
      },
      itemBuilder: (context, i) => _ReelItem(
        key: ValueKey(_reels[i].id),
        post: _reels[i],
        isActive: i == _activeIndex,
      ),
    );
  }
}

// ── Một video trong Reels ─────────────────────────────────────────────────────

class _ReelItem extends StatefulWidget {
  final Post post;
  final bool isActive;

  const _ReelItem({super.key, required this.post, required this.isActive});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  final _postService = PostService();
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _showPlayIcon = false;

  late bool _liked = widget.post.isLikedByCurrentUser;
  late int _likes = widget.post.likes;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _init();
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (_controller == null) {
        _init();
      } else {
        _controller!.play();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _init() async {
    if (_initializing || _controller != null) return;
    final url = widget.post.videoUrl;
    if (url == null || url.isEmpty) return;
    setState(() => _initializing = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      controller.addListener(_onUpdate);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      if (widget.isActive) controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _showPlayIcon = true;
      } else {
        c.play();
        _showPlayIcon = false;
      }
    });
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likes += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await _postService.unlikePost(widget.post.id);
      } else {
        await _postService.likePost(widget.post.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likes += wasLiked ? 1 : -1;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video (phủ kín) hoặc thumbnail/nền đen
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            _buildThumb(),

          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (ready && (_showPlayIcon || !c.value.isPlaying))
            const Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 72),
            ),

          // Gradient để chữ dễ đọc
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          _buildInfo(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    final thumb = widget.post.videoThumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(thumb,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.black));
    }
    return Container(color: Colors.black);
  }

  Widget _buildInfo() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => UserProfileScreen.open(
              context,
              widget.post.userId,
              displayName: widget.post.user.name,
              avatarUrl: widget.post.user.avatar,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: widget.post.user.avatar.isNotEmpty
                      ? NetworkImage(widget.post.user.avatar)
                      : null,
                  child: widget.post.user.avatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
          ),
          if (widget.post.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Positioned(
      right: 12,
      bottom: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: _liked ? Colors.redAccent : Colors.white,
            label: '$_likes',
            onTap: _toggleLike,
          ),
          const SizedBox(height: 20),
          _actionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.white,
            label: '${widget.post.commentsCount}',
            onTap: () => CommentBottomSheet.show(context, widget.post),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
