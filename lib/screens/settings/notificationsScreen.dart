import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _settings = {
    // General
    'push': true,
    'email': false,
    'sms': false,
    // Activity
    'likes': true,
    'comments': true,
    'mentions': true,
    'newFollowers': false,
    // Messages
    'messageRequests': true,
    'directMessages': true,
  };

  void _toggle(String key) {
    setState(() => _settings[key] = !(_settings[key] ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF1877F2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ===== GENERAL =====
          _buildSectionHeader('General', isDark),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications on your device',
            settingsKey: 'push',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            settingsKey: 'email',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.sms_outlined,
            title: 'SMS Notifications',
            subtitle: 'Receive notifications via text message',
            settingsKey: 'sms',
            isDark: isDark,
            activeColor: activeColor,
          ),

          // ===== DIVIDER =====
          _buildDivider(isDark),

          // ===== ACTIVITY =====
          _buildSectionHeader('Activity', isDark),
          _buildSwitchTile(
            icon: Icons.favorite_border_rounded,
            title: 'Likes',
            subtitle: 'Someone liked your post',
            settingsKey: 'likes',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Comments',
            subtitle: 'Someone commented on your post',
            settingsKey: 'comments',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.alternate_email_rounded,
            title: 'Mentions',
            subtitle: 'Someone mentioned you',
            settingsKey: 'mentions',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.person_add_alt_1_outlined,
            title: 'New Followers',
            subtitle: 'Someone started following you',
            settingsKey: 'newFollowers',
            isDark: isDark,
            activeColor: activeColor,
          ),

          // ===== DIVIDER =====
          _buildDivider(isDark),

          // ===== MESSAGES =====
          _buildSectionHeader('Messages', isDark),
          _buildSwitchTile(
            icon: Icons.mark_email_unread_outlined,
            title: 'Message Requests',
            subtitle: 'Receive notifications for message requests',
            settingsKey: 'messageRequests',
            isDark: isDark,
            activeColor: activeColor,
          ),
          _buildSwitchTile(
            icon: Icons.send_rounded,
            title: 'Direct Messages',
            subtitle: 'Receive notifications for new messages',
            settingsKey: 'directMessages',
            isDark: isDark,
            activeColor: activeColor,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===== SECTION HEADER =====
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppTheme.slate500 : AppTheme.slate500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ===== DIVIDER =====
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        color: isDark
            ? AppTheme.slate700.withOpacity(0.5)
            : AppTheme.slate200,
        thickness: 1,
      ),
    );
  }

  // ===== SWITCH TILE =====
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String settingsKey,
    required bool isDark,
    required Color activeColor,
  }) {
    final isOn = _settings[settingsKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOn
                ? activeColor.withOpacity(0.1)
                : (isDark ? AppTheme.slate800 : AppTheme.slate200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isOn
                ? activeColor
                : (isDark ? AppTheme.slate400 : AppTheme.slate500),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.slate900,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppTheme.slate500 : AppTheme.slate400,
            fontSize: 12,
          ),
        ),
        value: isOn,
        activeColor: activeColor,
        onChanged: (_) => _toggle(settingsKey),
      ),
    );
  }
}
