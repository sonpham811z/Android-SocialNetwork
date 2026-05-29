import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/languageProvider.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().translate;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('about_app'),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: [
          // ===== APP HEADER =====
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_fbBlue, Color(0xFF42A5F5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _fbBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.people_alt_rounded, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(t('social_network'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.slate900)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('${t('version')} 1.0.0', style: const TextStyle(color: _fbBlue, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Text(t('connect_share_inspire'),
              style: TextStyle(color: isDark ? AppTheme.slate500 : AppTheme.slate400, fontSize: 15, fontStyle: FontStyle.italic)),
          const SizedBox(height: 28),

          // ===== APP INFO =====
          _buildInfoCard(isDark, [
            _infoTile(t('version'), '1.0.0', Icons.info_outline, isDark),
            _divider(isDark),
            _infoTile(t('build_number'), '2026.05.26', Icons.build_outlined, isDark),
            _divider(isDark),
            _infoTile(t('developer'), 'Son Pham', Icons.code_rounded, isDark),
            _divider(isDark),
            _infoTile(t('website'), 'socialnetwork.app', Icons.language_rounded, isDark),
          ]),
          const SizedBox(height: 16),

          // ===== LEGAL =====
          _buildInfoCard(isDark, [
            _navTile(t('privacy_policy'), Icons.privacy_tip_outlined, isDark, context, t),
            _divider(isDark),
            _navTile(t('terms_of_service'), Icons.description_outlined, isDark, context, t),
          ]),
          const SizedBox(height: 16),

          // ===== LICENSES =====
          _buildInfoCard(isDark, [
            _navTile(t('licenses'), Icons.article_outlined, isDark, context, t),
            _divider(isDark),
            _navTile(t('acknowledgements'), Icons.favorite_border_rounded, isDark, context, t),
          ]),
          const SizedBox(height: 28),

          // ===== RATE BUTTON =====
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('thank_you_support')), behavior: SnackBarBehavior.floating)),
              icon: const Icon(Icons.star_rounded, size: 22),
              label: Text(t('rate_this_app'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _fbBlue, foregroundColor: Colors.white, elevation: 4,
                shadowColor: _fbBlue.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ===== COPYRIGHT =====
          Text(t('copyright'),
              style: TextStyle(color: isDark ? AppTheme.slate600 : AppTheme.slate400, fontSize: 12)),
          const SizedBox(height: 8),
          Text(t('made_in_vietnam'),
              style: TextStyle(color: isDark ? AppTheme.slate600 : AppTheme.slate400, fontSize: 12)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(String title, String value, IconData icon, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: _fbBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: _fbBlue),
      ),
      title: Text(title, style: TextStyle(color: isDark ? AppTheme.slate400 : AppTheme.slate500, fontSize: 13)),
      trailing: Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _navTile(String title, IconData icon, bool isDark, BuildContext context, String Function(String) t) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: isDark ? AppTheme.slate700 : AppTheme.slate100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: isDark ? AppTheme.slate400 : AppTheme.slate500),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate500),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title${t('coming_soon_suffix')}'), behavior: SnackBarBehavior.floating)),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, indent: 64, color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200);
  }
}
