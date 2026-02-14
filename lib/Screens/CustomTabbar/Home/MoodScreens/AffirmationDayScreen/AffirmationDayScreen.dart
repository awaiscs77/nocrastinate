import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/TipScreens/TipDayScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../AppData/Affirmation/AffirmationData.dart';
import '../../../../../AppData/Affirmation/AffirmationDataDE.dart';
import '../../../../../AppData/Affirmation/AffirmationDataES.dart';
import '../../../../../AppData/Affirmation/AffirmationDataFR.dart';
import '../../../../../AppData/Affirmation/AffirmationDataRU.dart';
import '../../../../../Manager/AffirmationManager.dart';

class AffirmationDayScreen extends StatefulWidget {
  const AffirmationDayScreen({Key? key}) : super(key: key);

  @override
  _AffirmationDayScreenState createState() => _AffirmationDayScreenState();
}

class _AffirmationDayScreenState extends State<AffirmationDayScreen> {
  String selectedCategory = "Strength and Resilience";
  String currentAffirmation = "";
  bool isLoading = true;
  bool showDropdown = false;
  String currentLanguage = 'en';
  bool _isInitialized = false;

  final AffirmationManager _affirmationManager = AffirmationManager();
  final ScreenshotController _screenshotController = ScreenshotController();

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
    _initializeAffirmationManager();
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

      // Load affirmation after language is set
      _loadAffirmationOfTheDay();
    }
  }

  Future<void> _initializeAffirmationManager() async {
    await _affirmationManager.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Get the appropriate affirmation data class based on language
  dynamic _getAffirmationDataClass() {
    switch (currentLanguage) {
      case 'de':
        return AffirmationDataDE;
      case 'es':
        return AffirmationDataES;
      case 'fr':
        return AffirmationDataFR;
      case 'ru':
        return AffirmationDataRU;
      case 'en':
      default:
        return AffirmationData;
    }
  }

  // Share functionality
  Future<void> _shareAffirmation() async {
    try {
      final Uint8List? image = await _screenshotController.capture();

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/affirmation_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);

        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out this affirmation!',
        );
      }
    } catch (e) {
      print('Error sharing affirmation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share affirmation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDonePressed() async {
    final success = await _affirmationManager.saveAffirmationView(
      affirmationContent: currentAffirmation,
      category: selectedCategory,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_affirmationManager.getStreakMessage()),
            backgroundColor: context.primaryTextColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _loadAffirmationOfTheDay() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    // Use language-specific key for saved category
    final savedCategory = prefs.getString('selected_affirmation_category_$currentLanguage') ?? selectedCategory;
    final lastAffirmationDate = prefs.getString('last_affirmation_date_${savedCategory}_$currentLanguage') ?? '';

    setState(() {
      selectedCategory = savedCategory;
    });

    String affirmationForToday;

    if (lastAffirmationDate != todayString) {
      affirmationForToday = _generateDailyAffirmation(selectedCategory, today);
      await prefs.setString('affirmation_of_day_${savedCategory}_${todayString}_$currentLanguage', affirmationForToday);
      await prefs.setString('last_affirmation_date_${savedCategory}_$currentLanguage', todayString);
    } else {
      affirmationForToday = prefs.getString('affirmation_of_day_${savedCategory}_${todayString}_$currentLanguage') ??
          _generateDailyAffirmation(selectedCategory, today);
    }

    setState(() {
      currentAffirmation = affirmationForToday;
      isLoading = false;
    });
  }

  String _generateDailyAffirmation(String categoryName, DateTime date) {
    Category? category;

    // Call static method directly on the class
    switch (currentLanguage) {
      case 'de':
        category = AffirmationDataDE.getCategoryByName(categoryName);
        break;
      case 'es':
        category = AffirmationDataES.getCategoryByName(categoryName);
        break;
      case 'fr':
        category = AffirmationDataFR.getCategoryByName(categoryName);
        break;
      case 'ru':
        category = AffirmationDataRU.getCategoryByName(categoryName);
        break;
      case 'en':
      default:
        category = AffirmationData.getCategoryByName(categoryName);
        break;
    }

    if (category == null || category.affirmation.isEmpty) {
      return _getDefaultAffirmation();
    }

    final daysSinceEpoch = date.difference(DateTime(2024, 1, 1)).inDays;
    final random = Random(daysSinceEpoch + categoryName.hashCode);
    final affirmationIndex = random.nextInt(category.affirmation.length);

    return category.affirmation[affirmationIndex];
  }

  String _getDefaultAffirmation() {
    switch (currentLanguage) {
      case 'de':
      // Get a random affirmation from German data
        final categories = AffirmationDataDE.getAllCategories();
        if (categories.isNotEmpty && categories.first.affirmation.isNotEmpty) {
          return categories.first.affirmation.first;
        }
        return "Bleib positiv und wachse weiter!";
      case 'es':
      // Get a random affirmation from Spanish data
        final categories = AffirmationDataES.getAllCategories();
        if (categories.isNotEmpty && categories.first.affirmation.isNotEmpty) {
          return categories.first.affirmation.first;
        }
        return "¡Mantente positivo y sigue creciendo!";
      case 'fr':
      // Get a random affirmation from French data
        final categories = AffirmationDataFR.getAllCategories();
        if (categories.isNotEmpty && categories.first.affirmation.isNotEmpty) {
          return categories.first.affirmation.first;
        }
        return "Restez positif et continuez à grandir !";
      case 'ru':
      // Get a random affirmation from Russian data
        final categories = AffirmationDataRU.getAllCategories();
        if (categories.isNotEmpty && categories.first.affirmation.isNotEmpty) {
          return categories.first.affirmation.first;
        }
        return "Оставайтесь позитивными и продолжайте расти!";
      case 'en':
      default:
      // Get a random affirmation from English data
        final categories = AffirmationData.getAllCategories();
        if (categories.isNotEmpty && categories.first.affirmation.isNotEmpty) {
          return categories.first.affirmation.first;
        }
        return "Stay positive and keep growing!";
    }
  }

  Future<void> _onCategoryChanged(String newCategory) async {
    if (newCategory == selectedCategory) return;

    setState(() {
      selectedCategory = newCategory;
      showDropdown = false;
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_affirmation_category_$currentLanguage', newCategory);

    await _loadAffirmationOfTheDay();
  }

  Widget _buildDropdown() {
    List<Category> categories;

    // Call static method directly on the class
    switch (currentLanguage) {
      case 'de':
        categories = AffirmationDataDE.getAllCategories();
        break;
      case 'es':
        categories = AffirmationDataES.getAllCategories();
        break;
      case 'fr':
        categories = AffirmationDataFR.getAllCategories();
        break;
      case 'ru':
        categories = AffirmationDataRU.getAllCategories();
        break;
      case 'en':
      default:
        categories = AffirmationData.getAllCategories();
        break;
    }


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                showDropdown = !showDropdown;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(24),
                color: context.backgroundColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      selectedCategory,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    showDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: context.primaryTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (showDropdown)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category.name == selectedCategory;

                  return GestureDetector(
                    onTap: () => _onCategoryChanged(category.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primaryTextColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.primaryTextColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: context.primaryTextColor,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.backgroundColor,
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                context.isDarkMode
                    ? 'assets/svg/AffirmationDark.svg'
                    : 'assets/svg/Affirmation of the Day.svg',
                fit: BoxFit.cover,
              ),
            ),

            Column(
              children: [
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              context.isDarkMode
                                  ? 'assets/svg/BackBlack.svg'
                                  : 'assets/svg/WhiteRoundBGBack.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Affirmation of the Day'.tr(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 56),
                      ],
                    ),
                  ),
                ),

                _buildDropdown(),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: isLoading
                          ? CircularProgressIndicator(
                        color: context.primaryTextColor,
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentAffirmation,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: context.primaryTextColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 140),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 180,
              child: Center(
                child: GestureDetector(
                  onTap: _handleDonePressed,
                  child: Container(
                    width: 148,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? AppColors.darkPrimaryText
                          : AppColors.lightBlackSection,
                      borderRadius: BorderRadius.circular(55),
                    ),
                    child: Center(
                      child: Text(
                        'Done'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.isDarkMode
                              ? AppColors.darkBackground
                              : Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: context.isDarkMode ? context.cardBackgroundColor : context.blackSectionColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _shareAffirmation,
                        child: SvgPicture.asset(
                          context.isDarkMode
                              ? 'assets/svg/shareTip.svg'
                              : 'assets/svg/shareTip.svg',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle neutral action
                        },
                        child: SvgPicture.asset(
                          context.isDarkMode
                              ? 'assets/svg/neutral.svg'
                              : 'assets/svg/neutral.svg',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle like action
                        },
                        child: SvgPicture.asset(
                          context.isDarkMode
                              ? 'assets/svg/like.svg'
                              : 'assets/svg/like.svg',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}