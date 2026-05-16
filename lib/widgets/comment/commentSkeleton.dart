import 'package:flutter/material.dart';

class CommentSkeleton extends StatefulWidget {
  final int count;
  const CommentSkeleton({super.key, this.count = 4});

  @override
  State<CommentSkeleton> createState() => _CommentSkeletonState();
}

class _CommentSkeletonState extends State<CommentSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Column(
          children: List.generate(widget.count, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar skeleton
                  _shimmerBox(
                    width: 36,
                    height: 36,
                    borderRadius: 18,
                    isDark: isDark,
                    shimmerValue: shimmerValue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name skeleton
                        _shimmerBox(
                          width: 100 + (index % 3) * 30.0,
                          height: 12,
                          borderRadius: 6,
                          isDark: isDark,
                          shimmerValue: shimmerValue,
                        ),
                        const SizedBox(height: 8),
                        // Content skeleton
                        _shimmerBox(
                          width: double.infinity,
                          height: 40 + (index % 2) * 16.0,
                          borderRadius: 12,
                          isDark: isDark,
                          shimmerValue: shimmerValue,
                        ),
                        const SizedBox(height: 6),
                        // Timestamp skeleton
                        Row(
                          children: [
                            _shimmerBox(
                              width: 50,
                              height: 10,
                              borderRadius: 5,
                              isDark: isDark,
                              shimmerValue: shimmerValue,
                            ),
                            const SizedBox(width: 16),
                            _shimmerBox(
                              width: 30,
                              height: 10,
                              borderRadius: 5,
                              isDark: isDark,
                              shimmerValue: shimmerValue,
                            ),
                            const SizedBox(width: 16),
                            _shimmerBox(
                              width: 40,
                              height: 10,
                              borderRadius: 5,
                              isDark: isDark,
                              shimmerValue: shimmerValue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double borderRadius,
    required bool isDark,
    required double shimmerValue,
  }) {
    final baseColor = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE8E8ED);
    final highlightColor =
        isDark ? const Color(0xFF3A3A40) : const Color(0xFFF5F5FA);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * shimmerValue, 0),
          end: Alignment(-1.0 + 2.0 * shimmerValue + 1.0, 0),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
