import 'package:flutter/material.dart';
import '../../config/theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _fbBlue = Color(0xFF1877F2);

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
    {'code': 'vi', 'name': 'Vietnamese', 'native': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文', 'flag': '🇨🇳'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português', 'flag': '🇵🇹'},
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'ru', 'name': 'Russian', 'native': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'th', 'name': 'Thai', 'native': 'ภาษาไทย', 'flag': '🇹🇭'},
    {'code': 'id', 'name': 'Indonesian', 'native': 'Indonesia', 'flag': '🇮🇩'},
  ];

  List<Map<String, String>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _languages;
    final q = _searchQuery.toLowerCase();
    return _languages
        .where((l) =>
            l['name']!.toLowerCase().contains(q) ||
            l['native']!.toLowerCase().contains(q) ||
            l['code']!.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredLanguages;

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
          'Language',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.slate900,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppTheme.slate800 : Colors.white,
                hintText: 'Search language...',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 20,
                            color: isDark
                                ? AppTheme.slate400
                                : AppTheme.slate500),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.slate700.withOpacity(0.5)
                        : AppTheme.slate200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _fbBlue, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // ===== LANGUAGE LIST =====
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color:
                                isDark ? AppTheme.slate600 : AppTheme.slate400),
                        const SizedBox(height: 12),
                        Text(
                          'No languages found',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.slate500
                                : AppTheme.slate400,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final lang = filtered[index];
                      final isSelected = _selectedLanguage == lang['code'];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _fbBlue.withOpacity(0.1)
                                : (isDark
                                    ? AppTheme.slate800
                                    : AppTheme.slate100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        title: Text(
                          lang['name']!,
                          style: TextStyle(
                            color: isSelected
                                ? _fbBlue
                                : (isDark ? Colors.white : AppTheme.slate900),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          lang['native']!,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.slate500
                                : AppTheme.slate400,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: _fbBlue, size: 22)
                            : null,
                        onTap: () {
                          setState(() => _selectedLanguage = lang['code']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
