import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Hiển thị nội dung bài viết, biến các #hashtag thành text bấm được.
/// Hỗ trợ ký tự tiếng Việt có dấu (dùng \p{L} unicode).
class HashtagText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Gọi khi người dùng chạm vào 1 hashtag (đã bỏ dấu #, ví dụ "flutter").
  final void Function(String tag) onTagTap;

  const HashtagText({
    super.key,
    required this.text,
    required this.onTagTap,
    this.style,
  });

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  final List<TapGestureRecognizer> _recognizers = [];
  static final RegExp _hashtagRegex =
      RegExp(r'#[\p{L}\p{N}_]+', unicode: true);

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

    for (final match in _hashtagRegex.allMatches(widget.text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, match.start)));
      }
      final tagWithHash = match.group(0)!;
      final tag = tagWithHash.substring(1); // bỏ '#'
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onTagTap(tag);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: tagWithHash,
        style: const TextStyle(color: linkColor, fontWeight: FontWeight.w600),
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
