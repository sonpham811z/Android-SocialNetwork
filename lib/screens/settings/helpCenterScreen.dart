import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/languageProvider.dart';
import 'staticContentScreen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  static const _fbBlue = Color(0xFF1877F2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTopics(String Function(String) t) => [
    {'icon': '🚀', 'title': t('getting_started'), 'color': const Color(0xFF4CAF50), 'body': t('getting_started_body')},
    {'icon': '🔒', 'title': t('privacy_safety'), 'color': const Color(0xFFE91E63), 'body': t('privacy_safety_body')},
    {'icon': '⚙️', 'title': t('account_settings'), 'color': const Color(0xFF2196F3), 'body': t('account_settings_body')},
    {'icon': '💳', 'title': t('payments'), 'color': const Color(0xFFFF9800), 'body': t('payments_body')},
    {'icon': '🔧', 'title': t('technical_issues'), 'color': const Color(0xFF9C27B0), 'body': t('technical_issues_body')},
    {'icon': '⚠️', 'title': t('report_problem'), 'color': const Color(0xFFF44336), 'body': t('report_problem_body')},
  ];

  List<Map<String, String>> _getArticles(String Function(String) t) => [
    {'title': t('reset_password_article'), 'body': t('reset_password_article_body')},
    {'title': t('privacy_settings_article'), 'body': t('privacy_settings_article_body')},
    {'title': t('deactivate_account_article'), 'body': t('deactivate_account_article_body')},
    {'title': t('login_issues_article'), 'body': t('login_issues_article_body')},
    {'title': t('feed_algorithm_article'), 'body': t('feed_algorithm_article_body')},
  ];

  void _openContent(String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaticContentScreen(
          title: title,
          sections: [StaticSection(body: body)],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.slate800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('contact_us'),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('contact_support_desc'),
                style: TextStyle(color: isDark ? AppTheme.slate300 : AppTheme.slate700, fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            _contactRow(Icons.email_outlined, t('email_support'), t('support_email_value'), isDark),
            const SizedBox(height: 12),
            _contactRow(Icons.schedule_outlined, t('support_hours_label'), t('support_hours_value'), isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'), style: const TextStyle(color: _fbBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, bool isDark) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _fbBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppTheme.slate500, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().translate;
    final topics = _getTopics(t);
    final articles = _getArticles(t);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('help_center'),
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
              hintText: t('search_help_center'),
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
          _sectionHeader(t('browse_topics'), isDark),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
            children: topics.map((tp) => _topicCard(tp, isDark, t)).toList(),
          ),
          const SizedBox(height: 28),

          // Articles
          _sectionHeader(t('popular_articles'), isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: List.generate(articles.length, (i) => Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.article_outlined, size: 16, color: _fbBlue)),
                  title: Text(articles[i]['title']!, style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w500, fontSize: 14)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate500),
                  onTap: () => _openContent(articles[i]['title']!, articles[i]['body']!),
                ),
                if (i < articles.length - 1) Divider(height: 1, indent: 60, color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200),
              ])),
            ),
          ),
          const SizedBox(height: 28),

          // Contact
          _sectionHeader(t('contact_us'), isDark),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: () => _showContactDialog(context, t),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: Text(t('chat_support'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: _fbBlue, foregroundColor: Colors.white, elevation: 2, shadowColor: _fbBlue.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
            onPressed: () => _showContactDialog(context, t),
            icon: Icon(Icons.email_outlined, size: 20, color: isDark ? Colors.white : _fbBlue),
            label: Text(t('email_support'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : _fbBlue)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? AppTheme.slate600 : _fbBlue.withOpacity(0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Text(title.toUpperCase(),
      style: TextStyle(color: AppTheme.slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _topicCard(Map<String, dynamic> tp, bool isDark, String Function(String) t) => GestureDetector(
    onTap: () => _openContent(tp['title'] as String, tp['body'] as String),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.slate800 : Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (tp['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Text(tp['icon'] as String, style: const TextStyle(fontSize: 24))),
        const SizedBox(height: 10),
        Text(tp['title'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}
