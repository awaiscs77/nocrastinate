import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../ApiServices/CreateGoalServices.dart';
import '../../../ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

class EntriesInsightScreen extends StatefulWidget {
  final Map<String, dynamic> goalData;

  const EntriesInsightScreen({
    Key? key,
    required this.goalData,
  }) : super(key: key);

  @override
  _EntriesInsightScreenState createState() => _EntriesInsightScreenState();
}

class _EntriesInsightScreenState extends State<EntriesInsightScreen> {
  final CreateGoalServices _goalService = CreateGoalServices();

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  Widget _buildEntryItem(Map<String, dynamic> entry) {
    final bool hadProgress = entry['sessionType'] == 'progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(entry['timestamp']),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.accent
                      : Color(0xFF023E8A),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: 24,
                child: SvgPicture.asset(
                  'assets/svg/taskProgress.svg',
                  fit: BoxFit.fill,
                  colorFilter: Theme.of(context).brightness == Brightness.dark
                      ? ColorFilter.mode(AppColors.accent, BlendMode.srcIn)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Right column with content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Self Evaluation container
                ThemedContainer(
                  width: 150,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Self Evaluation'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Done Anything row
                Row(
                  children: [
                    Text(
                      'Done Anything?'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 30,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.accent
                            : Color(0xFF023E8A),
                        borderRadius: BorderRadius.circular(55),
                      ),
                      child: Center(
                        child: Text(
                          hadProgress ? 'Yes'.tr() : 'No'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // How much effort row (only show if progress was made)
                if (hadProgress) ...[
                  Row(
                    children: [
                      Text(
                        'How much effort?'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accent
                              : Color(0xFF023E8A),
                          borderRadius: BorderRadius.circular(55),
                        ),
                        child: Center(
                          child: Text(
                            '${entry['effortLevel']?.toInt() ?? 0}%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Show mood and reason if no progress
                if (!hadProgress) ...[
                  if (entry['selectedMood'] != null) ...[
                    Row(
                      children: [
                        Text(
                          'Mood:'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Color(0xFF023E8A),
                            borderRadius: BorderRadius.circular(55),
                          ),
                          child: Text(
                            entry['selectedMood'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (entry['noProgressReason'] != null &&
                      entry['noProgressReason'].toString().isNotEmpty) ...[
                    Text(
                      'Why no progress?'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ThemedContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(8),
                      child: Text(
                        entry['noProgressReason'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // How could you improve commitment
                if (entry['improvementPlan'] != null &&
                    entry['improvementPlan'].toString().isNotEmpty) ...[
                  Text(
                    'How could you improve commitment?'.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ThemedContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      entry['improvementPlan'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String goalTitle = widget.goalData['title'] ?? 'Untitled Goal';
    final String goalId = widget.goalData['id'];

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting

      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            child: SvgPicture.asset(
              'assets/svg/WhiteRoundBGBack.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          'Life Goals - Insights'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Top section with goal title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '"$goalTitle"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // StreamBuilder for entries
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _goalService.getGoalProgressSessions(goalId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.primaryTextColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading entries'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: context.primaryTextColor,
                        ),
                      ),
                    );
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        'No progress entries yet'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: context.primaryTextColor.withOpacity(0.5),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildEntryItem(entries[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}