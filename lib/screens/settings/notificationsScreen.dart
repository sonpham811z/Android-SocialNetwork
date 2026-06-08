import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/userSettingsModel.dart';
import '../../providers/languageProvider.dart';
import '../../providers/userSettingsProvider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserSettingsProvider>().loadSettings();
    });
  }

  Future<void> _toggle(
    UserSettingsProvider provider,
    NotificationSettings current,
    String key,
    bool newValue,
  ) async {
    final updated = _applyToggle(current, key, newValue);
    final ok = await provider.updateNotificationSettings(updated);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save setting'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  NotificationSettings _applyToggle(NotificationSettings s, String key, bool v) {
    return switch (key) {
      'push' => s.copyWith(pushNotifications: v),
      'email' => s.copyWith(emailNotifications: v),
      'sms' => s.copyWith(smsNotifications: v),
      'likes' => s.copyWith(likes: v),
      'comments' => s.copyWith(comments: v),
      'mentions' => s.copyWith(mentions: v),
      'newFollowers' => s.copyWith(newFollowers: v),
      'friendRequests' => s.copyWith(friendRequests: v),
      'messageRequests' => s.copyWith(messageRequests: v),
      'directMessages' => s.copyWith(directMessages: v),
      _ => s,
    };
  }

  bool _getValue(NotificationSettings s, String key) => switch (key) {
        'push' => s.pushNotifications,
        'email' => s.emailNotifications,
        'sms' => s.smsNotifications,
        'likes' => s.likes,
        'comments' => s.comments,
        'mentions' => s.mentions,
        'newFollowers' => s.newFollowers,
        'friendRequests' => s.friendRequests,
        'messageRequests' => s.messageRequests,
        'directMessages' => s.directMessages,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF1877F2);
    final t = context.watch<LanguageProvider>().translate;
    final provider = context.watch<UserSettingsProvider>();
    final notif = provider.settings.notificationSettings;

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
          t('notifications'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (provider.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),

                // ===== GENERAL =====
                _buildSectionHeader(t('general'), isDark),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: t('push_notifications'),
                  subtitle: t('push_notifications_desc'),
                  value: _getValue(notif, 'push'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'push', v),
                ),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: t('email_notifications'),
                  subtitle: t('email_notifications_desc'),
                  value: _getValue(notif, 'email'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'email', v),
                ),
                _buildSwitchTile(
                  icon: Icons.sms_outlined,
                  title: t('sms_notifications'),
                  subtitle: t('sms_notifications_desc'),
                  value: _getValue(notif, 'sms'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'sms', v),
                ),

                _buildDivider(isDark),

                // ===== ACTIVITY =====
                _buildSectionHeader(t('activity'), isDark),
                _buildSwitchTile(
                  icon: Icons.favorite_border_rounded,
                  title: t('likes'),
                  subtitle: t('likes_desc'),
                  value: _getValue(notif, 'likes'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'likes', v),
                ),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: t('comments'),
                  subtitle: t('comments_desc'),
                  value: _getValue(notif, 'comments'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'comments', v),
                ),
                _buildSwitchTile(
                  icon: Icons.alternate_email_rounded,
                  title: t('mentions'),
                  subtitle: t('mentions_desc'),
                  value: _getValue(notif, 'mentions'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'mentions', v),
                ),
                _buildSwitchTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: t('new_followers'),
                  subtitle: t('new_followers_desc'),
                  value: _getValue(notif, 'newFollowers'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'newFollowers', v),
                ),

                _buildDivider(isDark),

                // ===== MESSAGES =====
                _buildSectionHeader(t('messages'), isDark),
                _buildSwitchTile(
                  icon: Icons.mark_email_unread_outlined,
                  title: t('message_requests'),
                  subtitle: t('message_requests_desc'),
                  value: _getValue(notif, 'messageRequests'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'messageRequests', v),
                ),
                _buildSwitchTile(
                  icon: Icons.send_rounded,
                  title: t('direct_messages'),
                  subtitle: t('direct_messages_desc'),
                  value: _getValue(notif, 'directMessages'),
                  isDark: isDark,
                  activeColor: activeColor,
                  onChanged: (v) => _toggle(provider, notif, 'directMessages', v),
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200,
        thickness: 1,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? activeColor.withOpacity(0.1)
                : (isDark ? AppTheme.slate800 : AppTheme.slate200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: value
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
        value: value,
        activeColor: activeColor,
        onChanged: onChanged,
      ),
    );
  }
}
