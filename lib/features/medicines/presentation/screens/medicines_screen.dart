import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/placeholder_screen.dart';

/// Medicine catalog: browsing, search, and category filtering.
class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Medicines',
      icon: Icons.medication_outlined,
      message: 'Medicine search and catalog browsing will be implemented here.',
    );
  }
}
