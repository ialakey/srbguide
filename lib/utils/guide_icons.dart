import 'package:flutter/material.dart';

/// Maps the stable icon keys written by `tool/sync_guide.dart` to Material
/// icons.
///
/// Section icons used to be recoloured PNG assets, which meant every new
/// section needed an artwork file and none of them adapted to the theme.
IconData guideSectionIcon(String key) {
  switch (key) {
    case 'luggage':
      return Icons.luggage_outlined;
    case 'person':
      return Icons.badge_outlined;
    case 'bank':
      return Icons.account_balance_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'verified':
      return Icons.verified_outlined;
    case 'work':
      return Icons.work_outline;
    case 'health':
      return Icons.medical_services_outlined;
    case 'car':
      return Icons.directions_car_outlined;
    default:
      return Icons.article_outlined;
  }
}
