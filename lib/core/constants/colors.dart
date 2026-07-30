import 'package:flutter/material.dart';

/// Brand color palette for Brainyte Restaurant POS.
///
/// Designed for professional restaurant operations with high contrast,
/// large touch targets, and a modern, warm feel.
class AppColors {
  // Primary: Deep navy blue - conveys trust, professionalism
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1642);

  // Accent: Warm amber/gold - energetic, appetizing
  static const Color accent = Color(0xFFFF8F00);
  static const Color accentLight = Color(0xFFFFC107);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // Surfaces
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color card = Colors.white;

  // Text
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Status colors for tables/orders
  static const Color statusAvailable = Color(0xFF2E7D32);
  static const Color statusOccupied = Color.fromARGB(255, 221, 36, 23);
  static const Color statusReserved = Color(0xFF1565C0);
  static const Color statusClosed = Color(0xFF616161);

  // Order status colors
  static const Color orderPending = Color(0xFFFF8F00);
  static const Color orderPreparing = Color(0xFF1565C0);
  static const Color orderReady = Color(0xFF2E7D32);
  static const Color orderServed = Color(0xFF6A1B9A);
static const Color orderCompleted = Color(0xFF616161);

  @Deprecated('Use semantic color names instead')
  static const Color muted = textSecondary;
}
