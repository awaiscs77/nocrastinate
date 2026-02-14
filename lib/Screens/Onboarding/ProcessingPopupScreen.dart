import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../ThemeManager.dart';

class ProcessingPopupScreen extends StatefulWidget {
  const ProcessingPopupScreen({Key? key}) : super(key: key);

  @override
  State<ProcessingPopupScreen> createState() => _ProcessingPopupScreenState();
}

class _ProcessingPopupScreenState extends State<ProcessingPopupScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;
  bool _task1Complete = false;
  bool _task2Complete = false;
  bool _task3Complete = false;
  bool _allTasksComplete = false;

  final List<String> _tasks = [
    'Reviewing your responses...',
    'Preparing your plan...',
    'Calculating your total score...',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;

        // Update task completion based on progress
        if (_progress >= 33 && !_task1Complete) {
          _task1Complete = true;
        }
        if (_progress >= 66 && !_task2Complete) {
          _task2Complete = true;
        }
        if (_progress >= 100 && !_task3Complete) {
          _task3Complete = true;
          _allTasksComplete = true;

          // Auto-close after a brief delay and return true
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      });
    });

    // Start the animation
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  List<ChartData> _getChartData() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      ChartData('Progress', _progress, isDark ? AppColors.accent : const Color(0xFF1F1F1F)),
      ChartData('Remaining', 100 - _progress, isDark ? const Color(0xFF505050) : const Color(0xFFE0E0E0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 280,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCardBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Circle
                SizedBox(
                  width: 100,
                  height: 100,
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    series: <CircularSeries>[
                      DoughnutSeries<ChartData, String>(
                        dataSource: _getChartData(),
                        xValueMapper: (ChartData data, _) => data.category,
                        yValueMapper: (ChartData data, _) => data.value,
                        pointColorMapper: (ChartData data, _) => data.color,
                        strokeWidth: 0,
                        innerRadius: '70%',
                        radius: '100%',
                      ),
                    ],
                    annotations: [
                      CircularChartAnnotation(
                        widget: Text(
                          '${_progress.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task 1
                    _buildTaskRow(
                      taskText: _tasks[0],
                      isCompleted: _task1Complete,
                    ),
                    const SizedBox(height: 12),

                    // Task 2
                    _buildTaskRow(
                      taskText: _tasks[1],
                      isCompleted: _task2Complete,
                    ),
                    const SizedBox(height: 12),

                    // Task 3
                    _buildTaskRow(
                      taskText: _tasks[2],
                      isCompleted: _task3Complete,
                    ),

                    if (_allTasksComplete) ...[
                      const SizedBox(height: 20),
                      Text(
                        'We found the perfect\nplan for you!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskRow({
    required String taskText,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: isCompleted
              ? SvgPicture.asset(
            'assets/svg/Done.svg',
            width: 24,
            height: 24,
          )
              : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            taskText,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isCompleted
                  ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText)
                  : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText),
            ),
          ),
        ),
      ],
    );
  }
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}

// Updated function to handle the result
Future<bool?> showProcessingScreen(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false, // Prevent manual dismissal
    enableDrag: false, // Prevent drag to dismiss
    builder: (context) => const ProcessingPopupScreen(),
  );
}

// Usage example:
// final result = await showProcessingScreen(context);
// if (result == true) {
//   // Processing completed successfully
//   print('Processing completed!');
// }