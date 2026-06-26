import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/friendModel.dart';

/// Danh sách gợi ý bạn bè khi gõ @ trong ô soạn (post/comment).
class MentionSuggestionList extends StatelessWidget {
  final List<UserLite> suggestions;
  final void Function(UserLite user) onSelected;

  const MentionSuggestionList({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.slate900;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.white12 : AppTheme.slate200),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (_, i) {
          final u = suggestions[i];
          final avatar = (u.avatarUrl ?? '').trim();
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  isDark ? const Color(0xFF2A2A2E) : AppTheme.slate200,
              backgroundImage:
                  avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
              child: avatar.isEmpty
                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 12, color: textColor))
                  : null,
            ),
            title: Text(u.name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            subtitle: Text('@${u.userName}',
                style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
            onTap: () => onSelected(u),
          );
        },
      ),
    );
  }
}

/// Lọc bạn bè theo query (so khớp username hoặc tên), tối đa [limit].
List<UserLite> filterMentionCandidates(
    List<UserLite> friends, String query, {int limit = 6}) {
  final q = query.toLowerCase();
  final matches = friends.where((f) {
    if (q.isEmpty) return true;
    return f.userName.toLowerCase().contains(q) ||
        f.name.toLowerCase().contains(q);
  }).take(limit).toList();
  return matches;
}
