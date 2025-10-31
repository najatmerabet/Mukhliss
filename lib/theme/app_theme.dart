import  'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter_material;
typedef flutter_ThemeMode = flutter_material.ThemeMode;
class AppColors {
  // static const Color primary = Color(0xFF765EFF);
  // static const Color secondary = Color(0xFFC4BAFF);
  // static const Color white = Colors.white;
   static const Color purpleDark = Color.fromARGB(255, 105, 96, 231);
  // static const Color error = Colors.red;
  // static const Color black=Colors.black;

  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const surface = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF8B5CF6);
  static const Color lightSurface = Color(0xFFFAFAFC);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
   static const Color lightWhite = Colors.white;
static const Color lightGrey50 = Color(0xFFFAFAFA);
  static const Color lightPurpleDark = Color.fromARGB(255, 105, 96, 231);
 

  // Dark Theme Colors
  static const Color darkPrimary = Color.fromARGB(255, 13, 13, 14);       // Version sombre de 0xFF765EFF
  static const Color darkSecondary = Color.fromARGB(255, 0, 0, 0);     // Version sombre de 0xFFC4BAFF
  static const Color darkSurface = Colors.black;  static const Color darkBackground = Color(0xFF111827);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkWhite = Color.fromARGB(255, 247, 250, 252); // Gris très clair pour dark
  static const Color darkGrey50 = Color.fromARGB(255, 191, 194, 196); // Gris plus foncé pour dark
  static const Color darkPurpleDark = Color.fromARGB(255, 19, 15, 78);
  static const Color amber= Colors.amber;

    // Gradients
  static const List<Color> lightGradient = [
  AppColors.lightWhite,
                    AppColors.lightGrey50,
                    AppColors.lightPurpleDark,
  ];
  
  static const List<Color> darkGradient = [
   Colors.black,
   Color.fromARGB(255, 19, 15, 78),

  ];

    static const List<Color> darkGradientscreen = [
    AppColors.darkWhite,
                    AppColors.darkGrey50,
                    AppColors.darkPurpleDark,

  ];

   // Thème clair
    //  Color.fromARGB(255, 63, 45, 221),
    // Color.fromARGB(255, 141, 120, 248),
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    
    // Couleurs principales
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFFFAFAFC),
      background: Color(0xFFF8FAFC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
      error: error,
      onError: Colors.white,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),

    // Cards
    // cardTheme: CardTheme(
    //   color: Colors.white,
    //   elevation: 4,
    //   shadowColor: Colors.black.withOpacity(0.05),
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //   ),
    // ),

    // Boutons élevés
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Boutons avec contour
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // ListTiles
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primary;
        }
        return Colors.grey.shade400;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primary.withOpacity(0.3);
        }
        return Colors.grey.shade300;
      }),
    ),
  );

  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    
    // Couleurs principales
    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 24, 24, 31),
      secondary: Color.fromARGB(255, 18, 17, 19),
      surface: Color(0xFF1F2937),
      background: Color(0xFF111827),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF9FAFB),
      onBackground: Color(0xFFF9FAFB),
      error: error,
      onError: Colors.white,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2937),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 20, 20, 20),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),

    // Cards
    // cardTheme: CardTheme(
    //   color: const Color(0xFF1F2937),
    //   elevation: 4,
    //   shadowColor: Colors.black.withOpacity(0.3),
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //   ),
    // ),

    // Boutons élevés
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Boutons avec contour
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4B5563)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // ListTiles
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primary;
        }
        return Colors.grey.shade600;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primary.withOpacity(0.3);
        }
        return Colors.grey.shade700;
      }),
    ),
  );
}
