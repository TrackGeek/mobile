import 'package:intl/intl.dart';

String numberLocale = 'en_US';

void setNumberLocale(String languageTag) {
  numberLocale = Intl.verifiedLocale(
    Intl.canonicalizedLocale(languageTag),
    NumberFormat.localeExists,
    onFailure: (_) => 'en_US',
  )!;
}

extension NumX on num {
  String humanizedCount({int? decimalDigits}) =>
      NumberFormat.decimalPatternDigits(
        locale: numberLocale,
        decimalDigits: decimalDigits,
      ).format(this);

  String humanizedCurrency(String code) => NumberFormat.simpleCurrency(
    locale: numberLocale,
    name: code,
  ).format(this);

  String humanizedCompact() =>
      NumberFormat.compact(locale: numberLocale).format(this);
}
