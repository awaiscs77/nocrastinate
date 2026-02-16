import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../AppData/Tips/TipDataRU.dart';
import '../../../../../AppData/Tips/TipsData.dart';
import '../../../../../AppData/Tips/TipsDataDE.dart';
import '../../../../../AppData/Tips/TipsDataES.dart';
import '../../../../../AppData/Tips/TipsDataFR.dart';
import '../../../../../Manager/TipsManager.dart';

class TipDayScreen extends StatefulWidget {
  const TipDayScreen({Key? key}) : super(key: key);

  @override
  _TipDayScreenState createState() => _TipDayScreenState();
}

class _TipDayScreenState extends State<TipDayScreen> {
  String selectedCategory = "Stress Management";
  String currentTip = "";
  bool isLoading = true;
  bool showDropdown = false;
  String currentLanguageCode = 'en';

  final TipsManager _tipsManager = TipsManager();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _initializeTipsManager();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get current language when dependencies are available
    final locale = context.locale;
    if (currentLanguageCode != locale.languageCode) {
      currentLanguageCode = locale.languageCode;
      _loadTipOfTheDay();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeTipsManager() async {
    await _tipsManager.initialize();
    await _loadTipOfTheDay();
  }

  // Get category by name based on current language
  dynamic _getCategoryByName(String categoryName) {
    switch (currentLanguageCode) {
      case 'ru':
        return TipDataRU.getCategoryByName(categoryName);
      case 'de':
        return TipDataDE.getCategoryByName(categoryName);
      case 'es':
        return TipDataES.getCategoryByName(categoryName);
      case 'fr':
        return TipDataFR.getCategoryByName(categoryName);
      default:
        return TipData.getCategoryByName(categoryName);
    }
  }

  // Get all categories based on current language
  List<dynamic> _getAllCategories() {
    switch (currentLanguageCode) {
      case 'ru':
        return TipDataRU.getAllCategories();
      case 'de':
        return TipDataDE.getAllCategories();
      case 'es':
        return TipDataES.getAllCategories();
      case 'fr':
        return TipDataFR.getAllCategories();
      default:
        return TipData.getAllCategories();
    }
  }

  Future<void> _loadTipOfTheDay() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    final savedCategory = prefs.getString('selected_tip_category') ?? selectedCategory;
    final lastTipDate = prefs.getString('last_tip_date_${savedCategory}_$currentLanguageCode') ?? '';

    setState(() {
      selectedCategory = savedCategory;
    });

    String tipForToday;

    if (lastTipDate != todayString) {
      tipForToday = _generateDailyTip(selectedCategory, today);
      await prefs.setString('tip_of_day_${selectedCategory}_${todayString}_$currentLanguageCode', tipForToday);
      await prefs.setString('last_tip_date_${savedCategory}_$currentLanguageCode', todayString);
    } else {
      tipForToday = prefs.getString('tip_of_day_${selectedCategory}_${todayString}_$currentLanguageCode') ??
          _generateDailyTip(selectedCategory, today);
    }

    setState(() {
      currentTip = tipForToday;
      isLoading = false;
    });
  }

  String _generateDailyTip(String categoryName, DateTime date) {
    final category = _getCategoryByName(categoryName);

    if (category == null || category.tips.isEmpty) {
      return "Stay positive and keep growing!";
    }

    final daysSinceEpoch = date.difference(DateTime(2024, 1, 1)).inDays;
    final random = Random(daysSinceEpoch + categoryName.hashCode);
    final tipIndex = random.nextInt(category.tips.length);

    return category.tips[tipIndex];
  }

  Future<void> _onCategoryChanged(String newCategory) async {
    if (newCategory == selectedCategory) return;

    setState(() {
      selectedCategory = newCategory;
      showDropdown = false;
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_tip_category', newCategory);

    await _loadTipOfTheDay();
  }

  // Share functionality
  Future<void> _shareTip() async {
    try {
      final Uint8List? image = await _screenshotController.capture();

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/tip_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);

        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out this helpful tip!'.tr(),
        );
      }
    } catch (e) {
      print('Error sharing tip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share tip'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  Widget _buildDropdown() {
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
                itemCount: _getAllCategories().length,
                itemBuilder: (context, index) {
                  final category = _getAllCategories()[index];
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
                                color: isSelected
                                    ? context.primaryTextColor
                                    : context.primaryTextColor,
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

  Future<void> _handleDonePressed() async {
    final success = await _tipsManager.saveTipView(
      tipContent: currentTip,
      category: selectedCategory,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tipsManager.getStreakMessage()),
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

  Future<void> _handleNeutralTip() async {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);
    final category = _getCategoryByName(selectedCategory);

    if (category != null && category.tips.length > 1) {
      List<String> availableTips = category.tips.where((tip) => tip != currentTip).toList();
      if (availableTips.isNotEmpty) {
        final random = Random();
        final newTip = availableTips[random.nextInt(availableTips.length)];

        setState(() {
          currentTip = newTip;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tip_of_day_${selectedCategory}_${todayString}_$currentLanguageCode', newTip);
      }
    }
  }

  Future<void> _handleLikeTip() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_tips_$currentLanguageCode') ?? [];

    if (!favorites.contains(currentTip)) {
      favorites.add(currentTip);
      await prefs.setStringList('favorite_tips_$currentLanguageCode', favorites);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tip saved to favorites!'.tr()),
          backgroundColor: context.primaryTextColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.backgroundColor,
      body: GestureDetector(
        onTap: () {
          if (showDropdown) {
            setState(() {
              showDropdown = false;
            });
          }
        },
        child: Screenshot(
          controller: _screenshotController,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  context.isDarkMode
                      ? 'assets/svg/Quotes.svg'
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
                                'Tip of the Day'.tr(),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: context.primaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildDropdown(),

                  const SizedBox(height: 20),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.primaryTextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryTextColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      DateFormat('MMMM d, yyyy').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

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
                              currentTip,
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

                  const SizedBox(height: 140),
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
                          onTap: _shareTip,
                          child: Container(
                            width: 173,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(55),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/share.png',

                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Share'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleNeutralTip,
                          child: SvgPicture.asset(
                            'assets/svg/neutral.svg',
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleLikeTip,
                          child: SvgPicture.asset(
                            'assets/svg/like.svg',
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
      ),
    );
  }
}