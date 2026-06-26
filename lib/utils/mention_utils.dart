import 'package:flutter/widgets.dart';

/// @query đang được gõ ngay trước con trỏ.
class MentionQuery {
  final String query; // phần sau @ (chưa gồm @)
  final int start; // vị trí ký tự @
  const MentionQuery(this.query, this.start);
}

/// Phát hiện token @... đang gõ ngay trước con trỏ (để gợi ý). Trả về null nếu không có.
MentionQuery? activeMentionQuery(TextEditingValue value) {
  final sel = value.selection;
  if (!sel.isCollapsed || sel.baseOffset < 0) return null;
  final cursor = sel.baseOffset;
  if (cursor > value.text.length) return null;
  final before = value.text.substring(0, cursor);
  final match = RegExp(r'(^|\s)@([A-Za-z0-9_.]{0,30})$').firstMatch(before);
  if (match == null) return null;
  final at = before.lastIndexOf('@');
  return MentionQuery(match.group(2) ?? '', at);
}

/// Thay token @query đang gõ bằng "@username " và đặt lại con trỏ.
TextEditingValue applyMention(
    TextEditingValue value, MentionQuery q, String username) {
  final cursor = value.selection.baseOffset;
  final before = value.text.substring(0, q.start);
  final after = value.text.substring(cursor);
  final insert = '@$username ';
  final text = before + insert + after;
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: (before + insert).length),
  );
}
