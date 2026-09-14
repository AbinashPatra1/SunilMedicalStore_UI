/// The fixed catalog of home-banner slots. Illustrations are mapped 1:1 per
/// id in the presentation layer (`BannerIllustration`) — code, not
/// admin-configurable; admin only edits [HomeBanner.title]/[description]/
/// [isActive] per slot. New slots need a developer (a new illustration to
/// map), so this list isn't admin-extensible.
enum BannerId {
  generalDiscount1,
  generalDiscount2,
  generalDiscount3,
  kaliPuja,
  durgaPuja,
  newYear,
  holi,
  independenceDay,
  ganeshPuja,
  doctorVisit1,
  doctorVisit2,
  doctorVisit3,
}

/// One home-screen promo banner. Customer-facing content (title/description)
/// is fully admin-editable; [isActive] controls whether it's shown at all —
/// when more than one banner is active, the dashboard cycles through them.
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
  });

  final BannerId id;
  final String title;
  final String description;
  final bool isActive;
}
