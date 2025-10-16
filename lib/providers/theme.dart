// lib/theme/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';

class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isDarkMode => _isDarkMode;

  ThemeManager() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('darkMode')) {
          _isDarkMode = data['darkMode'] ?? true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .set({'darkMode': isDark}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // ===== FIXED COLOR GETTERS =====
  
  // Background colors - FIXED
  Color get primaryBackground => _isDarkMode 
      ? AppColors.primary  // Dark navy blue
      : Color(0xFFF5F7FA); // Light gray-blue
  
  Color get secondaryBackground => _isDarkMode 
      ? AppColors.secondary  // Slightly lighter navy
      : Color(0xFFFFFFFF);   // Pure white
  
  Color get surfaceColor => _isDarkMode 
      ? AppColors.surface  // Card surface in dark
      : Colors.white;
  
  // Card color - THIS WAS THE MAIN ISSUE
  Color get cardColor => _isDarkMode 
      ? Color(0xFF1E293B)  // Dark slate (visible in dark mode)
      : Colors.white;       // White (visible in light mode)
  
  // Text colors - FIXED
  Color get primaryText => _isDarkMode 
      ? AppColors.textPrimary  // Light text for dark bg
      : Color(0xFF1F2937);      // Dark text for light bg
  
  Color get secondaryText => _isDarkMode 
      ? AppColors.textSecondary  // Medium light text
      : Color(0xFF6B7280);       // Medium dark text
  
  Color get tertiaryText => _isDarkMode 
      ? AppColors.textTertiary  // Subtle light text
      : Color(0xFF9CA3AF);      // Subtle dark text

  // Gradient colors that work in both modes
  List<Color> get primaryGradient => _isDarkMode
      ? [AppColors.accentBlue, AppColors.accentCyan]
      : [AppColors.accentBlue.withOpacity(0.8), AppColors.accentCyan.withOpacity(0.6)];

  List<Color> get backgroundGradient => _isDarkMode
      ? [
          AppColors.primary,
          AppColors.secondary.withOpacity(0.95),
          AppColors.surface.withOpacity(0.90),
        ]
      : [
          Color(0xFFF5F7FA),
          Color(0xFFE5E9F2),
          Colors.white,
        ];

  // Shadow colors - FIXED
  Color get shadowColor => _isDarkMode
      ? Colors.black.withOpacity(0.5)  // Stronger shadow in dark
      : Colors.black.withOpacity(0.08); // Subtle shadow in light

  BoxShadow get cardShadow => BoxShadow(
        color: _isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.black.withOpacity(0.08),
        blurRadius: _isDarkMode ? 12 : 8,
        offset: Offset(0, _isDarkMode ? 6 : 3),
      );

  // Border colors - FIXED
  Color get borderColor => _isDarkMode
      ? Color(0xFF334155)  // Visible border in dark mode
      : Color(0xFFE5E7EB); // Light border in light mode

  // Input field colors - FIXED
  Color get inputFillColor => _isDarkMode
      ? Color(0xFF0F172A)  // Very dark input bg
      : Color(0xFFF3F4F6); // Light gray input bg

  Color get inputBorderColor => _isDarkMode
      ? Color(0xFF475569)  // Medium border in dark
      : Color(0xFFD1D5DB); // Light border in light mode

  // Create full theme data
  ThemeData get themeData => ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: AppColors.accentBlue,
        scaffoldBackgroundColor: primaryBackground,
        cardColor: cardColor,
        colorScheme: ColorScheme(
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
          primary: AppColors.accentBlue,
          onPrimary: Colors.white,
          secondary: AppColors.accentCyan,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: surfaceColor,
          onSurface: primaryText,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: primaryText),
          displayMedium: TextStyle(color: primaryText),
          displaySmall: TextStyle(color: primaryText),
          bodyLarge: TextStyle(color: primaryText),
          bodyMedium: TextStyle(color: secondaryText),
          bodySmall: TextStyle(color: tertiaryText),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _isDarkMode ? AppColors.secondary : AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 2,
          shadowColor: shadowColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          
          filled: true,
          fillColor: inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
          ),
        ),
      );
}