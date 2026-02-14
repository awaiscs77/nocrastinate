import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Settings/NotificationDetailScreen.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your ThemeManager
import 'package:easy_localization/easy_localization.dart';

import '../../../ApiServices/AuthProvider.dart';
import 'LanguageSelectionScreen.dart';
import 'EditProfileScreen.dart';
import 'IconsAppearenceScreen.dart';

class AppGuideScreen extends StatefulWidget {
  @override
  _AppGuideScreenState createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openGettingStartedGuide() {
    // Navigate to Getting Started Guide or open URL
    print("Open Getting Started Guide");
  }

  void _contactDeveloper() {
    // Open email client or contact form
    print("Contact the developer");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
        builder: (context, themeManager, child)
    {
      return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userName = authProvider.userDisplayName.isNotEmpty
              ? authProvider.userDisplayName
              : 'User';
          return Scaffold(
            backgroundColor: context.blackSectionColor,
            appBar: AppBar(
              backgroundColor: context.blackSectionColor,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/svg/BackBlack.svg',
                    fit: BoxFit.contain,

                  ),
                ),
              ),
              centerTitle: true,
              title: Text(
                'App Guide & Feedback'.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            body: Column(
              children: [
                const SizedBox(height: 20),
                // Top content (Goal title and progress info)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),

                  ],
                ),
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: 'Member since'.tr() + ' ' ),
                        TextSpan(
                          text: authProvider.getMemberDuration(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // White container that extends to bottom with safe area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? context.cardBackgroundColor
                          : context.backgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Scrollable content area
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "App Guide & Feedback",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: context.primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),

                                  // Getting Started Guide button
                                  GestureDetector(
                                    onTap: _openGettingStartedGuide,
                                    child: ThemedContainer(
                                      height: 55,
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/svg/Getting Started Guide.svg',
                                            fit: BoxFit.contain,
                                            colorFilter: ColorFilter.mode(
                                              context.primaryTextColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Getting Started Guide'.tr(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: context.primaryTextColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            Icons.chevron_right,
                                            color: context.primaryTextColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  // Contact Developer button
                                  GestureDetector(
                                    onTap: _contactDeveloper,
                                    child: ThemedContainer(
                                      height: 55,
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/svg/Contact the developer.svg',
                                            fit: BoxFit.contain,
                                            colorFilter: ColorFilter.mode(
                                              context.primaryTextColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Contact the developer'.tr(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: context.primaryTextColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            Icons.chevron_right,
                                            color: context.primaryTextColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),

                                ],
                              ),
                            ),
                          ),
                        ),

                        // Fixed bottom buttons
                        Container(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery
                              .of(context)
                              .padding
                              .bottom + 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // You can add action buttons here if needed
                              const SizedBox(width: 15),
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
        },
      );
    }
    );
  }
}