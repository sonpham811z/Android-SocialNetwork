import 'package:flutter/material.dart';

class FloatingDock extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTabSelected;
  final VoidCallback? onAddPressed;
  final String? avatarUrl;
  final bool isVisible;
  final int notificationBadge;
  final int messageBadge;

  const FloatingDock({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    this.onAddPressed,
    this.avatarUrl,
    this.isVisible = true,
    this.notificationBadge = 0,
    this.messageBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dockBg = isDark
        ? const Color(0xFF18181B).withValues(alpha: 0.96)
        : const Color(0xFF1F1F1F).withValues(alpha: 0.88);
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.12);
    const activeIconColor = Colors.white;
    final inactiveIconColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFFD1D5DB);

    return Positioned(
      bottom: isDark ? 28 : 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeInOutCubicEmphasized,
          offset: isVisible ? Offset.zero : const Offset(0, 2.8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            opacity: isVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isVisible,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: dockBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
                      blurRadius: isDark ? 24 : 28,
                      spreadRadius: isDark ? 0 : 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDockItem(Icons.home_rounded, 0,
                        activeColor: activeIconColor,
                        inactiveColor: inactiveIconColor),
                    _buildDockItem(Icons.campaign_rounded, 1,
                        activeColor: activeIconColor,
                        inactiveColor: inactiveIconColor),
                    _buildDockItem(Icons.people_outline_rounded, 2,
                        activeColor: activeIconColor,
                        inactiveColor: inactiveIconColor),

                    const SizedBox(width: 2),
                    _buildAddButton(isDark),
                    const SizedBox(width: 2),

                    _buildDockItem(Icons.chat_bubble_outline_rounded, 3,
                        badge: messageBadge > 0 ? messageBadge : null,
                        activeColor: activeIconColor,
                        inactiveColor: inactiveIconColor),
                    _buildDockItem(Icons.notifications_outlined, 4,
                        badge: notificationBadge > 0 ? notificationBadge : null,
                        activeColor: activeIconColor,
                        inactiveColor: inactiveIconColor),
                    _buildProfileItem(5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF9FAFB), Color(0xFFE5E7EB)],
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Color(0xFF18181B), size: 24),
      ),
    );
  }

  Widget _buildDockItem(
    IconData icon,
    int index, {
    int? badge,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = activeIndex == index;
    final isFilled = index == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isActive
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  isFilled && isActive ? Icons.home_rounded : icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF18181B),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  badge > 99 ? '99+' : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(int index) {
    final isActive = activeIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              width: isActive ? 2 : 1,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              (avatarUrl ?? '').trim(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF2A2A2D),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
