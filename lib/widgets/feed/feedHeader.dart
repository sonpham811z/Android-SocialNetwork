import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/themeProvider.dart';
import '../../screens/appScreen/searchScreen.dart';

class FeedHeader extends StatefulWidget {
  final VoidCallback onCreatePost;

  const FeedHeader({
    super.key,
    required this.onCreatePost,
  });

  @override
  State<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends State<FeedHeader> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F0F10) : Colors.white).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppTheme.slate900 : AppTheme.slate200).withOpacity(0.7),
            width: 1,
          ),
        ),
      ),
      child: _buildNormalHeader(isDark, themeProvider),
    );
  }

  Widget _buildNormalHeader(bool isDark, ThemeProvider themeProvider) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : AppTheme.slate100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppTheme.slate200,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Transform.scale(
              scale: 1.28,
              child: Image.asset(
                'assets/images/anh.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Zest',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: isDark ? Colors.white : AppTheme.slate900,
                ),
              ),
              Text(
                'Connect your vibe',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        _buildIconButton(
          Icons.search,
          isDark,
          () => SearchScreen.open(context),
        ),

        const SizedBox(width: 8),

        _buildIconButton(
          isDark ? Icons.light_mode : Icons.dark_mode,
          isDark,
          () {
            themeProvider.toggleTheme();
          },
        ),

        const SizedBox(width: 8),
        _buildIconButton(
          Icons.add_rounded,
          isDark,
          widget.onCreatePost,
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, bool isDark, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppTheme.slate100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: 22,
        color: isDark ? AppTheme.slate400 : AppTheme.slate700,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
