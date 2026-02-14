import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocrastinate/ThemeManager.dart';

class IconsAppearenceScreen extends StatefulWidget {
  const IconsAppearenceScreen({Key? key}) : super(key: key);

  @override
  State<IconsAppearenceScreen> createState() => _IconsAppearenceScreenState();
}

class _IconsAppearenceScreenState extends State<IconsAppearenceScreen> {
  int selectedIconIndex = 0; // Default to first icon selected

  final List<String> iconAssets = [
    'assets/svg/icon1.svg',
    'assets/svg/icon2.svg',
    'assets/svg/icon3.svg',
    'assets/svg/icon4.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDarkMode = context.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.black54,
          body: Stack(
            children: [
              // Backdrop
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              // Bottom popup
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? context.cardBackgroundColor
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
                              'Icon Appearance'.tr(),
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
                      const SizedBox(height: 32),

                      // Icons selection row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(iconAssets.length, (index) {
                            final isSelected = selectedIconIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIconIndex = index;
                                });
                              },
                              child: Container(
                                width: 54,
                                height: 54,
                                child: Stack(
                                  children: [
                                    // Main icon
                                    Center(
                                      child: SvgPicture.asset(
                                        iconAssets[index],
                                      ),
                                    ),
                                    // Tick mark for selected item
                                    if (isSelected)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: SvgPicture.asset(
                                          'assets/svg/tickGreen.svg',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Done button
                      Center(
                        child: SizedBox(
                          width: 168,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle done action here
                              // You can access the selected icon index via selectedIconIndex
                              Navigator.of(context).pop();
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
                              'Confirm'.tr(),
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

// Usage example:
void showIconAppearenceScreen(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const IconsAppearenceScreen(),
  );
}