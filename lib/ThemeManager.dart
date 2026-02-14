import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced Theme Manager Class
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeManager() {
    _loadTheme();
  }

  // Load saved theme preference with proper error handling
  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
      _isDarkMode = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle between light and dark theme with proper error handling
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
      // Revert the change if saving failed
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  // Set specific theme with proper error handling
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return; // No change needed

    try {
      _isDarkMode = isDark;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
      // Revert the change if saving failed
      _isDarkMode = !isDark;
      notifyListeners();
    }
  }

  // Clear theme preference (optional utility method)
  Future<void> clearThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      _isDarkMode = false;
      notifyListeners();
    } catch (e) {
      print('Error clearing theme preference: $e');
    }
  }
}

// App Colors Class (same as your original)
class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF3F3F3);
  static const Color lightSecondaryBackground = Colors.white;
  static const Color lightCardBackground = Colors.white;
  static const Color lightPrimaryText = Color(0xFF1F1F1F);
  static const Color lightSecondaryText = Colors.grey;
  static const Color lightBorder = Color(0xFF1F1F1F73);
  static const Color lightBlackSection = Colors.black;

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1F1F1F);
  static const Color darkSecondaryBackground = Color(0xFF303030);
  static const Color darkCardBackground = Color(0xFF303030);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color darkBorder = Color(0xFF505050);
  static const Color darkBlackSection = Color(0xFF1F1F1F);

  // Common Colors (unchanged in both themes)
  static const Color accent = Color(0xFF007AFF);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
}

// Improved App Theme Class
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: AppColors.lightBlackSection,
    fontFamily: 'Poppins',

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBlackSection,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: const CardThemeData(
      color: AppColors.lightCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.lightPrimaryText,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.lightPrimaryText,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.lightPrimaryText,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.lightPrimaryText,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.lightPrimaryText,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.lightPrimaryText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: AppColors.lightPrimaryText,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        color: AppColors.lightSecondaryText,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.lightPrimaryText,
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.grey.shade300;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF1D79ED);
        }
        return Colors.grey.shade400;
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: AppColors.darkBlackSection,
    fontFamily: 'Poppins',

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBlackSection,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: const CardThemeData(
      color: AppColors.darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.darkPrimaryText,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.darkPrimaryText,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkPrimaryText,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.darkPrimaryText,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.darkPrimaryText,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.darkPrimaryText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: AppColors.darkPrimaryText,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        color: AppColors.darkSecondaryText,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.darkPrimaryText,
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.grey.shade600;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF1D79ED);
        }
        return Colors.grey.shade700;
      }),
    ),
  );
}

// Extension for easy access to current theme colors (same as your original)
extension ThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor => isDarkMode
      ? AppColors.darkBackground
      : AppColors.lightBackground;

  Color get secondaryBackgroundColor => isDarkMode
      ? AppColors.darkSecondaryBackground
      : AppColors.lightSecondaryBackground;

  Color get cardBackgroundColor => isDarkMode
      ? AppColors.darkCardBackground
      : AppColors.lightCardBackground;

  Color get primaryTextColor => isDarkMode
      ? AppColors.darkPrimaryText
      : AppColors.lightPrimaryText;

  Color get secondaryTextColor => isDarkMode
      ? AppColors.darkSecondaryText
      : AppColors.lightSecondaryText;

  Color get borderColor => isDarkMode
      ? AppColors.darkBorder
      : AppColors.lightBorder;

  Color get blackSectionColor => isDarkMode
      ? AppColors.darkBlackSection
      : AppColors.lightBlackSection;
}

// Enhanced Custom Widget for themed containers
class ThemedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool useSecondaryBackground;
  final VoidCallback? onTap;

  const ThemedContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.useSecondaryBackground = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: useSecondaryBackground
            ? context.secondaryBackgroundColor
            : context.isDarkMode ? context.backgroundColor : context.cardBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        child: container,
      );
    }

    return container;
  }
}

// Dark Mode Toggle Widget
class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return ThemedContainer(
          height: 55,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                themeManager.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: context.primaryTextColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Dark Mode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: themeManager.isDarkMode,
                onChanged: themeManager.isInitialized
                    ? (value) => themeManager.toggleTheme()
                    : null, // Disable until initialized
              ),
            ],
          ),
        );
      },
    );
  }
}