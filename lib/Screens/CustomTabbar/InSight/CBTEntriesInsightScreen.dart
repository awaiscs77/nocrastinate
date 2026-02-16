import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../ApiServices/CreateGoalServices.dart';
import '../../../ApiServices/MindPracticeService.dart';
import '../../../ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

class CBTEntriesInsightScreen extends StatefulWidget {
  final String practiceType; // Practice type to display

  const CBTEntriesInsightScreen({
    Key? key,
    required this.practiceType,
  }) : super(key: key);

  @override
  _CBTEntriesInsightScreenState createState() => _CBTEntriesInsightScreenState();
}

class _CBTEntriesInsightScreenState extends State<CBTEntriesInsightScreen> {
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

  String _getPracticeTitle() {
    switch (widget.practiceType) {
      case MindPracticeService.whatIfChallengeType:
        return 'What If Challenge - Insights'.tr();
      case MindPracticeService.costBenefitType:
        return 'Cost Benefit - Insights'.tr();
      case MindPracticeService.gratitudeJournalType:
        return 'Gratitude Journal - Insights'.tr();
      case MindPracticeService.growthMindsetType:
        return 'Growth Mindset - Insights'.tr();
      case MindPracticeService.selfCompassionType:
        return 'Self Compassion - Insights'.tr();
      case MindPracticeService.selfEfficacyType:
        return 'Self Efficacy - Insights'.tr();
      default:
        return 'Practice Insights'.tr();
    }
  }

  String _getPracticeDisplayName() {
    switch (widget.practiceType) {
      case MindPracticeService.whatIfChallengeType:
        return '"What If" Challenge';
      case MindPracticeService.costBenefitType:
        return '"Cost-Benefit" Analysis';
      case MindPracticeService.gratitudeJournalType:
        return 'Gratitude Journal';
      case MindPracticeService.growthMindsetType:
        return 'Growth Mindset';
      case MindPracticeService.selfCompassionType:
        return 'Self Compassion';
      case MindPracticeService.selfEfficacyType:
        return 'Self Efficacy';
      default:
        return 'Practice';
    }
  }

  Future<List<Map<String, dynamic>>> _getEntries() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in');
        return [];
      }

      print('DEBUG: User ID: ${user.uid}');
      print('DEBUG: Looking for practice type: ${widget.practiceType}');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mind_practices')
          .where('practiceType', isEqualTo: widget.practiceType)
          .where('completed', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} documents');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading entries: $e');
      print('Error stack trace: ${StackTrace.current}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          _getPracticeTitle().tr(),
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
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _getPracticeDisplayName().tr(),
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

            // FutureBuilder for entries
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getEntries(),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading entries'.tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: context.primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        'No entries yet'.tr(),
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
                      return _buildEntryForType(entries[index]);
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

  Widget _buildEntryForType(Map<String, dynamic> entry) {
    switch (widget.practiceType) {
      case MindPracticeService.whatIfChallengeType:
        return _buildWhatIfEntry(entry);
      case MindPracticeService.costBenefitType:
        return _buildCostBenefitEntry(entry);
      case MindPracticeService.gratitudeJournalType:
        return _buildGratitudeJournalEntry(entry);
      case MindPracticeService.growthMindsetType:
        return _buildGrowthMindsetEntry(entry);
      case MindPracticeService.selfCompassionType:
        return _buildSelfCompassionEntry(entry);
      case MindPracticeService.selfEfficacyType:
        return _buildSelfEfficacyEntry(entry);
      default:
        return Container();
    }
  }

  Widget _buildCostBenefitEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                // Practice Type container
                ThemedContainer(
                  width: 180,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Cost Benefit Analysis'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Behavior Evaluated
                Text(
                  'Behavior Evaluated:'.tr(),
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
                    data?['behaviorToEvaluate'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pros Section
                Row(
                  children: [
                    Container(
                      height: 20,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF023E8A),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Pros'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ThemedContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    data?['pros'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cons Section
                Row(
                  children: [
                    Container(
                      height: 20,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF023E8A),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Cons'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ThemedContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    data?['cons'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;
    final initialLikelihood = data?['initialLikelihood'] as double? ?? 0.0;
    final finalLikelihood = data?['finalLikelihood'] as double? ?? 0.0;
    final reduction = initialLikelihood - finalLikelihood;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                // Practice Type container
                ThemedContainer(
                  width: 160,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'What If Challenge',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Fear Scenario
                Text(
                  'Fear Scenario:'.tr(),
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
                    data?['fearScenario'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Likelihood Progress
                Row(
                  children: [
                    Text(
                      'Initial Likelihood:'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 45,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.accent
                            : Color(0xFF023E8A),
                        borderRadius: BorderRadius.circular(55),
                      ),
                      child: Center(
                        child: Text(
                          '${initialLikelihood.round()}%',
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

                Row(
                  children: [
                    Text(
                      'Final Likelihood:'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 45,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.accent
                            : Color(0xFF023E8A),
                        borderRadius: BorderRadius.circular(55),
                      ),
                      child: Center(
                        child: Text(
                          '${finalLikelihood.round()}%',
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

                if (reduction > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "${'Reduced by'.tr()} ${reduction.round()}%",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Best Outcome
                Text(
                  'Best Possible Outcome:'.tr(),
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
                    data?['bestOutcome'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGratitudeJournalEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                height: 150,
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
                // Practice Type container
                ThemedContainer(
                  width: 160,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Gratitude Journal'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Grateful For
                Text(
                  'Grateful For:'.tr(),
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
                    data?['gratefulThing'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Why Grateful
                Text(
                  'Why It Makes Me Grateful:'.tr(),
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
                    data?['whyGrateful'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMindsetEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                height: 220,
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
                // Practice Type container
                ThemedContainer(
                  width: 160,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Growth Mindset'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Difficulty
                Text(
                  'Current Difficulty:'.tr(),
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
                    data?['difficulty'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Opportunity
                Text(
                  'Turn Into Opportunity:'.tr(),
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
                    data?['opportunity'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Past Learning
                Text(
                  'Past Learning:'.tr(),
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
                    data?['pastLearning'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCompassionEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                height: 220,
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
                // Practice Type container
                ThemedContainer(
                  width: 160,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Self Compassion'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Self Criticism
                Text(
                  'Self-Criticism:'.tr(),
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
                    data?['selfCriticism'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Emotion
                Row(
                  children: [
                    Text(
                      'Emotion:'.tr(),
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
                        (data?['emotion'] ?? '').toString().tr(),
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
                const SizedBox(height: 12),

                // Kindness
                Text(
                  'Showing Kindness:'.tr(),
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
                    data?['kindness'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfEfficacyEntry(Map<String, dynamic> entry) {
    final data = entry['data'] as Map<String, dynamic>?;
    final timestamp = entry['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with date and SVG
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timestamp != null)
                Text(
                  _formatDate(timestamp).tr(),
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
                height: 150,
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
                // Practice Type container
                ThemedContainer(
                  width: 160,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  borderRadius: BorderRadius.circular(35),
                  child: Center(
                    child: Text(
                      'Self Efficacy'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Doubt
                Text(
                  'Doubt About Ability:'.tr(),
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
                    data?['doubt'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Past Success
                Text(
                  'Past Success:'.tr(),
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
                    data?['pastSuccess'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}