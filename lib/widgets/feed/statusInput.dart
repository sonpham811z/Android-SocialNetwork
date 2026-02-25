import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';

class StatusInput extends StatelessWidget {
  final VoidCallback onTap;

  const StatusInput({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.slate900),
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
                      color: const Color(0xFF0F0F10),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      MockData.currentUser.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.slate800,
                          child: const Icon(Icons.person, color: Colors.white),
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
                        color: const Color(0xFF18181B),
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
                color: AppTheme.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}