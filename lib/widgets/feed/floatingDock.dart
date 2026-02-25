import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart'; // Import để lấy data Avatar

class FloatingDock extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTabSelected;

  const FloatingDock({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

 @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDockItem(Icons.home, 0),
              _buildDockItem(Icons.explore_outlined, 1),
              _buildDockItem(Icons.people_outline, 2),

              const SizedBox(width: 4),
              // Nút Add
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE5E5E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 4),

              _buildDockItem(Icons.message_outlined, 3, badge: 3),
              _buildDockItem(Icons.notifications_outlined, 4, badge: 9),
              _buildProfileItem(5), // Avatar Profile là index 5
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, int index, {int? badge}) {
    final isActive = activeIndex == index;
    final isFilled = index == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onTabSelected(index), // Gọi callback
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 40,
                height: 40,
                child: Icon(
                  isFilled && isActive ? Icons.home : icon,
                  color: isActive ? Colors.white : AppTheme.slate400,
                  size: 22,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget riêng cho Avatar
  Widget _buildProfileItem(int index) {
    final isActive = activeIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => onTabSelected(index), // Gọi callback
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              MockData.currentUser.avatar,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}