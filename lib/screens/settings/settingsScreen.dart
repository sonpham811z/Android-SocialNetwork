import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'changePasswordScreen.dart';
import 'personalInformationScreen.dart';
import 'notificationsScreen.dart';
import 'displayThemeScreen.dart';
import 'languageScreen.dart';
import 'helpCenterScreen.dart';
import 'aboutAppScreen.dart';
import '../../providers/authProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/friendProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../providers/languageProvider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: Text(
          t('settings'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          _buildSectionHeader(t('account'), isDark),
          _buildSettingItem(
            context, 
            Icons.person_outline, 
            t('personal_information'), 
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonalInformationScreen()),
              );
            },
          ),
          _buildSettingItem(
            context, 
            Icons.shield_outlined, 
            t('change_password'), 
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader(t('preferences'), isDark),
          _buildSettingItem(
            context,
            Icons.notifications_none_outlined,
            t('notifications'),
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          _buildSettingItem(
            context,
            Icons.palette_outlined,
            t('display_theme'),
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisplayThemeScreen()),
              );
            },
          ),
          _buildSettingItem(
            context,
            Icons.language_outlined,
            t('language'),
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader(t('support'), isDark),
          _buildSettingItem(
            context,
            Icons.help_outline,
            t('help_center'),
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
              );
            },
          ),
          _buildSettingItem(
            context,
            Icons.info_outline,
            t('about_app'),
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Nút Đăng Xuất (Logout) màu đỏ nổi bật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1), // Nền đỏ nhạt
                foregroundColor: Colors.red, // Chữ đỏ
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
              ),
              onPressed: () => _showLogoutConfirmDialog(context, isDark, t),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout),
                  const SizedBox(width: 8),
                  Text(t('log_out'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40), // Khoảng trống dưới cùng
        ],
      ),
    );
  }

  // Widget Header của từng phần
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.slate500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Widget từng dòng setting
  // Thêm tham số VoidCallback? onTap
  Widget _buildSettingItem(BuildContext context, IconData icon, String title, bool isDark, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : AppTheme.slate900),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.slate900,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.slate500),
      onTap: onTap ?? () {
        final t = context.read<LanguageProvider>().translate;
        // Fallback nếu không truyền onTap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('feature_coming_soon'))),
        );
      },
    );
  }

  // Popup hỏi xác nhận đăng xuất
  void _showLogoutConfirmDialog(BuildContext context, bool isDark, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.slate900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t('log_out'),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          t('log_out_confirm'),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Đóng dialog
            child: Text(t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // Đóng dialog
              Navigator.pop(ctx);
              
              // Clear tất cả provider data trước khi logout
              context.read<UserProfileProvider>().clear();
              context.read<PostProvider>().clear();
              context.read<FriendProvider>().clear();
              context.read<ConversationProvider>().clear();

              // Gọi logic logout từ AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Đá user về màn hình Login
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Text(t('log_out'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}