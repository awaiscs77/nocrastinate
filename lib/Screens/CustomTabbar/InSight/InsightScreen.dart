import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:nocrastinate/Screens/CustomTabbar/InSight/CompletedGoalsScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/InSight/EntriesInsightScreen.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../ApiServices/CreateGoalServices.dart';
import '../../../ApiServices/FocusService.dart';
import '../../../Manager/MoodCheckinManager.dart';
import '../../../Models/FocusChartModels.dart';
import '../../../Models/FocusItem.dart';
import '../../../ThemeManager.dart'; // Import your ThemeManager
import 'dart:math';

import 'CBTEntriesInsightScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({Key? key}) : super(key: key);

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {

  String selectedMonth = 'This Month';
  String selectedEmotionsMonth = 'This Month';
  late List<String> months; // Remove the hardcoded list
  int currentMonthIndex = 0; // Start with 'This Month'
  int currentEmotionsMonthIndex = 0;
  Map<String, double> _emotionPercentages = {};
  bool _isLoadingEmotions = true;

  final List<String> calendarMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Map<String, int> _dailyMoods = {};
  bool _isLoadingMoodData = true;
  bool _hasSufficientMoodData = false;
  String selectedMoodPeriod = 'Weekly'; // 'Weekly' or 'Monthly'
  int currentWeekOffset = 0;
  Map<String, int> _calendarMoods = {};
  bool _isLoadingCalendarData = true;
  String selectedCalendarPeriod = 'Monthly'; // 'Weekly' or 'Monthly'

  String selectedCalendarMonth = 'January';
  int currentCalendarMonthIndex = 0;

  List<Map<String, dynamic>> _goalsData = [];
  bool _isLoadingGoals = true;
  final CreateGoalServices _goalServices = CreateGoalServices();
  Map<String, double> _activityPercentages = {};
  bool _isLoadingActivities = true;
  StreamSubscription<List<FocusItem>>? _activitiesSubscription;
  final FocusService _focusService = FocusService();
  Map<String, int> _lastPeriodMoods = {};
  double _percentageChange = 0.0;
  bool _showPeriodDropdown = false;

  @override
  void initState() {
    super.initState();
    months = _generateAvailableMonths();
    currentMonthIndex = 0;
    currentEmotionsMonthIndex = 0;

    // Defer loading until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoalsData();
      _loadActivityData();
      _loadEmotionData();
      _loadMoodGraphData();
    });
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCalendarMoodData() async {
    setState(() {
      _isLoadingCalendarData = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
      final now = DateTime.now();

      DateTime startDate, endDate;

      if (selectedCalendarPeriod == 'Weekly') {
        // Get current week (Monday to Sunday)
        startDate = _getStartOfWeek(now);
        endDate = startDate.add(const Duration(days: 6));
      } else {
        // Get current month
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      }

      final moodsDict = await moodManager.getDailyMoodsDictByDate(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _calendarMoods = moodsDict;
        _isLoadingCalendarData = false;
      });
    } catch (e) {
      print('Error loading calendar mood data: $e');
      setState(() {
        _calendarMoods = {};
        _isLoadingCalendarData = false;
      });
    }
  }
  Color _getMoodColor(int moodIndex) {
    // moodIndex: 1=Terrible, 2=Sad, 3=Neutral, 4=Happy, 5=Amazing
    if (moodIndex >= 3) {
      // Good moods: Neutral, Happy, Amazing
      return const Color(0x407AE9FF); // Blue with 25% opacity
    } else if (moodIndex > 0) {
      // Bad moods: Terrible, Sad
      return const Color(0x40FFAA85); // Orange with 25% opacity
    }
    // No data
    return Colors.transparent;
  }

  // Load mood data for the graph
  Future<void> _loadMoodGraphData() async {
    setState(() {
      _isLoadingMoodData = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
      final now = DateTime.now();

      DateTime currentStart, currentEnd, lastStart, lastEnd;

      if (selectedMoodPeriod == 'Weekly') {
        // Current week
        currentStart = _getStartOfWeek(now);
        currentEnd = currentStart.add(const Duration(days: 6));

        // Last week
        lastStart = currentStart.subtract(const Duration(days: 7));
        lastEnd = lastStart.add(const Duration(days: 6));
      } else {
        // Current month
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = DateTime(now.year, now.month + 1, 0);

        // Last month
        lastStart = DateTime(now.year, now.month - 1, 1);
        lastEnd = DateTime(now.year, now.month, 0);
      }

      // Fetch current period data
      final currentMoodsDict = await moodManager.getDailyMoodsDictByDate(
        startDate: currentStart,
        endDate: currentEnd,
      );

      // Fetch last period data
      final lastMoodsDict = await moodManager.getDailyMoodsDictByDate(
        startDate: lastStart,
        endDate: lastEnd,
      );

      // Calculate percentage change
      double currentAvg = _calculateAverageMood(currentMoodsDict);
      double lastAvg = _calculateAverageMood(lastMoodsDict);

      double percentageChange = 0.0;
      if (lastAvg > 0) {
        percentageChange = ((currentAvg - lastAvg) / lastAvg) * 100;
      }

      setState(() {
        _dailyMoods = currentMoodsDict;
        _lastPeriodMoods = lastMoodsDict;
        _percentageChange = percentageChange;
        // Check if we have at least 5 days of data
        _hasSufficientMoodData = currentMoodsDict.length >= 5;
        _isLoadingMoodData = false;
      });
    } catch (e) {
      print('Error loading mood graph data: $e');
      setState(() {
        _dailyMoods = {};
        _lastPeriodMoods = {};
        _percentageChange = 0.0;
        _hasSufficientMoodData = false;
        _isLoadingMoodData = false;
      });
    }
  }

  double _calculateAverageMood(Map<String, int> moodsDict) {
    if (moodsDict.isEmpty) return 0.0;

    int total = 0;
    int count = 0;

    moodsDict.forEach((date, moodIndex) {
      if (moodIndex > 0) {
        total += moodIndex;
        count++;
      }
    });

    return count > 0 ? total / count : 0.0;
  }
// Get weekly mood data (last 7 days)
  List<ChartData> getWeeklyMoodData() {
    if (!_hasSufficientMoodData) {
      return [];
    }

    final now = DateTime.now();
    final List<ChartData> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = _getDateString(date);
      final moodIndex = _dailyMoods[dateString] ?? 0;

      // Get day name (Mon, Tue, etc.)
      final dayName = _getDayName(date.weekday);

      // Convert mood index (1-5) to chart value (0-60 scale)
      final chartValue = moodIndex * 12.0; // Scale: 1->12, 2->24, 3->36, 4->48, 5->60

      weeklyData.add(ChartData(dayName, chartValue));
    }

    return weeklyData;
  }

  List<ChartData> getLastWeekMoodData() {
    if (!_hasSufficientMoodData) {
      return [];
    }

    final now = DateTime.now();
    final List<ChartData> weeklyData = [];

    for (int i = 13; i >= 7; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = _getDateString(date);
      final moodIndex = _lastPeriodMoods[dateString] ?? 0;

      // Get day name (Mon, Tue, etc.)
      final dayName = _getDayName(date.weekday);

      // Convert mood index (1-5) to chart value (0-60 scale)
      final chartValue = moodIndex * 12.0;

      weeklyData.add(ChartData(dayName, chartValue));
    }

    return weeklyData;
  }


// Get monthly mood data (last 4 weeks)
  List<ChartData> getMonthlyMoodData() {
    if (!_hasSufficientMoodData) {
      return [];
    }

    final now = DateTime.now();
    final List<ChartData> monthlyData = [];

    // Group data by weeks (4 weeks)
    for (int week = 3; week >= 0; week--) {
      final weekEnd = now.subtract(Duration(days: week * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      double totalMood = 0;
      int daysCount = 0;

      // Calculate average mood for this week
      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final dateString = _getDateString(date);
        final moodIndex = _dailyMoods[dateString];

        if (moodIndex != null && moodIndex > 0) {
          totalMood += moodIndex.toDouble();
          daysCount++;
        }
      }

      final averageMood = daysCount > 0 ? totalMood / daysCount : 0;
      final chartValue = averageMood * 12.0; // Scale to 0-60

      monthlyData.add(ChartData('Week ${4 - week}', chartValue));
    }

    return monthlyData;
  }
  List<ChartData> getLastMonthMoodData() {
    if (_lastPeriodMoods.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final List<ChartData> monthlyData = [];

    // Group data by weeks (4 weeks of last month)
    for (int week = 3; week >= 0; week--) {
      final weekEnd = lastMonthEnd.subtract(Duration(days: week * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      double totalMood = 0;
      int daysCount = 0;

      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final dateString = _getDateString(date);
        final moodIndex = _lastPeriodMoods[dateString];

        if (moodIndex != null && moodIndex > 0) {
          totalMood += moodIndex.toDouble();
          daysCount++;
        }
      }

      final averageMood = daysCount > 0 ? totalMood / daysCount : 0;
      final chartValue = averageMood * 12.0;

      monthlyData.add(ChartData('Week ${4 - week}', chartValue));
    }

    return monthlyData;
  }

// Helper function to get date string in YYYY-MM-DD format
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

// Helper function to get day name
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }


  Future<void> _loadEmotionData() async {
    setState(() {
      _isLoadingEmotions = true;
    });

    try {
      final now = DateTime.now();
      int month, year;

      // Only allow past months or current month
      if (selectedEmotionsMonth == 'This Month') {
        month = now.month;
        year = now.year;
      } else if (selectedEmotionsMonth == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1);
        month = lastMonth.month;
        year = lastMonth.year;
      } else {
        // Handle specific month names (May, April, March, etc.)
        final monthMap = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4,
          'May': 5, 'June': 6, 'July': 7, 'August': 8,
          'September': 9, 'October': 10, 'November': 11, 'December': 12
        };

        final selectedMonthNumber = monthMap[selectedEmotionsMonth] ?? now.month;

        // Determine the correct year for the selected month
        if (selectedMonthNumber > now.month) {
          // If selected month is later in year than current, it must be from previous year
          year = now.year - 1;
        } else {
          // If selected month is current or earlier, it's from current year
          year = now.year;
        }

        month = selectedMonthNumber;

        // Additional check to ensure we're not accessing future data
        final selectedDate = DateTime(year, month);
        final currentDate = DateTime(now.year, now.month);

        // If somehow the selected date is in the future, default to current month
        if (selectedDate.isAfter(currentDate)) {
          month = now.month;
          year = now.year;
        }
      }

      final percentages = await _getEmotionPercentagesForMonth(month, year);

      setState(() {
        _emotionPercentages = percentages;
        _isLoadingEmotions = false;
      });
    } catch (e) {
      print('Error loading emotion data: $e');
      setState(() {
        _emotionPercentages = {};
        _isLoadingEmotions = false;
      });
    }
  }
  DateTime _getStartOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
  Future<Map<String, double>> _getEmotionPercentagesForMonth(int month, int year) async {
    try {
      // Get start and end of month
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      // Get mood check-ins for the month
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
      final moodHistory = await moodManager.getMoodTrends(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      if (moodHistory == null || moodHistory.isEmpty) {
        return {};
      }

      // Count emotion occurrences
      final Map<String, int> emotionCounts = {};
      int totalEmotionEntries = 0;

      for (final mood in moodHistory) {
        final emotions = mood.selectedEmotionTags;
        if (emotions.isNotEmpty) {
          totalEmotionEntries++;
          for (final emotion in emotions) {
            emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
          }
        }
      }

      if (totalEmotionEntries == 0) {
        return {};
      }

      // Calculate percentages
      final Map<String, double> percentages = {};
      emotionCounts.forEach((emotion, count) {
        percentages[emotion] = (count / totalEmotionEntries) * 100;
      });

      return percentages;
    } catch (e) {
      print('Error getting emotion percentages: $e');
      return {};
    }
  }


  Future<void> _loadActivityData() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final now = DateTime.now();
      int month, year;

      // Only allow past months or current month
      if (selectedMonth == 'This Month') {
        month = now.month;
        year = now.year;
      } else if (selectedMonth == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1);
        month = lastMonth.month;
        year = lastMonth.year;
      } else {
        // Handle specific month names (May, April, March, etc.)
        // Map month names to numbers
        final monthMap = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4,
          'May': 5, 'June': 6, 'July': 7, 'August': 8,
          'September': 9, 'October': 10, 'November': 11, 'December': 12
        };

        final selectedMonthNumber = monthMap[selectedMonth] ?? now.month;

        // Determine the correct year for the selected month
        if (selectedMonthNumber > now.month) {
          // If selected month is later in year than current, it must be from previous year
          year = now.year - 1;
        } else {
          // If selected month is current or earlier, it's from current year
          year = now.year;
        }

        month = selectedMonthNumber;

        // Additional check to ensure we're not accessing future data
        final selectedDate = DateTime(year, month);
        final currentDate = DateTime(now.year, now.month);

        // If somehow the selected date is in the future, default to current month
        if (selectedDate.isAfter(currentDate)) {
          month = now.month;
          year = now.year;
        }
      }

      final percentages = await _focusService.getActivityPercentagesForMonth(month, year);

      setState(() {
        _activityPercentages = percentages;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading activity data: $e');
      setState(() {
        _activityPercentages = {};
        _isLoadingActivities = false;
      });
    }
  }

  List<String> _generateAvailableMonths() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    List<String> availableMonths = ['This Month']; // Always include current month

    // Add last month
    final lastMonth = DateTime(currentYear, currentMonth - 1);
    availableMonths.add('Last Month');

    // Add previous months from current year
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Add months from current year that are before current month
    for (int i = currentMonth - 2; i >= 0; i--) {
      availableMonths.add(monthNames[i]);
    }

    // Add months from previous year (you can limit how far back you want to go)
    final previousYear = currentYear - 1;
    for (int i = 11; i >= 0; i--) {
      availableMonths.add('${monthNames[i]} $previousYear');

      // Limit to last 12 months total to avoid too many options
      if (availableMonths.length >= 12) break;
    }

    return availableMonths;
  }

  Future<void> _loadGoalsData() async {
    setState(() {
      _isLoadingGoals = true;
    });

    try {
      // Get all goals for the current user
      final goalsStream = _goalServices.getUserGoals();

      // Listen to the stream and get the first emission
      await for (final goals in goalsStream) {
        // Filter active goals and sort by last progress date
        final activeGoals = goals
            .where((goal) => goal['isCompleted'] != true)
            .toList();

        // Sort by last progress date (most recent first)
        activeGoals.sort((a, b) {
          final aLastProgress = a['lastProgress'] as Timestamp?;
          final bLastProgress = b['lastProgress'] as Timestamp?;

          if (aLastProgress == null && bLastProgress == null) return 0;
          if (aLastProgress == null) return 1;
          if (bLastProgress == null) return -1;

          return bLastProgress.compareTo(aLastProgress);
        });

        // Take only first 3 goals for display
        setState(() {
          _goalsData = activeGoals.take(3).toList();
          _isLoadingGoals = false;
        });
        break; // Exit after first emission
      }
    } catch (e) {
      print('Error loading goals data: $e');
      setState(() {
        _goalsData = [];
        _isLoadingGoals = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting

      backgroundColor: context.blackSectionColor, // Use theme color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Insight'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.isDarkMode ? context.primaryTextColor: context.cardBackgroundColor, // Use theme color
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              // Top section with containers
              Row(
                children: [
                  // Left side - two containers vertically
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,  // Add this
                      mainAxisAlignment: MainAxisAlignment.center,  // Add this
                      crossAxisAlignment: CrossAxisAlignment.start,  // Add this
                      children: [
                        _buildPercentageIndicator(),
                        const SizedBox(height: 8),  // Reduce from 12 to 8
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/monitor.svg',
                              height: 16,  // Add explicit height if needed
                              width: 16,   // Add explicit width if needed
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Focused on Workplace'.tr(),
                                style: TextStyle(
                                  color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,  // Add this
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPeriodSelector(),
                ],
              ),
              const SizedBox(height: 32),
              // Chart section - Now takes full width
              // Container(
              //   width: MediaQuery.of(context).size.width,
              //   height: 250,
              //   child: SfCartesianChart(
              //     backgroundColor: Colors.transparent,
              //     plotAreaBorderWidth: 0,
              //     margin: const EdgeInsets.all(0),
              //     borderWidth: 0,
              //     legend: Legend(
              //       isVisible: true,
              //       position: LegendPosition.bottom,
              //       textStyle: TextStyle(
              //         color: context.isDarkMode ? context.primaryTextColor: context.cardBackgroundColor, // Use theme color
              //         fontSize: 12,
              //         fontWeight: FontWeight.w500,
              //       ),
              //       iconHeight: 8,
              //       iconWidth: 16,
              //       itemPadding: 20,
              //     ),
              //     primaryXAxis: CategoryAxis(
              //       labelStyle: TextStyle(
              //         color: context.isDarkMode ? context.primaryTextColor: context.cardBackgroundColor, // Use theme color
              //         fontSize: 12,
              //       ),
              //       axisLine: AxisLine(width: 0),
              //       majorTickLines: MajorTickLines(width: 0),
              //       majorGridLines: MajorGridLines(width: 0),
              //       plotOffset: 0,
              //       labelPlacement: LabelPlacement.onTicks,
              //       edgeLabelPlacement: EdgeLabelPlacement.shift,
              //       labelIntersectAction: AxisLabelIntersectAction.none,
              //       labelAlignment: LabelAlignment.center,
              //       rangePadding: ChartRangePadding.round,
              //     ),
              //     primaryYAxis: NumericAxis(
              //       isVisible: false,
              //       majorGridLines: MajorGridLines(width: 0),
              //       plotOffset: 0,
              //       minimum: 0,
              //       maximum: 60,
              //     ),
              //     annotations: <CartesianChartAnnotation>[
              //       CartesianChartAnnotation(
              //         widget: Container(
              //           width: double.infinity,
              //           height: 1,
              //           decoration: BoxDecoration(
              //             border: Border(
              //               top: BorderSide(
              //                 color: context.secondaryTextColor, // Use theme color
              //                 width: 1,
              //                 style: BorderStyle.solid,
              //               ),
              //             ),
              //           ),
              //           child: CustomPaint(
              //             painter: DottedLinePainter(color: context.secondaryTextColor),
              //           ),
              //         ),
              //         coordinateUnit: CoordinateUnit.point,
              //         x: 'Week 4',
              //         y: 35,
              //       ),
              //     ],
              //     series: <CartesianSeries<dynamic, dynamic>>[
              //       // Last month spline series
              //       SplineSeries<ChartData, String>(
              //         dataSource: getLastMonthData(),
              //         xValueMapper: (ChartData data, _) => data.x,
              //         yValueMapper: (ChartData data, _) => data.y,
              //         color: context.isDarkMode ? context.primaryTextColor: context.cardBackgroundColor, // Use theme color
              //         width: 4,
              //         splineType: SplineType.natural,
              //         name: 'Last Month',
              //       ),
              //       // This month area series with gradient
              //       SplineAreaSeries<ChartData, String>(
              //         dataSource: getThisMonthData(),
              //         xValueMapper: (ChartData data, _) => data.x,
              //         yValueMapper: (ChartData data, _) => data.y,
              //         borderColor: const Color(0xFF1D79ED),
              //         borderWidth: 4,
              //         splineType: SplineType.natural,
              //         name: 'This Month',
              //         gradient: LinearGradient(
              //           begin: Alignment.topCenter,
              //           end: Alignment.bottomCenter,
              //           colors: [
              //             const Color(0xFF1D79ED).withOpacity(0.78),
              //             const Color(0x001D79ED),
              //           ],
              //         ),
              //       ),
              //       // Average line series
              //       LineSeries<ChartData, String>(
              //         dataSource: getAverageData(),
              //         xValueMapper: (ChartData data, _) => data.x,
              //         yValueMapper: (ChartData data, _) => data.y,
              //         color: context.secondaryTextColor, // Use theme color
              //         width: 2,
              //         dashArray: <double>[5, 5],
              //         name: 'Average',
              //       ),
              //     ],
              //   ),
              // ),
              _buildMoodChart(),
              const SizedBox(height: 32),
              // General Insights Container
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: context.backgroundColor, // Use theme color
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                  child: Column(
                    children: [
                      // Header with title and edit button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'General Insights'.tr(),
                            style: TextStyle(
                              color: context.primaryTextColor, // Use theme color
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 20),
                      // First custom insight box with radial chart
                      _buildTopActivitiesBox(),
                      const SizedBox(height: 12),
                      // Second insight box - Top Emotions
                      _buildTopEmotionsBox(),
                      const SizedBox(height: 12),
                      // Remaining 3 white boxes
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildMoodCalendarBox(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildLifeGoalsBox(),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => CompletedGoalsScreen()));
                        },
                        child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor, // Use theme color
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Text(
                                    "Completed Goals".tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.primaryTextColor, // Use theme color
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: context.secondaryTextColor, // Use theme color
                                    size: 20,
                                  ),
                                ],
                              ),
                            )),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "CBT ${"Exercises Entries".tr()}",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.primaryTextColor, // Use theme color
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {

                        },
                        child: SvgPicture.asset(
                          'assets/svg/cbt.svg',
                        ),
                      ),
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  //cost benefit entries
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CBTEntriesInsightScreen(
                                        isWhatIfChallenge: false,
                                      ),
                                    ),
                                  );
                                },
                                child: SvgPicture.asset(
                                  'assets/svg/cbt1.svg',
                                ),
                              ),
                            ),
                            SizedBox(width: 32),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {


                                },
                                child: Image.asset('assets/self_compression.png'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),



                      GestureDetector(
                          onTap: () {
                            //entries what if challenge
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CBTEntriesInsightScreen(
                                  isWhatIfChallenge: true,
                                ),
                              ),
                            );
                          },
                          child: Image.asset('assets/whatifChallenge.png')
                      ),
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                  onTap: () {

                                  },
                                  child: Image.asset('assets/growthMindset.png')
                              ),
                            ),
                            SizedBox(width: 32),
                            Expanded(
                              child: GestureDetector(
                                  onTap: () {

                                  },
                                  child: Image.asset('assets/selfEfficacy.png')
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActivitiesBox() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor, // Use theme color
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top section with flash icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/flash.svg',
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Activities this month'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor, // Use theme color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Month selector with arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentMonthIndex > 0) {
                        currentMonthIndex--;
                        selectedMonth = months[currentMonthIndex];
                        _loadActivityData(); // Add this line
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF), // Different colors for dark/light
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      size: 12,
                      color: context.primaryTextColor, // Use theme color
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  selectedMonth.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.primaryTextColor, // Use theme color
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentMonthIndex < months.length - 1) {
                        currentMonthIndex++;
                        selectedMonth = months[currentMonthIndex];
                        _loadActivityData(); // Add this line
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF), // Different colors for dark/light
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      size: 12,
                      color: context.primaryTextColor, // Use theme color
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Custom legend and chart container
            Expanded(
              child: Row(
                children: [
                  // Chart on the right
                  Expanded(
                    flex: 3,
                    child: SfCircularChart(
                      backgroundColor: Colors.transparent,
                      margin: EdgeInsets.zero,
                      legend: Legend(isVisible: false),
                      series: <CircularSeries<ActivityData, String>>[
                        RadialBarSeries<ActivityData, String>(
                          dataSource: getActivityData(),
                          xValueMapper: (ActivityData data, _) => data.activity,
                          yValueMapper: (ActivityData data, _) => data.percentage,
                          pointColorMapper: (ActivityData data, _) => data.color,
                          innerRadius: '40%',
                          radius: '85%',
                          cornerStyle: CornerStyle.bothCurve,
                          trackColor: context.isDarkMode
                              ? const Color(0xFF505050)
                              : const Color(0xFFE9ECEF), // Different track colors
                          trackBorderWidth: 2,
                          trackBorderColor: Colors.transparent,
                          gap: '8%',
                          dataLabelSettings: DataLabelSettings(isVisible: false),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingActivities)
                          Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.primaryTextColor,
                              ),
                            ),
                          )
                        else if (_activityPercentages.isEmpty)
                          Text(
                            'No activities yet'.tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: context.secondaryTextColor,
                            ),
                          )
                        else
                          ...getActivityData().asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final iconPaths = {
                              'Family': 'assets/svg/familyInsight.svg',
                              'Friends': 'assets/svg/partnerInsight.svg',
                              'Social': 'assets/svg/relaxingInsight.svg',
                              'Personal': 'assets/svg/familyInsight.svg',
                              'Relationships': 'assets/svg/partnerInsight.svg',
                            };

                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 16),
                                _buildLegendItem(
                                  iconPaths[data.activity] ?? 'assets/svg/familyInsight.svg',
                                  '${data.percentage.toStringAsFixed(0)}%',
                                  data.activity,
                                  data.color,
                                ),
                              ],
                            );
                          }).toList(),
                      ],
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

  Widget _buildTopEmotionsBox() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top section with happy emoji icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/emoji-happy.svg',
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Emotions this month'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Month selector with arrows for emotions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentEmotionsMonthIndex > 0) {
                        currentEmotionsMonthIndex--;
                        selectedEmotionsMonth = months[currentEmotionsMonthIndex];
                        _loadEmotionData(); // Add this line
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      size: 12,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  selectedEmotionsMonth.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentEmotionsMonthIndex < months.length - 1) {
                        currentEmotionsMonthIndex++;
                        selectedEmotionsMonth = months[currentEmotionsMonthIndex];
                        _loadEmotionData(); // Add this line
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      size: 12,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Custom legend and chart container for emotions
            Expanded(
              child: Row(
                children: [
                  // Chart on the right
                  Expanded(
                    flex: 3,
                    child: SfCircularChart(
                      backgroundColor: Colors.transparent,
                      margin: EdgeInsets.zero,
                      legend: Legend(isVisible: false),
                      series: <CircularSeries<EmotionData, String>>[
                        RadialBarSeries<EmotionData, String>(
                          dataSource: getEmotionData(),
                          xValueMapper: (EmotionData data, _) => data.emotion,
                          yValueMapper: (EmotionData data, _) => data.percentage,
                          pointColorMapper: (EmotionData data, _) => data.color,
                          innerRadius: '40%',
                          radius: '85%',
                          cornerStyle: CornerStyle.bothCurve,
                          trackColor: context.isDarkMode
                              ? const Color(0xFF505050)
                              : const Color(0xFFE9ECEF),
                          trackBorderWidth: 2,
                          trackBorderColor: Colors.transparent,
                          gap: '8%',
                          dataLabelSettings: DataLabelSettings(isVisible: false),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingEmotions)
                          Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.primaryTextColor,
                              ),
                            ),
                          )
                        else if (_emotionPercentages.isEmpty)
                          Text(
                            'No emotions yet'.tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: context.secondaryTextColor,
                            ),
                          )
                        else
                          ...getEmotionData().asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final iconPaths = {
                              'Happy': 'assets/svg/emoji-happy.svg',
                              'Sad': 'assets/svg/angryInsight.svg',
                              'Angry': 'assets/svg/angryInsight.svg',
                              'Excited': 'assets/svg/relaxedInsight.svg',
                              'Anxious': 'assets/svg/jealousInsight.svg',
                              'Relaxed': 'assets/svg/relaxedInsight.svg',
                              'Stressed': 'assets/svg/jealousInsight.svg',
                              'Grateful': 'assets/svg/emoji-happy.svg',
                              'Confused': 'assets/svg/jealousInsight.svg',
                              'Confident': 'assets/svg/relaxedInsight.svg',
                            };

                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 16),
                                _buildLegendItem(
                                  iconPaths[data.emotion] ?? 'assets/svg/emoji-happy.svg',
                                  '${data.percentage.toStringAsFixed(0)}%',
                                  data.emotion,
                                  data.color,
                                ),
                              ],
                            );
                          }).toList(),
                      ],
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

  Widget _buildLifeGoalsBox() {
    return Container(
      width: double.infinity,
      height: _goalsData.isEmpty ? 152 :_goalsData.length < 5 ? (40 + 70.0 * _goalsData.length) : 250.0, // Adjust height based on content
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with title and dropdown arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Life Goals'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: context.primaryTextColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Goals list or empty state
            Expanded(
              child: _isLoadingGoals
                  ? Center(
                child: CircularProgressIndicator(
                  color: context.primaryTextColor,
                  strokeWidth: 2,
                ),
              )
                  : _goalsData.isEmpty
                  ? _buildEmptyGoalsState()
                  : _buildGoalsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.track_changes_outlined,
          size: 32,
          color: context.secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Text(
          'No active goals yet'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your first goal to see it here'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsList() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), // Parent handles scrolling
      child: Column(
        children: [
          for (int index = 0; index < _goalsData.length; index++) ...[
            _buildGoalItemFromData(_goalsData[index]),
            if (index < _goalsData.length - 1) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                width: double.infinity,
                color: context.isDarkMode
                    ? const Color(0xFF505050)
                    : const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }



  Widget _buildGoalItemFromData(Map<String, dynamic> goalData) {
    final String title = goalData['title'] ?? 'Untitled Goal';
    final Timestamp? createdAt = goalData['createdAt'] as Timestamp?;
    final Timestamp? lastProgress = goalData['lastProgress'] as Timestamp?;

    // Format dates
    String subtitle = '';
    if (createdAt != null) {
      final createdDate = createdAt.toDate();
      final createdFormatted = CreateGoalServices.formatDate(createdAt);
      subtitle = 'Started $createdFormatted';

      if (lastProgress != null) {
        final lastProgressFormatted = CreateGoalServices.formatDate(lastProgress);
        subtitle += ' • Last Progress $lastProgressFormatted';
      } else {
        subtitle += ' • No progress yet';
      }
    } else {
      subtitle = 'No date available';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => EntriesInsightScreen(goalData:goalData,
                )
            )
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: context.secondaryTextColor,
            size: 20,
          ),
        ],
      ),
    );
  }




  Widget _buildMoodCalendarBox() {
    return Container(
      width: double.infinity,
      height: selectedMoodPeriod == 'Weekly' ? 300 : 370, // Shorter for weekly view
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top section with calendar icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/calendar.svg',
                ),
                const SizedBox(width: 8),
                Text(
                  'Mood Calendar'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Period selector with arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedMoodPeriod == 'Weekly') {
                        currentWeekOffset++;
                      } else {
                        if (currentCalendarMonthIndex > 0) {
                          currentCalendarMonthIndex--;
                          selectedCalendarMonth = calendarMonths[currentCalendarMonthIndex];
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      size: 12,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getCalendarPeriodLabel(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedMoodPeriod == 'Weekly') {
                        if (currentWeekOffset > 0) {
                          currentWeekOffset--;
                        }
                      } else {
                        if (currentCalendarMonthIndex < calendarMonths.length - 1) {
                          currentCalendarMonthIndex++;
                          selectedCalendarMonth = calendarMonths[currentCalendarMonthIndex];
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      size: 12,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Calendar view
            Expanded(
              child: selectedMoodPeriod == 'Weekly'
                  ? _buildWeeklyCalendarView()
                  : _buildMonthlyCalendarView(),
            ),

            const SizedBox(height: 12),
            // Gradient line
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFAA85),
                    const Color(0xFF7AE9FF),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 8),
            // Worst and Good labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Worst'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                  ),
                ),
                Text(
                  'Good'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getCalendarPeriodLabel() {
    if (selectedMoodPeriod == 'Weekly') {
      if (currentWeekOffset == 0) {
        return 'This Week'.tr();
      } else if (currentWeekOffset == 1) {
        return 'Last Week'.tr();
      } else {
        return '${currentWeekOffset + 1} ${'Weeks Ago'.tr()}';
      }
    } else {
      return selectedCalendarMonth.tr();
    }
  }


  Widget _buildWeeklyCalendarView() {
    final now = DateTime.now();
    final weekStart = _getStartOfWeek(now).subtract(Duration(days: 7 * currentWeekOffset));

    return Column(
      children: [
        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Week row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              final dateString = _getDateString(date);

              // Use the same alternating color pattern as monthly view
              Color backgroundColor;
              if (index % 4 == 0 || index % 4 == 2) {
                backgroundColor = const Color(0x40FFAA85); // #FFAA8540 with 25% opacity
              } else {
                backgroundColor = const Color(0x407AE9FF); // #7AE9FF40 with 25% opacity
              }

              return Expanded(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(25), // Fully rounded like monthly view
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCalendarView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SfCalendar(
        view: CalendarView.month,
        backgroundColor: Colors.transparent,
        headerHeight: 0,
        viewHeaderHeight: 40,
        monthViewSettings: MonthViewSettings(
          showAgenda: false,
          appointmentDisplayMode: MonthAppointmentDisplayMode.none,
          monthCellStyle: MonthCellStyle(
            backgroundColor: Colors.transparent,
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.primaryTextColor,
            ),
            trailingDatesTextStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.secondaryTextColor,
            ),
            leadingDatesTextStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.secondaryTextColor,
            ),
          ),
        ),
        viewHeaderStyle: ViewHeaderStyle(
          backgroundColor: Colors.transparent,
          dayTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.secondaryTextColor,
          ),
        ),
        cellBorderColor: Colors.transparent,
        monthCellBuilder: (BuildContext context, MonthCellDetails details) {
          // Get column index (0-6 for Sunday-Saturday)
          int columnIndex = (details.date.day + DateTime(details.date.year, details.date.month, 1).weekday - 1) % 7;

          Color backgroundColor;
          if (columnIndex % 4 == 0 || columnIndex % 4 == 2) {
            backgroundColor = const Color(0x40FFAA85); // #FFAA8540 with 25% opacity
          } else {
            backgroundColor = const Color(0x407AE9FF); // #7AE9FF40 with 25% opacity
          }

          return Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25), // Fully rounded
            ),
            margin: const EdgeInsets.all(3),
            child: Center(
              child: Text(
                '${details.date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: details.date.month == DateTime.now().month
                      ? context.primaryTextColor
                      : context.secondaryTextColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String svgPath, String percentage, String label, Color color) {
    return Row(
      children: [
        // Custom SVG icon
        SvgPicture.asset(
          svgPath,
        ),
        const SizedBox(width: 8),
        // Percentage and label
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: percentage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor, // Use theme color
                  ),
                ),
                TextSpan(
                  text: ' $label',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.primaryTextColor, // Use theme color
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ActivityData> getActivityData() {
    if (_activityPercentages.isEmpty) {
      // Return default data if no activities
      return [
        ActivityData('No Data', 0, const Color(0xFF868E9D)),
      ];
    }

    // Convert the percentages map to ActivityData list
    List<ActivityData> activityDataList = [];

    // Define colors for different categories
    final Map<String, Color> categoryColors = {
      'Family': const Color(0xFF1F1F1F),
      'Friends': const Color(0xFF868E9D),
      'Social': const Color(0xFF023E8A),
      'Personal': const Color(0xFF1D79ED),
      'Relationships': const Color(0xFF505050),
    };

    // Sort by percentage (highest first) and take top 3
    var sortedEntries = _activityPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topThree = sortedEntries.take(3); // This line limits to top 3

    for (var entry in topThree) {
      activityDataList.add(
        ActivityData(
          entry.key,
          entry.value,
          categoryColors[entry.key] ?? const Color(0xFF868E9D),
        ),
      );
    }

    return activityDataList;
  }

  List<EmotionData> getEmotionData() {
    if (_emotionPercentages.isEmpty) {
      // Return default data if no emotions
      return [
        EmotionData('No Data', 0, const Color(0xFF868E9D)),
      ];
    }

    // Convert the percentages map to EmotionData list
    List<EmotionData> emotionDataList = [];

    // Define colors for different emotions


    // Sort by percentage (highest first) and take top 3
    var sortedEntries = _emotionPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topThree = sortedEntries.take(3);
    var defaultColors = [
      const Color(0xFF000000), // Black
      const Color(0xFF607D8B), // Light Grey
      const Color(0xFF2196F3), // Blue
    ];
    var index = 0;
    for (var entry in topThree) {
      emotionDataList.add(
        EmotionData(
          entry.key,
          entry.value,
          defaultColors[index % 3],
        ),
      );
      index++;
    }

    return emotionDataList;
  }

  List<ChartData> getLastMonthData() {
    if (!_hasSufficientMoodData) {
      return [];
    }

    if (selectedMoodPeriod == 'Weekly') {
      return getLastWeekMoodData();
    } else {
      return getLastMonthMoodData();
    }
  }

  List<ChartData> getAverageData() {
    if (!_hasSufficientMoodData || _dailyMoods.isEmpty) {
      return [];
    }

    // Calculate overall average mood
    double totalMood = 0;
    int count = 0;

    _dailyMoods.forEach((date, moodIndex) {
      if (moodIndex > 0) {
        totalMood += moodIndex.toDouble();
        count++;
      }
    });

    if (count == 0) return [];

    final averageMood = totalMood / count;
    final averageChartValue = averageMood * 12.0; // Scale to 0-60

    // Create average line data based on current period
    final currentData = getThisMonthData();
    if (currentData.isEmpty) return [];

    return currentData.map((data) =>
        ChartData(data.x, averageChartValue)
    ).toList();
  }



  List<ChartData> getThisMonthData() {
    if (!_hasSufficientMoodData) {
      return [];
    }

    if (selectedMoodPeriod == 'Weekly') {
      return getWeeklyMoodData();
    } else {
      return getMonthlyMoodData();
    }
  }



  Widget _buildMoodChart() {
    return Stack(
      children: [
        Column(
          children: [
            if (_isLoadingMoodData)
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.primaryTextColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (!_hasSufficientMoodData)
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        size: 48,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Not enough data yet'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.cardBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete at least 5 mood check-ins\nto see your mood trends'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_dailyMoods.length}/5 ${'check-ins completed'.tr()}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D79ED),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: SfCartesianChart(
                  backgroundColor: Colors.transparent,
                  plotAreaBorderWidth: 0,
                  margin: const EdgeInsets.all(0),
                  borderWidth: 0,
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    textStyle: TextStyle(
                      color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    iconHeight: 8,
                    iconWidth: 16,
                    itemPadding: 20,
                  ),
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(
                      color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
                      fontSize: 12,
                    ),
                    axisLine: AxisLine(width: 0),
                    majorTickLines: MajorTickLines(width: 0),
                    majorGridLines: MajorGridLines(width: 0),
                    plotOffset: 0,
                    labelPlacement: LabelPlacement.onTicks,
                    edgeLabelPlacement: EdgeLabelPlacement.shift,
                    labelIntersectAction: AxisLabelIntersectAction.none,
                    labelAlignment: LabelAlignment.center,
                    rangePadding: ChartRangePadding.round,
                  ),
                  primaryYAxis: NumericAxis(
                    isVisible: false,
                    majorGridLines: MajorGridLines(width: 0),
                    plotOffset: 0,
                    minimum: 0,
                    maximum: 60,
                  ),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    SplineSeries<ChartData, String>(
                      dataSource: getLastMonthData(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
                      width: 4,
                      splineType: SplineType.natural,
                      name: 'Last ${selectedMoodPeriod}',
                    ),
                    SplineAreaSeries<ChartData, String>(
                      dataSource: getThisMonthData(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      borderColor: const Color(0xFF1D79ED),
                      borderWidth: 4,
                      splineType: SplineType.natural,
                      name: 'This ${selectedMoodPeriod}',
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1D79ED).withOpacity(0.78),
                          const Color(0x001D79ED),
                        ],
                      ),
                    ),
                    LineSeries<ChartData, String>(
                      dataSource: getAverageData(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      color: context.secondaryTextColor,
                      width: 2,
                      dashArray: <double>[5, 5],
                      name: 'Average',
                    ),
                  ],
                ),
              ),
          ],
        ),
        _buildPeriodDropdown(),
      ],
    );
  }

// Add toggle for Weekly/Monthly view (add this widget where you have the "Monthly" dropdown)
  Widget _buildPeriodSelector() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showPeriodDropdown = !_showPeriodDropdown;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.secondaryBackgroundColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svg/calendar.svg'),
            const SizedBox(width: 8),
            Text(
              selectedMoodPeriod.tr(),
              style: TextStyle(
                color: context.isDarkMode ? context.primaryTextColor : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showPeriodDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    if (!_showPeriodDropdown) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      right: 20,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: context.cardBackgroundColor,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.secondaryTextColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption('Weekly'),
              Divider(height: 1, color: context.secondaryTextColor.withOpacity(0.2)),
              _buildPeriodOption('Monthly'),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPeriodOption(String period) {
    final isSelected = selectedMoodPeriod == period;

    return InkWell(
      onTap: () {
        setState(() {
          selectedMoodPeriod = period;
          _showPeriodDropdown = false;
        });
        _loadMoodGraphData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              period,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1D79ED) : context.primaryTextColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: const Color(0xFF1D79ED),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildPercentageIndicator() {
    if (!_hasSufficientMoodData || _percentageChange == 0) {
      return const SizedBox.shrink();
    }

    final isPositive = _percentageChange > 0;
    final displayPercentage = _percentageChange.abs().toStringAsFixed(0);

    return Flexible(  // Add this
      child: Row(
        children: [
          SvgPicture.asset(
            isPositive ? 'assets/svg/up.svg' : 'assets/svg/down.svg',
          ),
          const SizedBox(width: 8),
          Flexible(  // Also wrap the Text
            child: Text(
              '${displayPercentage}% ${isPositive ? 'Better' : 'Lower'} than last ${selectedMoodPeriod.toLowerCase()}',
              style: TextStyle(
                color: context.isDarkMode ? context.primaryTextColor : context.cardBackgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,  // Add this
            ),
          ),
        ],
      ),
    );
  }

}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
