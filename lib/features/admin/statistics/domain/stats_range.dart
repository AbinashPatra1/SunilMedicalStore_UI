/// Time window for the admin Statistics dashboard.
enum StatsRange {
  today,
  sevenDays,
  thirtyDays,
  allTime;

  String get label => switch (this) {
    StatsRange.today => 'Today',
    StatsRange.sevenDays => '7 days',
    StatsRange.thirtyDays => '30 days',
    StatsRange.allTime => 'All time',
  };

  /// Wire value sent as the `range` query param — see
  /// `docs/API_ENDPOINTS.md` §Admin — Statistics.
  String get wireValue => switch (this) {
    StatsRange.today => 'today',
    StatsRange.sevenDays => '7d',
    StatsRange.thirtyDays => '30d',
    StatsRange.allTime => 'all',
  };
}
