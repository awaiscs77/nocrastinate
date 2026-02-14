import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager
import 'Onboarding10Screen.dart';

class Onboarding9Screen extends StatefulWidget {
  const Onboarding9Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding9Screen> createState() => _Onboarding9ScreenState();
}

class _Onboarding9ScreenState extends State<Onboarding9Screen> {
  bool morningToggle = false;
  bool dayToggle = true; // Default to day being selected
  bool eveningToggle = false;

  Widget _buildTimeOption({
    required String iconPath,
    required String title,
    required String time,
    required bool isSelected,
    required bool toggleValue,
    required ValueChanged<bool> onToggleChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 62,
      decoration: BoxDecoration(
        color: isSelected
            ? context.blackSectionColor
            : context.cardBackgroundColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: isSelected
            ? null
            : Border.all(
          color: context.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            colorFilter: isSelected
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : ColorFilter.mode(
                context.primaryTextColor.withOpacity(0.8),
                BlendMode.srcIn
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : context.primaryTextColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : context.blackSectionColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? context.blackSectionColor
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: toggleValue,
            onChanged: onToggleChanged,
            activeColor: isSelected
                ? AppColors.accent
                : context.blackSectionColor,
            inactiveThumbColor: context.primaryTextColor.withOpacity(0.45),
            activeTrackColor: isSelected
                ? AppColors.accent.withOpacity(0.3)
                : context.blackSectionColor.withOpacity(0.3),
            inactiveTrackColor: context.borderColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.blackSectionColor,
      body: Column(
        children: [
          // Top safe area
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top padding
                const SizedBox(height: 40),

                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      '"Healthy habits are built through consistency."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // 40 height padding
                const SizedBox(height: 40),
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'When do you want to set time aside for your mental health?',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                color: context.primaryTextColor,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Morning option
                            _buildTimeOption(
                              iconPath: 'assets/svg/morning.svg',
                              title: 'Morning',
                              time: '18:00',
                              isSelected: morningToggle,
                              toggleValue: morningToggle,
                              onToggleChanged: (value) {
                                setState(() {
                                  morningToggle = value;
                                  if (value) {
                                    dayToggle = false;
                                    eveningToggle = false;
                                  }
                                });
                              },
                            ),

                            // Day option (default selected)
                            _buildTimeOption(
                              iconPath: 'assets/svg/day.svg',
                              title: 'Day',
                              time: '15:00',
                              isSelected: dayToggle,
                              toggleValue: dayToggle,
                              onToggleChanged: (value) {
                                setState(() {
                                  dayToggle = value;
                                  if (value) {
                                    morningToggle = false;
                                    eveningToggle = false;
                                  }
                                });
                              },
                            ),

                            // Evening option
                            _buildTimeOption(
                              iconPath: 'assets/svg/night.svg',
                              title: 'Evening',
                              time: '20:00',
                              isSelected: eveningToggle,
                              toggleValue: eveningToggle,
                              onToggleChanged: (value) {
                                setState(() {
                                  eveningToggle = value;
                                  if (value) {
                                    morningToggle = false;
                                    dayToggle = false;
                                  }
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            // Additional info text
                            Center(
                              child: Text(
                                'You can always change these settings later in your profile.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom button section
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 168,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: (morningToggle || dayToggle || eveningToggle)
                                ? () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => Onboarding10Screen())
                              );
                            }
                                : null, // Disable button if no option selected
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.isDarkMode
                                  ? Colors.white
                                  : context.blackSectionColor,
                              disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                              shadowColor: context.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                            child:  Text(
                              'Confirm',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode
                                    ? context.backgroundColor
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Bottom safe area padding
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}