import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Một mục nội dung tĩnh: tiêu đề phụ (tùy chọn) + nội dung.
class StaticSection {
  final String? heading;
  final String body;
  const StaticSection({this.heading, required this.body});
}

/// Màn hình hiển thị nội dung tĩnh (Chính sách bảo mật, Điều khoản, Giấy phép...).
class StaticContentScreen extends StatelessWidget {
  final String title;
  final List<StaticSection> sections;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppTheme.slate900;
    final bodyColor = isDark ? AppTheme.slate300 : AppTheme.slate700;

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
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final s = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.heading != null && s.heading!.isNotEmpty) ...[
                Text(
                  s.heading!,
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                s.body,
                style: TextStyle(color: bodyColor, fontSize: 14, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }
}
