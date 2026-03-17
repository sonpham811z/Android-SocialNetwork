import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'changePasswordScreen.dart';
import '../../providers/authProvider.dart'; // Gọi authProvider để dùng hàm logout

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          _buildSectionHeader('Account', isDark),
          _buildSettingItem(context, Icons.person_outline, 'Personal Information', isDark),
          _buildSettingItem(
            context, 
            Icons.shield_outlined, 
            'Change Password', 
            isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Preferences', isDark),
          _buildSettingItem(context, Icons.notifications_none_outlined, 'Notifications', isDark),
          _buildSettingItem(context, Icons.palette_outlined, 'Display & Theme', isDark),
          _buildSettingItem(context, Icons.language_outlined, 'Language', isDark),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Support', isDark),
          _buildSettingItem(context, Icons.help_outline, 'Help Center', isDark),
          _buildSettingItem(context, Icons.info_outline, 'About App', isDark),
          
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
              onPressed: () => _showLogoutConfirmDialog(context, isDark),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        // Fallback nếu không truyền onTap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon!')),
        );
      },
    );
  }

  // Popup hỏi xác nhận đăng xuất
  void _showLogoutConfirmDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.slate900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Đóng dialog
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // Đóng dialog
              Navigator.pop(ctx);
              
              // Gọi logic logout từ AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Đá user về màn hình Login
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}