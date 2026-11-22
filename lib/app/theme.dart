import 'package:material_ui/material_ui.dart';

class GenSolarTheme {
  static const brandGreen = Color(0xFF126B4A);
  static const brandDeep = Color(0xFF0A392A);
  static const brandMint = Color(0xFFE3F4EB);
  static const ink = Color(0xFF15241D);
  static const canvas = Color(0xFFF4F7F5);
  static const line = Color(0xFFE4EBE6);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: Brightness.light,
      surface: Colors.white,
    ).copyWith(
      primary: brandGreen,
      onPrimary: Colors.white,
      primaryContainer: brandMint,
      onPrimaryContainer: brandDeep,
      secondary: const Color(0xFF287E91),
      tertiary: const Color(0xFFB8792B),
      surface: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8FAF8),
      surfaceContainer: const Color(0xFFF0F5F1),
      outlineVariant: line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarThemeData(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: const Color(0xFFFBFCFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: brandGreen, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: brandMint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? brandDeep : const Color(0xFF66756C),
        )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF2F6F3),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
        headlineLarge: const TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: ink),
        headlineMedium: const TextStyle(fontSize: 28, height: 1.14, fontWeight: FontWeight.w800, letterSpacing: -.7, color: ink),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
        titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink),
        bodyMedium: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF526259)),
      ),
    );
  }
}
