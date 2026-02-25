import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friend suggestions
          _buildSuggestionsSection(),

          const SizedBox(height: 32),

          // Online friends
          _buildOnlineFriendsSection(),

          const SizedBox(height: 32),

          // Footer links
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate900.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gợi ý kết bạn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Suggestion list
          ...MockData.suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSuggestionItem(suggestion, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(FriendSuggestion suggestion, int index) {
    return Row(
      children: [
        // Avatar
        if (index < 2)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.slate800,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.slate700),
            ),
            child: Center(
              child: Text(
                suggestion.user.name.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slate400,
                ),
              ),
            ),
          )
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.slate800),
            ),
            child: ClipOval(
              child: Image.network(
                suggestion.user.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.slate800,
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  );
                },
              ),
            ),
          ),

        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.user.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate200,
                ),
              ),
              Text(
                suggestion.user.handle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate500,
                ),
              ),
            ],
          ),
        ),

        // Add button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.slate700),
          ),
          child: IconButton(
            icon: Icon(
              Icons.person_add_outlined,
              size: 16,
              color: AppTheme.slate400,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineFriendsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate900.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Người liên hệ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.search,
                size: 16,
                color: AppTheme.slate500,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Empty state
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.slate900.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.slate800),
                ),
                child: Icon(
                  Icons.group_outlined,
                  size: 24,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có ai online',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildFooterLink('Giới thiệu'),
        _buildFooterLink('Trợ giúp'),
        _buildFooterLink('Quyền riêng tư'),
        _buildFooterLink('Điều khoản'),
        Text(
          '© 2025 Shiku Social',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.slate600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppTheme.slate600,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
    );
  }
}