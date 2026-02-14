import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

class ActivityPopupScreen extends StatefulWidget {
  @override
  _ActivityPopupScreenState createState() => _ActivityPopupScreenState();
}

class _ActivityPopupScreenState extends State<ActivityPopupScreen> {
  PageController _pageController = PageController(viewportFraction: 0.3);
  int _currentIndex = 0;
  TextEditingController _editController = TextEditingController();

  final List<Map<String, String>> activities = [
    {'icon': 'assets/svg/steering-wheel.svg', 'title': 'Drive'},
    {'icon': 'assets/svg/school.svg', 'title': 'School'},
    {'icon': 'assets/svg/beach_access.svg', 'title': 'Beach'},
    {'icon': 'assets/svg/Cookie.svg', 'title': 'Food'},
    {'icon': 'assets/svg/Sun.svg', 'title': 'Sun'},
    {'icon': 'assets/svg/pool.svg', 'title': 'Pool'},
    {'icon': 'assets/svg/sports_basketball.svg', 'title': 'Sports'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    _editController.text = activities[_currentIndex]['title']!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Enter Name'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          content: TextField(
            controller: _editController,
            style: TextStyle(color: context.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Activity name'.tr(),
              hintStyle: TextStyle(color: context.secondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF023E8A)),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel'.tr(),
                style: TextStyle(color: context.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  activities[_currentIndex]['title'] = _editController.text.trim().isEmpty
                      ? activities[_currentIndex]['title']!
                      : _editController.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Save'.tr(),
                style: TextStyle(color: Color(0xFF023E8A)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Column(
        children: [
          Expanded(child: Container()), // Takes up remaining space
          Container(
            height: 302,
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Top bar with cross and Add button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          'assets/svg/RoundWhiteBack.svg',
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.primaryTextColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Add button action
                          print('Add button tapped');
                        },
                        child: Text(
                          '+ Add'.tr(),
                          style: TextStyle(
                            color: Color(0xFF023E8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable horizontal activities
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Horizontal scrollable activities
                      Container(
                        height: 115,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            bool isActive = index == _currentIndex;

                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              width: 115,
                              height: 115,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (context.isDarkMode ? Colors.grey[700] : Color(0xFFDEDEDE))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(57.5),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  activities[index]['icon']!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      // Activity title with edit icon (moved to bottom)
                      Container(
                        height: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (activities[_currentIndex]['title'] ?? '').toString().tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.primaryTextColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showEditDialog,
                              child: SvgPicture.asset(
                                'assets/svg/EDIT.svg',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}