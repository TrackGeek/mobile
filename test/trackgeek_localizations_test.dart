import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/l10n/trackgeek_localizations.dart';

Future<String> _read(String path) async {
  if (path.endsWith('common.json')) {
    if (path.contains('pt-PT')) return '{"language":"Idioma"}';
    return '{"language":"Language"}';
  }
  return '{}';
}

void main() {
  test('supports date formatting in every app language', () async {
    final l10n = await TrackGeekLocalizations.load(
      const Locale('en', 'US'),
      read: _read,
    );

    for (final language in TrackGeekLocalizations.supportedLanguages) {
      await l10n.setLanguage(language, _read);
      expect(
        () => DateFormat.yMd(language).format(DateTime(2024, 1, 31)),
        returnsNormally,
        reason: language,
      );
    }
  });

  testWidgets('loads date formatting before rebuilding in a new language', (
    tester,
  ) async {
    final l10n = await TrackGeekLocalizations.load(
      const Locale('en', 'US'),
      read: _read,
    );
    await tester.pumpWidget(
      L10nScope(
        localizations: l10n,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final language = L10nScope.of(context).language;
              return Text(
                '${context.t('common:language')}: '
                '${DateFormat.yMd(language).format(DateTime(2024, 1, 31))}',
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Language: 1/31/2024'), findsOneWidget);

    await l10n.setLanguage('pt-PT', _read);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Idioma: 31/01/2024'), findsOneWidget);
  });
}
