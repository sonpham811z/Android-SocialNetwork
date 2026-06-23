import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Trình phát video cho bài đăng dạng video.
///
/// Hiển thị thumbnail (nếu có) cho tới khi người dùng bấm play, sau đó mới
/// khởi tạo [VideoPlayerController] để tiết kiệm băng thông trên feed.
class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _hasError = false;
  bool _muted = false;

  Future<void> _initializeAndPlay() async {
    if (_initializing || _controller != null) return;
    setState(() => _initializing = true);

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      controller.addListener(_onControllerUpdate);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _initializing = false;
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    final aspectRatio =
        isReady ? controller.value.aspectRatio : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: aspectRatio <= 0 ? 16 / 9 : aspectRatio,
        child: GestureDetector(
          onTap: isReady ? _togglePlayPause : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                VideoPlayer(controller)
              else
                _buildPlaceholder(),

              // Lớp phủ tối nhẹ để thấy rõ nút
              if (!isReady || !controller.value.isPlaying)
                Container(color: Colors.black.withValues(alpha: 0.25)),

              _buildCenterControl(isReady, controller),

              if (isReady) _buildBottomBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final thumb = widget.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black),
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildCenterControl(bool isReady, VideoPlayerController? controller) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white70, size: 48),
      );
    }

    final showPlayIcon = !isReady || !controller!.value.isPlaying;
    if (!showPlayIcon) return const SizedBox.shrink();

    return Center(
      child: GestureDetector(
        onTap: isReady ? _togglePlayPause : _initializeAndPlay,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(14),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildBottomBar(VideoPlayerController controller) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Text(
              _formatDuration(controller.value.position),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatDuration(controller.value.duration),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            GestureDetector(
              onTap: _toggleMute,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
