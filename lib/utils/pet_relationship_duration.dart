import 'package:easy_localization/easy_localization.dart';

String formatTogetherFor(DateTime since, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (!reference.isAfter(since)) {
    return 'pets.together_today'.tr();
  }

  int years = reference.year - since.year;
  int months = reference.month - since.month;
  int days = reference.day - since.day;

  if (days < 0) {
    final previousMonth = DateTime(reference.year, reference.month, 0);
    days += previousMonth.day;
    months -= 1;
  }
  if (months < 0) {
    months += 12;
    years -= 1;
  }

  final parts = <String>[];
  if (years > 0) {
    parts.add('pets.age_units.year'.plural(years, args: [years.toString()]));
  }
  if (months > 0) {
    parts.add('pets.age_units.month'.plural(months, args: [months.toString()]));
  }
  if (parts.isEmpty) {
    parts.add('pets.age_units.day'.plural(days, args: [days.toString()]));
  }

  final separator = 'pets.age_units.separator'.tr();
  return parts.join(separator);
}
