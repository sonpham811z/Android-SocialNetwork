import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/languageProvider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _fbBlue = Color(0xFF1877F2);

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
    {'code': 'vi', 'name': 'Vietnamese', 'native': 'Tiếng Việt', 'flag': '🇻🇳'},
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
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

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
          t('language'),
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
                hintText: t('search_language'),
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
                          t('no_languages_found'),
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
                      final langItem = filtered[index];
                      final isSelected = lang.languageCode == langItem['code'];

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
                            langItem['flag']!,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        title: Text(
                          langItem['name']!,
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
                          langItem['native']!,
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
                          lang.setLanguage(langItem['code']!);
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
