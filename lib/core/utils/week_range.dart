/// The Monday-to-Sunday range of the week containing [day].
///
/// Used by the appointments feature to show "doctors available this week" and
/// to highlight which weekdays fall in the current week.
class WeekRange {
  const WeekRange(this.start, this.end);

  /// Monday (date-only, time set to 00:00) of the week containing [day].
  final DateTime start;

  /// Sunday (date-only) of the week containing [day].
  final DateTime end;

  factory WeekRange.of(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final monday = dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return WeekRange(monday, sunday);
  }

  /// The seven dates from [start] to [end], Monday first.
  List<DateTime> get days =>
      List.generate(7, (i) => start.add(Duration(days: i)));
}
