import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../AppData/Quotes/QuotesData.dart';
import '../../../AppData/Quotes/QuotesDataES.dart';
import '../../../AppData/Quotes/QuotesDataFR.dart';
import '../../../ThemeManager.dart';
import 'QuoteCategoryScreen.dart';
import '../Settings/LanguageSelectionScreen.dart' hide showQuoteCategoryScreen;

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({Key? key}) : super(key: key);

  @override
  _QuotesScreenState createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  String selectedLanguage = 'en';
  Set<String> selectedCategories = {};  // Changed: Start with empty set
  List<String> allQuotes = [];
  int currentQuoteIndex = 0;
  bool showDropdown = false;
  bool _isInitialized = false;  // Added: Track initialization
  late PageController _pageController;
  final ScreenshotController _screenshotController = ScreenshotController();

  // Map English categories to data source keys
  final Map<String, String> categoryToKeyMap = {
    // English
    'Be Yourself': 'be_yourself',
    'Gratitude': 'gratitude',
    'Positive Thinking': 'positive_thinking',
    'Self Love': 'self_love',
    'Business & Money': 'business_money',
    'Leadership': 'leadership',
    'Success': 'success',
    'Fitness': 'fitness',
    'Habits': 'habits',
    'Overcome Fear': 'overcome_fear',
    'Resilience': 'resilience',
    'Uncertainty': 'uncertainty',
    'Loneliness': 'loneliness',
    'Dealing with Change': 'change',
    'Love': 'love',
    'Family': 'family',
    'Being Single': 'being_single',
    'Breakup': 'breakup',
    'Buddhism': 'buddhism',
    'Stoicism': 'stoicism',

    // Spanish
    'Sé Tú Mismo': 'be_yourself',
    'Gratitud': 'gratitude',
    'Pensamiento Positivo': 'positive_thinking',
    'Amor Propio': 'self_love',
    'Negocios y Dinero': 'business_money',
    'Liderazgo': 'leadership',
    'Éxito': 'success',
    'Hábitos': 'habits',
    'Superar el Miedo': 'overcome_fear',
    'Resiliencia': 'resilience',
    'Incertidumbre': 'uncertainty',
    'Soledad': 'loneliness',
    'Lidiar con el Cambio': 'change',
    'Amor': 'love',
    'Familia': 'family',
    'Estar Soltero': 'being_single',
    'Ruptura': 'breakup',
    'Budismo': 'buddhism',
    'Estoicismo': 'stoicism',

    // French
    'Être Soi-Même': 'be_yourself',
    'Pensée Positive': 'positive_thinking',
    'Amour de Soi': 'self_love',
    'Affaires et Argent': 'business_money',
    'Succès': 'success',
    'Forme Physique': 'fitness',
    'Habitudes': 'habits',
    'Surmonter la Peur': 'overcome_fear',
    'Résilience': 'resilience',
    'Incertitude': 'uncertainty',
    'Solitude': 'loneliness',
    'Faire Face au Changement': 'change',
    'Amour': 'love',
    'Famille': 'family',
    'Célibat': 'being_single',
    'Rupture': 'breakup',
    'Bouddhisme': 'buddhism',
    'Stoïcisme': 'stoicism',

    // German
    'Sei Du Selbst': 'be_yourself',
    'Dankbarkeit': 'gratitude',
    'Positives Denken': 'positive_thinking',
    'Selbstliebe': 'self_love',
    'Geschäft und Geld': 'business_money',
    'Führung': 'leadership',
    'Erfolg': 'success',
    'Gewohnheiten': 'habits',
    'Überwindung der Angst': 'overcome_fear',
    'Ungewissheit': 'uncertainty',
    'Einsamkeit': 'loneliness',
    'Bewältigung von Veränderungen': 'change',
    'Liebe': 'love',
    'Familie': 'family',
    'Ein Leben ohne Beziehung': 'being_single',
    'Trennung': 'breakup',
    'Buddhismus': 'buddhism',
    'Stoizismus': 'stoicism',

    // Russian
    'Будь Собой': 'be_yourself',
    'Благодарность': 'gratitude',
    'Позитивное Мышление': 'positive_thinking',
    'Любовь к Себе': 'self_love',
    'Бизнес и Деньги': 'business_money',
    'Лидерство': 'leadership',
    'Успех': 'success',
    'Привычки': 'habits',
    'Преодоление Страха': 'overcome_fear',
    'Устойчивость': 'resilience',
    'Неопределенность': 'uncertainty',
    'Одиночество': 'loneliness',
    'Справляться с Переменами': 'change',
    'Любовь': 'love',
    'Семья': 'family',
    'Жизнь без Отношений': 'being_single',
    'Расставание': 'breakup',
    'Буддизм': 'buddhism',
    'Стоицизм': 'stoicism',
  };

  // Added: Get default category based on language
  String _getDefaultCategoryForLanguage(String lang) {
    switch (lang) {
      case 'es':
        return 'Sé Tú Mismo';
      case 'fr':
        return 'Être Soi-Même';
      case 'de':
        return 'Sei Du Selbst';
      case 'ru':
        return 'Будь Собой';
      default:
        return 'Be Yourself';
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Removed: Don't load quotes here, wait for didChangeDependencies
  }

  // Added: Initialize after context is available
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Get current locale from context
      final currentLocale = context.locale;
      selectedLanguage = currentLocale.languageCode;

      // Set default category based on current language
      String defaultCategory = _getDefaultCategoryForLanguage(selectedLanguage);
      selectedCategories = {defaultCategory};

      // Load quotes with the correct language
      _loadQuotesFromSelectedCategories();
    }
  }

  // Detect language from selected categories
  void _updateLanguageFromCategories() {
    if (selectedCategories.isEmpty) return;

    String firstCategory = selectedCategories.first;

    // Spanish categories
    if (['Sé Tú Mismo', 'Gratitud', 'Pensamiento Positivo', 'Amor Propio',
      'Negocios y Dinero', 'Liderazgo', 'Éxito', 'Hábitos',
      'Superar el Miedo', 'Resiliencia', 'Incertidumbre', 'Soledad',
      'Lidiar con el Cambio', 'Amor', 'Familia', 'Estar Soltero',
      'Ruptura', 'Budismo', 'Estoicismo'].contains(firstCategory)) {
      selectedLanguage = 'es';
    }
    // French categories
    else if (['Être Soi-Même', 'Pensée Positive', 'Amour de Soi',
      'Affaires et Argent', 'Succès', 'Forme Physique', 'Habitudes',
      'Surmonter la Peur', 'Résilience', 'Incertitude', 'Solitude',
      'Faire Face au Changement', 'Amour', 'Famille', 'Célibat',
      'Rupture', 'Bouddhisme', 'Stoïcisme'].contains(firstCategory)) {
      selectedLanguage = 'fr';
    }
    // German categories
    else if (['Sei Du Selbst', 'Dankbarkeit', 'Positives Denken', 'Selbstliebe',
      'Geschäft und Geld', 'Führung', 'Erfolg', 'Gewohnheiten',
      'Überwindung der Angst', 'Ungewissheit', 'Einsamkeit',
      'Bewältigung von Veränderungen', 'Liebe', 'Familie',
      'Ein Leben ohne Beziehung', 'Trennung', 'Buddhismus',
      'Stoizismus'].contains(firstCategory)) {
      selectedLanguage = 'de';
    }
    // Russian categories
    else if (['Будь Собой', 'Благодарность', 'Позитивное Мышление', 'Любовь к Себе',
      'Бизнес и Деньги', 'Лидерство', 'Успех', 'Привычки',
      'Преодоление Страха', 'Устойчивость', 'Неопределенность', 'Одиночество',
      'Справляться с Переменами', 'Любовь', 'Семья',
      'Жизнь без Отношений', 'Расставание', 'Буддизм',
      'Стоицизм'].contains(firstCategory)) {
      selectedLanguage = 'ru';
    }
    // Default to English
    else {
      selectedLanguage = 'en';
    }
  }

  void _loadQuotesFromSelectedCategories() {
    // Update language based on selected categories
    _updateLanguageFromCategories();

    List<String> quotes = [];

    for (String category in selectedCategories) {
      quotes.addAll(_getQuotesForCategory(category));
    }

    quotes.shuffle();

    setState(() {
      allQuotes = quotes.isNotEmpty
          ? quotes
          : ['Each challenge I face sharpens my mind and strengthens my determination.'];
      currentQuoteIndex = 0;
    });
  }

  List<String> _getQuotesForCategory(String category) {
    final key = categoryToKeyMap[category];
    if (key == null) return [];

    // Get the appropriate data source based on language
    dynamic quotes;

    switch (selectedLanguage) {
      case 'es':
      // For Spanish, use QuotesDataES class
        switch (key) {
          case 'be_yourself':
            quotes = QuotesDataES.beYourselfQuotes;
            break;
          case 'gratitude':
            quotes = QuotesDataES.gratitudeQuotes;
            break;
          case 'positive_thinking':
            quotes = QuotesDataES.positiveThinkingQuotes;
            break;
          case 'self_love':
            quotes = QuotesDataES.selfLoveQuotes;
            break;
          case 'business_money':
            quotes = QuotesDataES.businessMoneyQuotes;
            break;
          case 'leadership':
            quotes = QuotesDataES.leadershipQuotes;
            break;
          case 'success':
            quotes = QuotesDataES.successQuotes;
            break;
          case 'habits':
            quotes = QuotesDataES.habitQuotes;
            break;
          case 'overcome_fear':
            quotes = ['El miedo solo es tan profundo como la mente lo permite.'];
            break;
          case 'resilience':
            quotes = QuotesDataES.resilienceQuotes;
            break;
          case 'uncertainty':
            quotes = QuotesDataES.uncertaintyQuotes;
            break;
          case 'loneliness':
            quotes = QuotesDataES.lonelinessQuotes;
            break;
          case 'change':
            quotes = QuotesDataES.changeQuotes;
            break;
          case 'love':
            quotes = QuotesDataES.loveQuotes;
            break;
          case 'family':
            quotes = QuotesDataES.familyQuotes;
            break;
          case 'being_single':
            quotes = QuotesDataES.beingSingleQuotes;
            break;
          case 'breakup':
            quotes = QuotesDataES.breakupQuotes;
            break;
          case 'buddhism':
            quotes = QuotesDataES.buddhismQuotes;
            break;
          case 'stoicism':
            quotes = QuotesDataES.stoicismQuotes;
            break;
          default:
            quotes = null;
        }
        break;

      case 'fr':
      // For French, use QuotesDataFR class
        switch (key) {
          case 'be_yourself':
            quotes = QuotesDataFR.beYourselfQuotes;
            break;
          case 'positive_thinking':
            quotes = QuotesDataFR.positiveThinkingQuotes;
            break;
          case 'self_love':
            quotes = QuotesDataFR.selfLoveQuotes;
            break;
          case 'business_money':
            quotes = QuotesDataFR.businessMoneyQuotes;
            break;
          case 'success':
            quotes = QuotesDataFR.successQuotes;
            break;
          case 'fitness':
            quotes = QuotesDataFR.fitnessQuotes;
            break;
          case 'habits':
            quotes = QuotesDataFR.habitQuotes;
            break;
          case 'overcome_fear':
            quotes = ['La peur n\'est profonde que si l\'esprit le permet.'];
            break;
          case 'resilience':
            quotes = QuotesDataFR.resilienceQuotes;
            break;
          case 'uncertainty':
            quotes = QuotesDataFR.uncertaintyQuotes;
            break;
          case 'loneliness':
            quotes = QuotesDataFR.lonelinessQuotes;
            break;
          case 'change':
            quotes = QuotesDataFR.changeQuotes;
            break;
          case 'love':
            quotes = QuotesDataFR.loveQuotes;
            break;
          case 'family':
            quotes = QuotesDataFR.familyQuotes;
            break;
          case 'being_single':
            quotes = QuotesDataFR.beingSingleQuotes;
            break;
          case 'breakup':
            quotes = QuotesDataFR.breakupQuotes;
            break;
          case 'buddhism':
            quotes = QuotesDataFR.buddhismQuotes;
            break;
          case 'stoicism':
            quotes = QuotesDataFR.stoicismQuotes;
            break;
          default:
            quotes = null;
        }
        break;

      default:
      // For English, use QuotesData class
        switch (key) {
          case 'be_yourself':
            quotes = QuotesData.beYourselfQuotes;
            break;
          case 'gratitude':
            quotes = QuotesData.gratitudeQuotes;
            break;
          case 'positive_thinking':
            quotes = QuotesData.positiveThinkingQuotes;
            break;
          case 'self_love':
            quotes = QuotesData.selfLoveQuotes;
            break;
          case 'business_money':
            quotes = QuotesData.businessMoneyQuotes;
            break;
          case 'leadership':
            quotes = QuotesData.leadershipQuotes;
            break;
          case 'success':
            quotes = QuotesData.successQuotes;
            break;
          case 'fitness':
            quotes = QuotesData.fitnessQuotes;
            break;
          case 'habits':
            quotes = QuotesData.habitQuotes;
            break;
          case 'overcome_fear':
            quotes = QuotesData.fearQuotes;
            break;
          case 'resilience':
            quotes = QuotesData.resilienceQuotes;
            break;
          case 'uncertainty':
            quotes = QuotesData.uncertaintyQuotes;
            break;
          case 'loneliness':
            quotes = QuotesData.lonelinessQuotes;
            break;
          case 'change':
            quotes = QuotesData.changeQuotes;
            break;
          case 'love':
            quotes = QuotesData.loveQuotes;
            break;
          case 'family':
            quotes = QuotesData.familyQuotes;
            break;
          case 'being_single':
            quotes = QuotesData.beingSingleQuotes;
            break;
          case 'breakup':
            quotes = QuotesData.breakupQuotes;
            break;
          case 'buddhism':
            quotes = QuotesData.buddhismQuotes;
            break;
          case 'stoicism':
            quotes = QuotesData.stoicismQuotes;
            break;
          default:
            quotes = null;
        }
    }

    return quotes != null ? List<String>.from(quotes) : [];
  }

  Future<void> _shareQuote() async {
    try {
      final Uint8List? image = await _screenshotController.capture();

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);

        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out this inspiring quote!',
        );
      }
    } catch (e) {
      print('Error sharing quote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildQuotePage(String quote) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            isDarkMode
                ? 'assets/svg/Quotes.svg'
                : 'assets/svg/Affirmation of the Day.svg',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: allQuotes.length,
              onPageChanged: (index) {
                setState(() {
                  currentQuoteIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildQuotePage(allQuotes[index]);
              },
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: kToolbarHeight,
                  color: Colors.transparent,
                  child: Row(
                    children: [

                      Expanded(
                        child: Center(
                          child: Text(
                            'Quotes'.tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom left menu button
            Positioned(
              left: 16,
              bottom: 60,
              child: GestureDetector(
                onTap: () async {
                  final result = await showQuoteCategoryScreen(context);
                  if (result != null) {
                    // Handle the result from category screen
                    if (result is Map<String, dynamic>) {
                      setState(() {
                        if (result['categories'] != null) {
                          selectedCategories = result['categories'] as Set<String>;
                        }
                        if (result['language'] != null) {
                          selectedLanguage = result['language'] as String;
                        }
                        _loadQuotesFromSelectedCategories();
                      });
                    }
                  }
                },
                child: SvgPicture.asset('assets/svg/menu.svg'),
              ),
            ),

            // Bottom right share button
            Positioned(
              right: 16,
              bottom: 60,
              child: GestureDetector(
                onTap: _shareQuote,
                child: SvgPicture.asset('assets/svg/share.svg'),
              ),
            ),

            // Bottom center action buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (currentQuoteIndex < allQuotes.length - 1) {
                        _pageController.animateToPage(
                          currentQuoteIndex + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: SvgPicture.asset(
                      isDarkMode
                          ? 'assets/svg/dislike_dark.svg'
                          : 'assets/svg/netralQuote.svg',
                    ),
                  ),
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () {
                      // TODO: Add to favorites
                      if (currentQuoteIndex < allQuotes.length - 1) {
                        _pageController.animateToPage(
                          currentQuoteIndex + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: SvgPicture.asset(
                      isDarkMode
                          ? 'assets/svg/heart_dark.svg'
                          : 'assets/svg/liked.svg',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}