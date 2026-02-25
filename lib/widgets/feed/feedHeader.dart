import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/themeProvider.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.slate900.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: _isSearching ? _buildSearchBar() : _buildNormalHeader(isDark, themeProvider),
    );
  }

  Widget _buildNormalHeader(bool isDark, ThemeProvider themeProvider) {
    return Row(
      children: [
        // 1. Logo App 
        Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/2048px-2021_Facebook_icon.svg.png',
          height: 32,
          width: 32,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.facebook, color: Colors.blue, size: 32),
        ),

        const Spacer(), 
        // 2. Nút Search
        _buildIconButton(
          Icons.search,
          () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        
        const SizedBox(width: 8),

        _buildIconButton(
          isDark ? Icons.light_mode : Icons.dark_mode,
          () {
            themeProvider.toggleTheme();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: TextStyle(
                color: AppTheme.slate600,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFF18181B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.close, color: AppTheme.slate500, size: 20),
                onPressed: () => _searchController.clear(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: 22,
        color: AppTheme.slate400,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}