import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // <-- Xóa dòng này đi, không dùng nữa
import '../config/theme.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Sign in with Google',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.slate800 : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.slate900,
          side: BorderSide(
            color: isDark ? AppTheme.slate600 : AppTheme.slate300,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- SỬA LẠI ĐƯỜNG DẪN CHUẨN ---
            Image.asset(
              'assets/images/google_logo.png', // Tính từ gốc project, không có ../..
              height: 24, 
              width: 24,
            ),
            // -------------------------------
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}