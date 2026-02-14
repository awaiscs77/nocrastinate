import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../ThemeManager.dart';
import '../Settings/LanguageSelectionScreen.dart';
import 'package:easy_localization/easy_localization.dart';

// Language data structure
class QuoteLanguageData {
  final String code;
  final String name;
  final Map<String, List<String>> categories;

  QuoteLanguageData({
    required this.code,
    required this.name,
    required this.categories,
  });

  static final Map<String, QuoteLanguageData> languages = {
    'en': QuoteLanguageData(
      code: 'en',
      name: 'English',
      categories: {
        'Personal Growth': [
          'Be Yourself',
          'Gratitude',
          'Positive Thinking',
          'Self Love'
        ],
        'Work & Productivity': [
          'Business & Money',
          'Leadership',
          'Success'
        ],
        'Fitness & Habits': [
          'Fitness',
          'Habits'
        ],
        'Hard Times': [
          'Overcome Fear',
          'Resilience',
          'Uncertainty',
          'Loneliness',
          'Dealing with Change'
        ],
        'Relationships': [
          'Love',
          'Family',
          'Being Single',
          'Breakup'
        ],
        'Philosophy': [
          'Buddhism',
          'Stoicism'
        ],
      },
    ),
    'es': QuoteLanguageData(
      code: 'es',
      name: 'Español',
      categories: {
        'Crecimiento Personal': [
          'Sé Tú Mismo',
          'Gratitud',
          'Pensamiento Positivo',
          'Amor Propio'
        ],
        'Trabajo y Productividad': [
          'Negocios y Dinero',
          'Liderazgo',
          'Éxito'
        ],
        'Fitness y Hábitos': [
          'Fitness',
          'Hábitos'
        ],
        'Tiempos Difíciles': [
          'Superar el Miedo',
          'Resiliencia',
          'Incertidumbre',
          'Soledad',
          'Lidiar con el Cambio'
        ],
        'Relaciones': [
          'Amor',
          'Familia',
          'Estar Soltero',
          'Ruptura'
        ],
        'Filosofía': [
          'Budismo',
          'Estoicismo'
        ],
      },
    ),
    'fr': QuoteLanguageData(
      code: 'fr',
      name: 'Français',
      categories: {
        'Développement Personnel': [
          'Être Soi-Même',
          'Gratitude',
          'Pensée Positive',
          'Amour de Soi'
        ],
        'Travail et Productivité': [
          'Affaires et Argent',
          'Leadership',
          'Succès'
        ],
        'Fitness et Habitudes': [
          'Forme Physique',
          'Habitudes'
        ],
        'Moments Difficiles': [
          'Surmonter la Peur',
          'Résilience',
          'Incertitude',
          'Solitude',
          'Faire Face au Changement'
        ],
        'Relations': [
          'Amour',
          'Famille',
          'Célibat',
          'Rupture'
        ],
        'Philosophie': [
          'Bouddhisme',
          'Stoïcisme'
        ],
      },
    ),
    'de': QuoteLanguageData(
      code: 'de',
      name: 'Deutsch',
      categories: {
        'Persönliches Wachstum': [
          'Sei Du Selbst',
          'Dankbarkeit',
          'Positives Denken',
          'Selbstliebe'
        ],
        'Arbeit und Produktivität': [
          'Geschäft und Geld',
          'Führung',
          'Erfolg'
        ],
        'Fitness und Gewohnheiten': [
          'Fitness',
          'Gewohnheiten'
        ],
        'Schwere Zeiten': [
          'Überwindung der Angst',
          'Resilienz',
          'Ungewissheit',
          'Einsamkeit',
          'Bewältigung von Veränderungen'
        ],
        'Beziehung': [
          'Liebe',
          'Familie',
          'Ein Leben ohne Beziehung',
          'Trennung'
        ],
        'Philosophie': [
          'Buddhismus',
          'Stoizismus'
        ],
      },
    ),
    'ru': QuoteLanguageData(
      code: 'ru',
      name: 'Русский',
      categories: {
        'Личностный Рост': [
          'Будь Собой',
          'Благодарность',
          'Позитивное Мышление',
          'Любовь к Себе'
        ],
        'Работа и Продуктивность': [
          'Бизнес и Деньги',
          'Лидерство',
          'Успех'
        ],
        'Фитнес и Привычки': [
          'Фитнес',
          'Привычки'
        ],
        'Трудные Времена': [
          'Преодоление Страха',
          'Устойчивость',
          'Неопределенность',
          'Одиночество',
          'Справляться с Переменами'
        ],
        'Отношения': [
          'Любовь',
          'Семья',
          'Жизнь без Отношений',
          'Расставание'
        ],
        'Философия': [
          'Буддизм',
          'Стоицизм'
        ],
      },
    ),
  };
}

// QuoteCategoryScreen with language support
class QuoteCategoryScreen extends StatefulWidget {
  const QuoteCategoryScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<QuoteCategoryScreen> createState() => _QuoteCategoryScreenState();
}

class _QuoteCategoryScreenState extends State<QuoteCategoryScreen> {
  String selectedType = 'categories';
  Set<String> selectedCategories = {};
  String currentLanguage = 'en';
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Get current locale from context
      final currentLocale = context.locale;
      languageMap.forEach((key, value) {
        if (value.languageCode == currentLocale.languageCode) {
          setState(() {
            currentLanguage = value.languageCode;
          });
        }
      });

      // Pre-select first category
      final langData = QuoteLanguageData.languages[currentLanguage];
      if (langData != null && langData.categories.isNotEmpty) {
        setState(() {
          selectedCategories.add(langData.categories.values.first.first);
        });
      }
    }
  }

  void toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        if (selectedCategories.length > 1) {
          selectedCategories.remove(category);
        }
      } else {
        selectedCategories.add(category);
      }
    });
  }

  void onLanguageChanged(String newLanguage) {
    setState(() {
      currentLanguage = newLanguage;
      selectedCategories.clear();
      // Auto-select first category in new language
      final langData = QuoteLanguageData.languages[currentLanguage];
      if (langData != null && langData.categories.isNotEmpty) {
        selectedCategories.add(langData.categories.values.first.first);
      }
    });
  }

  void applySelection() {
    // Return both categories and language to the previous screen
    Navigator.of(context).pop({
      'categories': selectedCategories,
      'language': currentLanguage,
    });
  }

  Widget buildCategoryButton(String category, bool isSelected, bool isDarkMode) {
    return GestureDetector(
      onTap: () => toggleCategory(category),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 140,
        ),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
              width: 1.5)
              : Border.all(
              color: isDarkMode
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            category,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  Widget buildCategoriesGrid(Map<String, List<String>> categories, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDarkMode
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: entry.value.map((category) {
                  return buildCategoryButton(
                    category,
                    selectedCategories.contains(category),
                    isDarkMode,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDarkMode = themeManager.isDarkMode;
        final langData = QuoteLanguageData.languages[currentLanguage]!;

        return Scaffold(
          backgroundColor: isDarkMode
              ? AppColors.darkBackground.withOpacity(0.8)
              : Colors.black.withOpacity(0.5),
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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
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

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Topics'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDarkMode
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showQuoteLanguageScreen(
                                      context,
                                      currentLanguage,
                                      onLanguageChanged,
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/svg/language.svg',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: SvgPicture.asset(
                                    'assets/svg/cancel.svg',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: buildCategoriesGrid(langData.categories, isDarkMode),
                        ),
                      ),

                      // Apply button
                      Padding(
                        padding:  EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: applySelection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                              foregroundColor: isDarkMode
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply' +  '(${selectedCategories.length}' + 'selected'.tr() + ')',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
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

// Helper function to show the category screen
Future<Map<String, dynamic>?> showQuoteCategoryScreen(BuildContext context) async {
  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuoteCategoryScreen(),
  );
}

void showQuoteLanguageScreen(
    BuildContext context,
    String currentLanguage,
    Function(String) onLanguageChanged,
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuoteLanguageScreen(
      currentLanguage: currentLanguage,
      onLanguageChanged: onLanguageChanged,
    ),
  );
}

// QuoteLanguageScreen widget (you'll need to create this if it doesn't exist)
class QuoteLanguageScreen extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const QuoteLanguageScreen({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDarkMode = themeManager.isDarkMode;

        return Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
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
              ),

              const SizedBox(height: 20),

              // Language options
              ...QuoteLanguageData.languages.entries.map((entry) {
                final isSelected = entry.key == currentLanguage;
                return ListTile(
                  title: Text(
                    entry.value.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDarkMode
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                    Icons.check,
                    color: isDarkMode
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  )
                      : null,
                  onTap: () {
                    onLanguageChanged(entry.key);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}