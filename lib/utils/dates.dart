import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

final _initialized = <String>{};
final _pending = <String, Future<void>>{};

Future<void> ensureDateLocale(String languageTag) {
  final locale = Intl.canonicalizedLocale(languageTag);
  if (_initialized.contains(locale)) return Future.value();
  return _pending.putIfAbsent(locale, () async {
    await initializeDateFormatting(locale);
    _initialized.add(locale);
    _pending.remove(locale);
  });
}

String? formatLongDate(String? value, String languageTag) {
  if (value == null || value.isEmpty) return null;
  final date = DateTime.tryParse(value);
  if (date == null) return null;
  return DateFormat.yMMMMd(Intl.canonicalizedLocale(languageTag))
      .format(DateTime.utc(date.year, date.month, date.day));
}

String? formatDateRange(
  String? from,
  String? to,
  String languageTag, {
  required String presentLabel,
}) {
  final start = formatLongDate(from, languageTag);
  if (start == null) return null;
  final end = formatLongDate(to, languageTag);
  if (start == end) return start;
  return '$start – ${end ?? presentLabel}';
}

int? ageFrom(String? birthday, String? deathday) {
  if (birthday == null || birthday.isEmpty) return null;
  final born = DateTime.tryParse(birthday);
  if (born == null) return null;
  final reference =
      (deathday != null && deathday.isNotEmpty
          ? DateTime.tryParse(deathday)
          : null) ??
      DateTime.now();
  final age = reference.year - born.year;
  final hasHadBirthday =
      reference.month > born.month ||
      (reference.month == born.month && reference.day >= born.day);
  return hasHadBirthday ? age : age - 1;
}
