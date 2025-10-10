import 'package:flutter/material.dart';

class AppColors {
  // Dark backgrounds (for main screens)
  static const Color primary = Color(0xFF0A1628);      // Deep navy (darker than before)
  static const Color secondary = Color(0xFF132842);    // Dark blue-gray
  static const Color surface = Color(0xFF1A3A52);      // Elevated surface color
  
  // Light backgrounds (for cards on dark bg)
  static const Color cardLight = Color(0xFFF5F9FF);    // Very light blue
  static const Color cardWhite = Color(0xFFFFFFFF);    // Pure white
  
  // Accent colors - VIBRANT for visual pop
  static const Color accentBlue = Color(0xFF4DA6FF);   // Bright blue
  static const Color accentCyan = Color(0xFF00D9FF);   // Cyan highlight
  static const Color accentPurple = Color(0xFF8B7FFF); // Purple accent
  
  // Exercise type colors - BRIGHT and DISTINCT
  static const Color orange = Color(0xFFFF9500);       // iOS orange (strength)
  static const Color red = Color(0xFFFF3B30);          // iOS red (cardio)
  static const Color blue = Color(0xFF007AFF);         // iOS blue (core)
  static const Color green = Color(0xFF34C759);        // iOS green (flexibility)
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);  // White
  static const Color textSecondary = Color(0xFFB8C5D6); // Light blue-gray
  static const Color textTertiary = Color(0xFF6B7D94); // Medium gray-blue
  static const Color textDark = Color(0xFF1A1A1A);     // For light backgrounds
  
  // Grays
  static const Color lightGray = Color(0xFFE5E5EA);
  static const Color mediumGray = Color(0xFF8E8E93);
  static const Color darkGray = Color(0xFF48484A);
  
  // System colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF3B30);
}