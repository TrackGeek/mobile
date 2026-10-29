import 'package:flutter/widgets.dart';

import '../l10n/l10n_context.dart';

String formatStatusKey(String statusName) {
  final words = statusName.split(' ');
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;
    if (i == 0) {
      buffer.write(word[0].toLowerCase() + word.substring(1));
    } else {
      buffer.write(word[0].toUpperCase() + word.substring(1));
    }
  }
  return buffer.toString();
}

String statusLabel(BuildContext context, String statusName) {
  final key = 'library:statusAir.${formatStatusKey(statusName)}';
  final label = context.t(key);
  return label == key ? statusName : label;
}
