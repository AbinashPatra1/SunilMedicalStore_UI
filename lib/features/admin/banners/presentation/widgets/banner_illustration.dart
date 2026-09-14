import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/illustrations/festival_illustration.dart';
import 'package:sunil_medical_store/core/illustrations/person_badge_illustration.dart';
import 'package:sunil_medical_store/features/admin/banners/domain/home_banner.dart';

/// Human-readable label for which of the 12 fixed banner slots this is —
/// shown in the admin UI so a slot stays identifiable even after its title
/// text has been customized away from the seeded default.
String bannerSlotLabel(BannerId id) => switch (id) {
  BannerId.generalDiscount1 => 'General Discount 1',
  BannerId.generalDiscount2 => 'General Discount 2',
  BannerId.generalDiscount3 => 'General Discount 3',
  BannerId.kaliPuja => 'Kali Puja (Diwali)',
  BannerId.durgaPuja => 'Durga Puja',
  BannerId.newYear => 'New Year',
  BannerId.holi => 'Holi',
  BannerId.independenceDay => 'Independence Day',
  BannerId.ganeshPuja => 'Ganesh Puja',
  BannerId.doctorVisit1 => 'Doctor Visit 1',
  BannerId.doctorVisit2 => 'Doctor Visit 2',
  BannerId.doctorVisit3 => 'Doctor Visit 3',
};

/// The illustration for a given banner slot — fixed per id, not
/// admin-configurable (illustrations are code, not data; see
/// [BannerId]'s doc comment).
class BannerIllustration extends StatelessWidget {
  const BannerIllustration({super.key, required this.bannerId, this.size = 88});

  final BannerId bannerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (bannerId) {
      BannerId.generalDiscount1 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.percent,
        shirtColor: scheme.primary,
        badgeColor: scheme.tertiary,
      ),
      BannerId.generalDiscount2 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.local_offer,
        shirtColor: scheme.secondary,
        badgeColor: scheme.primary,
      ),
      BannerId.generalDiscount3 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.card_giftcard,
        shirtColor: scheme.tertiary,
        badgeColor: scheme.secondary,
      ),
      BannerId.kaliPuja => FestivalIllustration(
        size: size,
        motif: FestivalMotif.diya,
        accentColor: const Color(0xFFE08A2B),
      ),
      BannerId.durgaPuja => FestivalIllustration(
        size: size,
        motif: FestivalMotif.diya,
        accentColor: const Color(0xFFB0273E),
      ),
      BannerId.newYear => FestivalIllustration(
        size: size,
        motif: FestivalMotif.confetti,
        accentColor: scheme.primary,
      ),
      BannerId.holi => FestivalIllustration(
        size: size,
        motif: FestivalMotif.colorSplash,
        accentColor: scheme.primary,
      ),
      BannerId.independenceDay => FestivalIllustration(
        size: size,
        motif: FestivalMotif.flag,
        accentColor: const Color(0xFF0B6E4F),
      ),
      BannerId.ganeshPuja => FestivalIllustration(
        size: size,
        motif: FestivalMotif.sweet,
        accentColor: const Color(0xFFC0392B),
      ),
      BannerId.doctorVisit1 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.favorite,
        shirtColor: Colors.white,
        badgeColor: const Color(0xFFD24B4B),
      ),
      BannerId.doctorVisit2 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.spa,
        shirtColor: Colors.white,
        badgeColor: scheme.secondary,
      ),
      BannerId.doctorVisit3 => PersonBadgeIllustration(
        size: size,
        badgeIcon: Icons.child_care,
        shirtColor: Colors.white,
        badgeColor: scheme.tertiary,
      ),
    };
  }
}
