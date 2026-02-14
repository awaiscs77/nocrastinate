import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:provider/provider.dart';
import '../../../ThemeManager.dart';
import '../Quote/QuoteCategoryScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class QuoteLanguageScreen extends StatefulWidget {
  const QuoteLanguageScreen({Key? key}) : super(key: key);

  @override
  State<QuoteLanguageScreen> createState() => _QuoteLanguageScreenState();
}

class _QuoteLanguageScreenState extends State<QuoteLanguageScreen> {
  String selectedLanguage = 'English';
  bool _isInitialized = false;

  final Map<String, Locale> languageMap = {
    'English': Locale('en', 'US'),
    'Spanish': Locale('es', 'ES'),
    'French': Locale('fr', 'FR'),
    'Russian': Locale('ru', 'RU'),
    'German': Locale('de', 'DE'),
  };

  @override
  void initState() {
    super.initState();
    // Don't access context.locale here - it's too early
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize only once when dependencies are available
    if (!_isInitialized) {
      _isInitialized = true;
      final currentLocale = context.locale;
      languageMap.forEach((key, value) {
        if (value.languageCode == currentLocale.languageCode) {
          setState(() {
            selectedLanguage = key;
          });
        }
      });
    }
  }

  void selectLanguage(String language) {
    setState(() {
      selectedLanguage = language;
    });
  }

  Widget buildLanguageButton(String language, bool isDarkMode) {
    bool isSelected = selectedLanguage == language;
    String displayName = language.tr();

    return GestureDetector(
      onTap: () => selectLanguage(language),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 110,
        ),
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
              ? AppColors.darkBorder.withOpacity(0.3)
              : AppColors.lightBorder.withOpacity(0.1))
              : (isDarkMode
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFE9ECEF)),
          border: isSelected
              ? Border.all(
              color: isDarkMode
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              width: 1
          )
              : Border.all(
              color: isDarkMode
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 0.5
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            displayName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isDarkMode
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDarkMode = themeManager.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.black54,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkBackground
                        : AppColors.lightSecondaryBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Language'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDarkMode
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: SvgPicture.asset(
                                'assets/svg/cancel.svg',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: languageMap.keys.map((language) {
                            return buildLanguageButton(language, isDarkMode);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: 168,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (languageMap.containsKey(selectedLanguage)) {
                                await context.setLocale(languageMap[selectedLanguage]!);
                              }
                              Navigator.of(context).pop();
                              print('Selected language: $selectedLanguage');
                              print('Locale changed to: ${languageMap[selectedLanguage]}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                              foregroundColor: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightSecondaryBackground,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(55),
                              ),
                            ),
                            child: Text(
                              'Done'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDarkMode
                                    ? AppColors.darkBackground
                                    : AppColors.lightSecondaryBackground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// Helper functions
void showQuoteCategoryScreen(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuoteCategoryScreen(),
  );
}

void showLanguageScreen(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuoteLanguageScreen(),
  );
}

// Optional: Theme Toggle Widget for testing
class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return FloatingActionButton(
          onPressed: () => themeManager.toggleTheme(),
          backgroundColor: themeManager.isDarkMode
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
          child: Icon(
            themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: themeManager.isDarkMode
                ? AppColors.darkBackground
                : AppColors.lightSecondaryBackground,
          ),
        );
      },
    );
  }
}