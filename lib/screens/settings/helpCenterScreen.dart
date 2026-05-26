import 'package:flutter/material.dart';
import '../../config/theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  static const _fbBlue = Color(0xFF1877F2);

  final List<Map<String, dynamic>> _topics = const [
    {'icon': '🚀', 'title': 'Getting Started', 'color': Color(0xFF4CAF50)},
    {'icon': '🔒', 'title': 'Privacy & Safety', 'color': Color(0xFFE91E63)},
    {'icon': '⚙️', 'title': 'Account Settings', 'color': Color(0xFF2196F3)},
    {'icon': '💳', 'title': 'Payments', 'color': Color(0xFFFF9800)},
    {'icon': '🔧', 'title': 'Technical Issues', 'color': Color(0xFF9C27B0)},
    {'icon': '⚠️', 'title': 'Report a Problem', 'color': Color(0xFFF44336)},
  ];

  final List<String> _articles = const [
    'How to reset your password',
    'Managing your privacy settings',
    'How to deactivate your account',
    'Troubleshooting login issues',
    'Understanding your feed algorithm',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Help Center',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Search
          TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppTheme.slate800 : Colors.white,
              hintText: 'Search Help Center',
              hintStyle: TextStyle(color: isDark ? AppTheme.slate500 : AppTheme.slate400, fontSize: 15),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppTheme.slate500 : AppTheme.slate400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _fbBlue, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Topics
          _sectionHeader('Browse Topics', isDark),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
            children: _topics.map((t) => _topicCard(t, isDark)).toList(),
          ),
          const SizedBox(height: 28),

          // Articles
          _sectionHeader('Popular Articles', isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: List.generate(_articles.length, (i) => Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.article_outlined, size: 16, color: _fbBlue)),
                  title: Text(_articles[i], style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w500, fontSize: 14)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate500),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article coming soon!'), behavior: SnackBarBehavior.floating)),
                ),
                if (i < _articles.length - 1) Divider(height: 1, indent: 60, color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200),
              ])),
            ),
          ),
          const SizedBox(height: 28),

          // Contact
          _sectionHeader('Contact Us', isDark),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat support coming soon!'), behavior: SnackBarBehavior.floating)),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: const Text('Chat Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: _fbBlue, foregroundColor: Colors.white, elevation: 2, shadowColor: _fbBlue.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email support coming soon!'), behavior: SnackBarBehavior.floating)),
            icon: Icon(Icons.email_outlined, size: 20, color: isDark ? Colors.white : _fbBlue),
            label: Text('Email Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : _fbBlue)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? AppTheme.slate600 : _fbBlue.withOpacity(0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Text(title.toUpperCase(),
      style: TextStyle(color: AppTheme.slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _topicCard(Map<String, dynamic> t, bool isDark) => GestureDetector(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t['title']} — coming soon!'), behavior: SnackBarBehavior.floating)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.slate800 : Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (t['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Text(t['icon'] as String, style: const TextStyle(fontSize: 24))),
        const SizedBox(height: 10),
        Text(t['title'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}
