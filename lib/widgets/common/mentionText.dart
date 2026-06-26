import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/userProfileService.dart';
import '../../screens/appScreen/userProfileScreen.dart';

/// Khớp token @username (chữ/số/_/.). Không dùng lookbehind cho tương thích rộng.
final RegExp mentionRegExp = RegExp(r'@([A-Za-z0-9_.]+)');

/// Hiển thị text có highlight + bấm được vào các @username.
class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MentionText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final mentionStyle = base.copyWith(
      color: const Color(0xFF2D88FF),
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in mentionRegExp.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final username = m.group(1)!;
      spans.add(TextSpan(
        text: '@$username',
        style: mentionStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => openMentionedUser(context, username),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: base, children: spans),
    );
  }
}

/// Tra cứu username → mở trang cá nhân.
Future<void> openMentionedUser(BuildContext context, String username) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final user = await UserProfileService().getProfileByUsername(username);
    if (!context.mounted) return;
    if (user == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không tìm thấy người dùng @$username')),
      );
      return;
    }
    UserProfileScreen.open(
      context,
      user.id,
      displayName: user.displayName,
      avatarUrl: user.avatar,
    );
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Không mở được @$username')),
    );
  }
}
