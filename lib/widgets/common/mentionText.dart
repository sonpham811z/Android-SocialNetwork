import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Hiển thị nội dung bình luận, biến các `@username` thành text bấm được.
/// Ký tự username khớp regex backend `@([A-Za-z0-9_.]+)` để đảm bảo phần được
/// tô sáng đúng bằng phần mà server nhận diện là mention.
class MentionText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Gọi khi người dùng chạm vào một mention (đã bỏ dấu `@`, ví dụ "sonpham").
  final void Function(String username) onMentionTap;

  const MentionText({
    super.key,
    required this.text,
    required this.onMentionTap,
    this.style,
  });

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  final List<TapGestureRecognizer> _recognizers = [];
  static final RegExp _mentionRegex = RegExp(r'@([A-Za-z0-9_.]+)');

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dọn recognizer cũ trước khi build lại (khi text đổi).
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    const linkColor = AppTheme.violetPrimary;
    final spans = <TextSpan>[];
    int last = 0;

    for (final match in _mentionRegex.allMatches(widget.text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, match.start)));
      }
      final mentionWithAt = match.group(0)!;
      final username = match.group(1)!; // bỏ '@'
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onMentionTap(username);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: mentionWithAt,
        style: const TextStyle(
          color: linkColor,
          fontWeight: FontWeight.w600,
        ),
        recognizer: recognizer,
      ));
      last = match.end;
    }

    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }

    return RichText(
      text: TextSpan(style: widget.style, children: spans),
    );
  }
}
