/// Time window for the admin Statistics dashboard.
enum StatsRange {
  today,
  sevenDays,
  thirtyDays,
  sixMonths,
  oneYear,
  allTime;

  String get label => switch (this) {
    StatsRange.today => 'Today',
    StatsRange.sevenDays => '7 days',
    StatsRange.thirtyDays => '30 days',
    StatsRange.sixMonths => '6 months',
    StatsRange.oneYear => '1 year',
    StatsRange.allTime => 'All time',
  };

  /// Wire value sent as the `range` query param — see
  /// `docs/API_ENDPOINTS.md` §Admin — Statistics.
  String get wireValue => switch (this) {
    StatsRange.today => 'today',
    StatsRange.sevenDays => '7d',
    StatsRange.thirtyDays => '30d',
    StatsRange.sixMonths => '6m',
    StatsRange.oneYear => '1y',
    StatsRange.allTime => 'all',
  };
}
