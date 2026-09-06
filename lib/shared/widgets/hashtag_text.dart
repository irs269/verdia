import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

final _hashtagPattern = RegExp(r'#([a-zA-Z0-9_]+)');

/// Affiche [text] avec ses `#hashtags` mis en évidence et cliquables — voir
/// audit, item "Hashtags". Même expression régulière que le trigger
/// `extract_hashtags` (migration 0024) côté serveur, pour que ce qui est
/// surligné corresponde exactement à ce qui a réellement été indexé.
class HashtagText extends StatelessWidget {
  const HashtagText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _hashtagPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final tag = match.group(1)!;
      spans.add(
        TextSpan(
          text: '#$tag',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()
            ..onTap = () => context.push('/hashtags/${tag.toLowerCase()}'),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
