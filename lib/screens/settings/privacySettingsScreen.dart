import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/userSettingsModel.dart';
import '../../providers/languageProvider.dart';
import '../../providers/userSettingsProvider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserSettingsProvider>().loadSettings();
    });
  }

  String _labelFor(String value, String Function(String) t) {
    switch (value) {
      case 'public':
        return t('visibility_public');
      case 'friends':
        return t('visibility_friends');
      case 'onlyMe':
        return t('visibility_only_me');
      case 'everyone':
        return t('visibility_everyone');
      default:
        return value;
    }
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required String Function(String) t,
    required bool isDark,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        title: Text(title,
            style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900)),
        children: options.map((opt) {
          final isSel = opt == current;
          return RadioListTile<String>(
            value: opt,
            groupValue: current,
            activeColor: const Color(0xFF1877F2),
            onChanged: (v) => Navigator.pop(ctx, v),
            title: Text(
              _labelFor(opt, t),
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.slate900,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
    if (selected != null && selected != current) {
      onSelected(selected);
    }
  }

  Future<void> _save(
    UserSettingsProvider provider,
    PrivacySettings updated,
    String Function(String) t,
  ) async {
    final ok = await provider.updatePrivacySettings(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t('privacy_saved') : (provider.error ?? t('save_failed'))),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().translate;
    final provider = context.watch<UserSettingsProvider>();
    final privacy = provider.settings.privacySettings;

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
          t('privacy_settings'),
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
                _buildOptionTile(
                  icon: Icons.visibility_outlined,
                  title: t('profile_visibility'),
                  subtitle: t('profile_visibility_desc'),
                  currentValue: privacy.profileVisibility,
                  isDark: isDark,
                  t: t,
                  onTap: () => _pickOption(
                    title: t('profile_visibility'),
                    options: const ['public', 'friends', 'onlyMe'],
                    current: privacy.profileVisibility,
                    t: t,
                    isDark: isDark,
                    onSelected: (v) => _save(
                        provider, privacy.copyWith(profileVisibility: v), t),
                  ),
                ),
                _buildOptionTile(
                  icon: Icons.email_outlined,
                  title: t('who_can_see_email'),
                  subtitle: t('who_can_see_email_desc'),
                  currentValue: privacy.whoCanSeeEmail,
                  isDark: isDark,
                  t: t,
                  onTap: () => _pickOption(
                    title: t('who_can_see_email'),
                    options: const ['everyone', 'friends', 'onlyMe'],
                    current: privacy.whoCanSeeEmail,
                    t: t,
                    isDark: isDark,
                    onSelected: (v) =>
                        _save(provider, privacy.copyWith(whoCanSeeEmail: v), t),
                  ),
                ),
                _buildOptionTile(
                  icon: Icons.people_outline,
                  title: t('who_can_see_friends'),
                  subtitle: t('who_can_see_friends_desc'),
                  currentValue: privacy.whoCanSeeFriends,
                  isDark: isDark,
                  t: t,
                  onTap: () => _pickOption(
                    title: t('who_can_see_friends'),
                    options: const ['everyone', 'friends', 'onlyMe'],
                    current: privacy.whoCanSeeFriends,
                    t: t,
                    isDark: isDark,
                    onSelected: (v) =>
                        _save(provider, privacy.copyWith(whoCanSeeFriends: v), t),
                  ),
                ),
                _buildOptionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: t('who_can_send_request'),
                  subtitle: t('who_can_send_request_desc'),
                  currentValue: privacy.whoCanSendFriendRequest,
                  isDark: isDark,
                  t: t,
                  onTap: () => _pickOption(
                    title: t('who_can_send_request'),
                    options: const ['everyone', 'friends'],
                    current: privacy.whoCanSendFriendRequest,
                    t: t,
                    isDark: isDark,
                    onSelected: (v) => _save(provider,
                        privacy.copyWith(whoCanSendFriendRequest: v), t),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentValue,
    required bool isDark,
    required String Function(String) t,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : AppTheme.slate200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20, color: isDark ? Colors.white : AppTheme.slate900),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labelFor(currentValue, t),
              style: const TextStyle(
                color: Color(0xFF1877F2),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate500),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
