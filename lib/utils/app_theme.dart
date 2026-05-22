import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Cores Premium (Rosé Gold, Nude, Branco Suave, Marrom Sofisticado)
  static const Color primary = Color(0xFFC49363); // Rosé Gold / Bronze
  static const Color secondary = Color(0xFFE5C1A7); // Nude Claro
  static const Color accent = Color(0xFFD9B99B); // Bege Elegante
  static const Color background = Color(0xFFFDF8F5); // Branco Suave / Nude
  static const Color textDark = Color(0xFF4A3728); // Marrom Sofisticado
  static const Color textLight = Color(0xFF8C7365); // Marrom Claro
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB04D3F); // Terracota Elegante

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textDark,
        background: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          color: textLight,
          height: 1.5,
        ),
        labelSmall: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textLight,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark, size: 22),
        titleTextStyle: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', letterSpacing: -0.5),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primary.withValues(alpha: 0.08), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textLight,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: textLight.withOpacity(0.7), size: 24);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
          textStyle: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.montserrat(
          color: textLight.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
    );
  }

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: textDark.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: textDark.withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: textDark.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
