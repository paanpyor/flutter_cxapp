import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- MODERN SAAS / RESTAURANT TECH PALETTE ---
  
  // Brand Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo 600: Trustworthy & Modern
  static const Color secondary = Color(0xFF8B5CF6); // Violet 500: Adds depth for gradients
  static const Color accent = Color(0xFFF97316); // Orange 500: High energy for CTAs
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald: Growth/Profit
  static const Color warning = Color(0xFFF59E0B); // Amber: Attention needed
  static const Color error = Color(0xFFEF4444);   // Red: Critical issues
  static const Color info = Color(0xFF3B82F6);    // Blue: Neutral info

  // Surface Colors (Eye-comfort optimized)
  static const Color background = Color(0xFFF8FAFC); // Slate 50 (Soft grey-ish white)
  static const Color surface = Color(0xFFFFFFFF);     // Pure White
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (Near black for high readability)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 (Soft grey for labels)

  // --- METRIC SPECIFIC COLORS (For Charts) ---
  // Distinct colors to easily differentiate CSAT, CES, and NPS in charts
  static const Color csatColor = Color(0xFFF59E0B); // Amber (Satisfaction/Warmth)
  static const Color cesColor = Color(0xFF06B6D4);  // Cyan (Ease/Cool)
  static const Color npsColor = Color(0xFF10B981);  // Emerald (Loyalty/Good)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: Colors.white, // Ensures text on primary buttons is white
        onSurface: textPrimary,
      ),
      
      // Typography
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.w800, 
          color: textPrimary, 
          letterSpacing: -0.5
        ),
        headlineMedium: const TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w700, 
          color: textPrimary
        ),
        bodyLarge: const TextStyle(
          fontSize: 16, 
          color: textPrimary, 
          height: 1.5 // Better line height for readability
        ),
        bodyMedium: const TextStyle(
          fontSize: 14, 
          color: textSecondary
        ),
        labelLarge: const TextStyle( // For Buttons
          fontSize: 14, 
          fontWeight: FontWeight.w600
        ),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary, 
          fontSize: 18, 
          fontWeight: FontWeight.w600
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0, 
        // Use a soft, diffused shadow instead of a harsh one
        shadowColor: const Color(0xFF0F172A).withOpacity(0.05), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Floating Action Button
      floatingActionButtonTheme:  FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          // Add a subtle shadow on click
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) return secondary.withOpacity(0.3);
              return null;
            },
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 20,
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}