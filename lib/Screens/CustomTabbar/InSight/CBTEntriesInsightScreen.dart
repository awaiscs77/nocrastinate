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
  final bool isWhatIfChallenge; // true = What If Challenge, false = Cost Benefit

  const CBTEntriesInsightScreen({
    Key? key,
    required this.isWhatIfChallenge,
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

  Future<List<Map<String, dynamic>>> _getEntries() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in');
        return [];
      }

      print('DEBUG: User ID: ${user.uid}');

      final practiceType = widget.isWhatIfChallenge
          ? MindPracticeService.whatIfChallengeType
          : MindPracticeService.costBenefitType;

      print('DEBUG: Looking for practice type: $practiceType');
      print('DEBUG: isWhatIfChallenge: ${widget.isWhatIfChallenge}');

      // First, check all documents without filters
      final allDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mind_practices')
          .get();

      print('DEBUG: Total documents in collection: ${allDocs.docs.length}');

      for (var doc in allDocs.docs) {
        final data = doc.data();
        print('DEBUG: Doc ${doc.id} - practiceType: ${data['practiceType']}, completed: ${data['completed']}');
      }

      // Now try with filters
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mind_practices')
          .where('practiceType', isEqualTo: practiceType)
          .where('completed', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Filtered documents: ${snapshot.docs.length}');

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
          widget.isWhatIfChallenge ? 'What If Challenge - Insights' : 'Cost Benefit - Insights',
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
                  widget.isWhatIfChallenge
                      ? '"What If" Challenge'
                      : '"Cost-Benefit" Analysis',
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
                            'Error loading entries',
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
                      return widget.isWhatIfChallenge
                          ? _buildWhatIfEntry(entries[index])
                          : _buildCostBenefitEntry(entries[index]);
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
                      child:  Center(
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
                      child:  Center(
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
}