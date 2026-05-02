import 'package:flutter/material.dart';
import '../../config/theme.dart';

class StatusInput extends StatelessWidget {
  final VoidCallback onTap;
  final String? avatarUrl;

  const StatusInput({
    super.key,
    required this.onTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? AppTheme.slate900 : AppTheme.slate200),
        ),
        child: Row(
          children: [
            // User avatar with plus icon
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F0F10) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      (avatarUrl ?? '').trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? AppTheme.slate800 : AppTheme.slate100,
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.white : AppTheme.slate600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Input placeholder
            Text(
              'Hôm nay bạn thế nào?',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}