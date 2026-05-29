import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/languageProvider.dart';
import 'languageScreen.dart';

class DisplayThemeScreen extends StatefulWidget {
  const DisplayThemeScreen({super.key});

  @override
  State<DisplayThemeScreen> createState() => _DisplayThemeScreenState();
}

class _DisplayThemeScreenState extends State<DisplayThemeScreen> {
  String _selectedTheme = 'dark'; // 'light' | 'dark' | 'system'
  double _textSize = 16.0;
  bool _reduceMotion = false;
  bool _highContrast = false;

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
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('display_theme'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ===== THEME SELECTOR =====
          _buildSectionHeader(t('theme'), isDark),
          const SizedBox(height: 12),
          _buildThemeSelector(isDark, t),

          const SizedBox(height: 28),

          // ===== TEXT SIZE =====
          _buildSectionHeader(t('text_size'), isDark),
          const SizedBox(height: 12),
          _buildTextSizeSlider(isDark, t),

          const SizedBox(height: 28),

          // ===== ACCESSIBILITY =====
          _buildSectionHeader(t('accessibility'), isDark),
          const SizedBox(height: 4),
          _buildSwitchTile(
            icon: Icons.motion_photos_off_outlined,
            title: t('reduce_motion'),
            subtitle: t('reduce_motion_desc'),
            value: _reduceMotion,
            isDark: isDark,
            onChanged: (v) => setState(() => _reduceMotion = v),
          ),
          _buildSwitchTile(
            icon: Icons.contrast_rounded,
            title: t('high_contrast'),
            subtitle: t('high_contrast_desc'),
            value: _highContrast,
            isDark: isDark,
            onChanged: (v) => setState(() => _highContrast = v),
          ),

          const SizedBox(height: 12),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ===== LANGUAGE =====
          _buildLanguageTile(isDark, t),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===== SECTION HEADER =====
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppTheme.slate500,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  // ===== THEME SELECTOR (3 CARDS) =====
  Widget _buildThemeSelector(bool isDark, String Function(String) t) {
    return Row(
      children: [
        _buildThemeCard(
          key: 'light',
          label: t('light'),
          icon: Icons.light_mode_rounded,
          gradientColors: [const Color(0xFFFFF9C4), const Color(0xFFFFE082)],
          iconColor: const Color(0xFFF9A825),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildThemeCard(
          key: 'dark',
          label: t('dark'),
          icon: Icons.dark_mode_rounded,
          gradientColors: [const Color(0xFF1A237E), const Color(0xFF311B92)],
          iconColor: const Color(0xFF7C4DFF),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildThemeCard(
          key: 'system',
          label: t('system'),
          icon: Icons.settings_suggest_rounded,
          gradientColors: [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
          iconColor: const Color(0xFF42A5F5),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String key,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == key;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTheme = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _fbBlue : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _fbBlue.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Check icon top-right
              if (isSelected)
                Positioned(
                  top: -8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: _fbBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Card content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? _fbBlue
                            : (isDark ? Colors.white : AppTheme.slate900),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TEXT SIZE SLIDER =====
  Widget _buildTextSizeSlider(bool isDark, String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('font_size'),
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.slate900,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _fbBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_textSize.toInt()}px',
                  style: const TextStyle(
                    color: _fbBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _fbBlue,
              inactiveTrackColor:
                  isDark ? AppTheme.slate700 : AppTheme.slate200,
              thumbColor: _fbBlue,
              overlayColor: _fbBlue.withOpacity(0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _textSize,
              min: 12,
              max: 24,
              divisions: 4,
              label: '${_textSize.toInt()}',
              onChanged: (v) => setState(() => _textSize = v),
            ),
          ),

          // Min / Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 22,
                    color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: isDark
                ? AppTheme.slate700.withOpacity(0.5)
                : AppTheme.slate200,
          ),
          const SizedBox(height: 12),

          // Preview text
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: _textSize,
                color: isDark ? Colors.white : AppTheme.slate900,
                fontWeight: FontWeight.w500,
              ),
              child: Text(t('preview_text')),
            ),
          ),
        ],
      ),
    );
  }

  // ===== SWITCH TILE =====
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? _fbBlue.withOpacity(0.1)
              : (isDark ? AppTheme.slate800 : AppTheme.slate200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: value
              ? _fbBlue
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
      activeColor: _fbBlue,
      onChanged: onChanged,
    );
  }

  // ===== DIVIDER =====
  Widget _buildDivider(bool isDark) {
    return Divider(
      color: isDark ? AppTheme.slate700.withOpacity(0.5) : AppTheme.slate200,
      thickness: 1,
    );
  }

  // ===== LANGUAGE TILE =====
  Widget _buildLanguageTile(bool isDark, String Function(String) t) {
    final langProvider = context.watch<LanguageProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.language_rounded,
          size: 20,
          color: isDark ? Colors.white : AppTheme.slate900,
        ),
      ),
      title: Text(
        t('language'),
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.slate900,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        langProvider.languageName,
        style: TextStyle(
          color: isDark ? AppTheme.slate500 : AppTheme.slate400,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.slate500,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LanguageScreen()),
        );
      },
    );
  }
}
