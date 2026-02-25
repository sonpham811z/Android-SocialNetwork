import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VoicePlayer extends StatefulWidget {
  final List<double> waveform;
  final String duration;

  const VoicePlayer({
    super.key,
    required this.waveform,
    required this.duration,
  });

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation giả lập sóng nhạc nhảy múa
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Hiệu ứng Gradient nhẹ cho nền player
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
            : [AppTheme.slate100, AppTheme.slate200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.slate300,
        ),
      ),
      child: Row(
        children: [
          // Nút Play/Pause
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.violetPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violetPrimary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Waveform Visualization
          Expanded(
            child: SizedBox(
              height: 30, // Chiều cao vùng sóng
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(widget.waveform.length, (index) {
                  // Logic animation: Nếu đang play thì sóng nhấp nhô
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double height = widget.waveform[index] * 30;
                      if (_isPlaying) {
                        // Random nhẹ chiều cao khi play cho sinh động
                        final randomFactor = (index % 2 == 0) 
                            ? _controller.value 
                            : (1 - _controller.value);
                        height = height * (0.5 + 0.5 * randomFactor);
                      }
                      
                      return Container(
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: _isPlaying 
                              ? AppTheme.violetPrimary // Màu tím khi play
                              : (isDark ? AppTheme.slate600 : AppTheme.slate400), // Xám khi pause
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Duration Text
          Text(
            widget.duration,
            style: TextStyle(
              color: isDark ? AppTheme.slate400 : AppTheme.slate600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()], // Số thẳng hàng
            ),
          ),
        ],
      ),
    );
  }
}