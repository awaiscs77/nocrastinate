import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Focus/ProductivityTimerScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/ExerciseDayScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:nocrastinate/Models/FocusItem.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../ApiServices/FocusService.dart';
import '../Home/MoodScreens/MindPracticeScreens/PlanActivityScreen.dart';
import 'BreathingExerciseScreen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({Key? key}) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final FocusService _focusService = FocusService();
  List<FocusItem> focusItems = [];
  bool isLoading = true;

  PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> timerCells = List.generate(2, (index) => 'Timer ${index + 1}');

  @override
  void initState() {
    super.initState();
    _loadFocusItems();
  }

  void _loadFocusItems() {
    _focusService.getFocusItems().listen(
          (items) {
        if (mounted) {
          setState(() {
            focusItems = items;
            isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading focus items: $error')),
          );
        }
      },
    );
  }

  void _toggleItemStatus(FocusItem item) async {
    try {
      if (item.isDone) {
        await _focusService.markFocusItemUndone(item.id);
      } else {
        await _focusService.markFocusItemDone(item.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.blackSectionColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Your focus for today".tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: context.isDarkMode ? context.primaryTextColor : Colors.white,
                  ),
                ),
              ),

              // List items
              Container(
                child: isLoading
                    ? Container(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1D79ED),
                    ),
                  ),
                )
                    : focusItems.isEmpty
                    ? Container(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Icon(
                          Icons.task_alt,
                          size: 48,
                          color: context.secondaryTextColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "No focus items yet".tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        Text(
                          "Add your first activity to get started".tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        SizedBox(height: 50)
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.0),
                  itemCount: focusItems.length,
                  itemBuilder: (context, index) {
                    final item = focusItems[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.0),
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: context.isDarkMode
                                        ? context.primaryTextColor
                                        : context.cardBackgroundColor,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: context.secondaryTextColor,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? AppColors.darkSecondaryBackground
                                      : Color(0xFF303030),
                                  borderRadius: BorderRadius.circular(55),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: context.isDarkMode
                                        ? context.primaryTextColor
                                        : context.cardBackgroundColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _toggleItemStatus(item),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: item.isDone
                                        ? Colors.green
                                        : Color(0xFF1D79ED),
                                    borderRadius: BorderRadius.circular(55),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        child: SvgPicture.asset(
                                          'assets/svg/doubleTick.svg',
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        item.isDone ? "Done".tr() : "Mark Done",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Add daily activity button
              // Add daily activity button
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => PlanActivityScreen()
                        )
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 200,
                      maxWidth: MediaQuery.of(context).size.width - 48, // Account for padding
                    ),
                    height: 35,
                    padding: EdgeInsets.symmetric(horizontal: 16), // Add horizontal padding
                    decoration: BoxDecoration(
                      color: context.secondaryBackgroundColor,
                      borderRadius: BorderRadius.circular(55),
                      boxShadow: [
                        BoxShadow(
                          color: (context.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1)),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Important: This makes the Row only as wide as needed
                      children: [
                        SvgPicture.asset(
                          'assets/svg/add.svg',
                          color: context.primaryTextColor,
                          width: 16, // Constrain icon size
                          height: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible( // Wrap text in Flexible to allow it to shrink if needed
                          child: Text(
                            "Add daily activity".tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: context.primaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis, // Add ellipsis if text is still too long
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              // White container
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Text(
                      "Quick Focus".tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => BreathingExerciseScreen(isRelaxType: true))
                                );
                              },
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Color(0xFF023E8A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Changed from mainAxisSize
                                    children: [
                                      Text(
                                        "Quick Mental\nReset".tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Expanded( // Wrap SVG with Expanded
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                                          child: SvgPicture.asset(
                                            'assets/svg/resetMental.svg',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded( // Changed from Flexible
                                            child: Text(
                                              "Start a 2 min\nBreathing Exercise".tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => ProductivityTimerScreen(timer: 10))
                                );
                              },
                              child: Container(
                                height: 200, // Changed to match the first container
                                decoration: BoxDecoration(
                                  color: Color(0xFF023E8A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Changed from mainAxisSize
                                    children: [
                                      Text(
                                        "Lightning\nWork Session".tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Expanded( // Wrap SVG with Expanded
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: SvgPicture.asset(
                                            'assets/svg/workStation.svg',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded( // Changed from Flexible
                                            child: Text(
                                              "Start a 10 min\nProductivity Timer".tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Focus Activities".tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 84,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: timerCells.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              if (index == 0){
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => ProductivityTimerScreen(timer: 25))
                                );
                              }
                              else{
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => BreathingExerciseScreen(isRelaxType: false))
                                );
                              }

                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 0),
                              child: index == 0 ? SvgPicture.asset(
                                'assets/svg/timeCell.svg',
                                height: 84,
                                fit: BoxFit.contain,
                              ) : SvgPicture.asset(
                                'assets/breathingSVG.svg',
                                height: 84,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        timerCells.length,
                            (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Color(0xFF023E8A)
                                : (context.isDarkMode
                                ? Colors.white38
                                : Color(0xFFBDBDBD)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}