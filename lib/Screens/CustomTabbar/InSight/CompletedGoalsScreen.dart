import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nocrastinate/ThemeManager.dart';
import '../../../ApiServices/CreateGoalServices.dart';
import 'EntriesInsightScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class CompletedGoalsScreen extends StatefulWidget {
  @override
  _CompletedGoalsScreenState createState() => _CompletedGoalsScreenState();
}

class _CompletedGoalsScreenState extends State<CompletedGoalsScreen> {
  final CreateGoalServices _goalService = CreateGoalServices();
  Map<String, int> _statistics = {'total': 0, 'completed': 0};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await _goalService.getGoalStatistics();
    setState(() {
      _statistics = stats;
      _isLoadingStats = false;
    });
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Set';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid Date';
    }

    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting
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
          'Completed Goals'.tr(),
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
          // Statistics section
          _isLoadingStats
              ? CircularProgressIndicator(color: Colors.white)
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${_statistics['total']}',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'Total Goals'.tr(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20),
              Container(
                height: 30,
                width: 1,
                color: Colors.white,
              ),
              SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    '${_statistics['completed']}',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'Completed'.tr(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                      height: 1.3,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          // White container with completed goals list
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
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _goalService.getCompletedGoals(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: context.primaryTextColor,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          print('Error details: ${snapshot.error}'); // Add this line

                          return Center(
                            child: Text(
                              'Error loading goals'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: context.primaryTextColor,
                              ),
                            ),
                          );
                        }

                        final completedGoals = snapshot.data ?? [];

                        if (completedGoals.isEmpty) {
                          return Center(
                            child: Text(
                              'No completed goals yet'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: context.primaryTextColor.withOpacity(0.5),
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    "Completed".tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.primaryTextColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: completedGoals.length,
                                  separatorBuilder: (context, index) => Container(
                                    height: 0.5,
                                    color: context.borderColor,
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  itemBuilder: (context, index) {
                                    final goal = completedGoals[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EntriesInsightScreen(
                                                  goalData: goal,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 8),
                                        color: Colors.transparent, // Add this for better tap detection
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    goal['title'] ?? 'Untitled Goal'.tr(),
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w400,
                                                      color: context.primaryTextColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      SvgPicture.asset(
                                                        'assets/svg/target.svg',
                                                        colorFilter: ColorFilter.mode(
                                                          context.primaryTextColor,
                                                          BlendMode.srcIn,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        _formatDate(goal['createdAt']),
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: context.primaryTextColor,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      SvgPicture.asset(
                                                        'assets/svg/Check_All.svg',
                                                        colorFilter: ColorFilter.mode(
                                                          isDark
                                                              ? AppColors.accent
                                                              : Color(0xFF023E8A),
                                                          BlendMode.srcIn,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        _formatDate(goal['completedAt']),
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark
                                                              ? AppColors.accent
                                                              : Color(0xFF023E8A),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right,
                                              color: context.primaryTextColor,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
            ),
          ),
        ],
      ),
    );
  }
}