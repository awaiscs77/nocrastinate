import 'package:flutter/material.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager
import 'Onboarding7Screen.dart';

class Onboarding6Screen extends StatelessWidget {
  const Onboarding6Screen({Key? key}) : super(key: key);

  Widget _buildMetricView(
      BuildContext context,
      String percentage,
      String metricName,
      double progressValue,
      ) {
    // Determine color based on progress value
    Color getMetricColor(double value) {
      if (value >= 0.7) return AppColors.error;      // Red for high values
      if (value >= 0.4) return AppColors.warning;    // Orange for medium values
      return AppColors.success;                       // Green for low values
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  percentage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              metricName,
              style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // Progress bar using Stack
            Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: context.isDarkMode
                        ? AppColors.darkBorder.withOpacity(0.3)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                // Progress bar
                FractionallySizedBox(
                  widthFactor: progressValue,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          getMetricColor(progressValue).withOpacity(0.7),
                          getMetricColor(progressValue),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'High',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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

                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '48',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                // Score row
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Your score is',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 69,
                      height: 41,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          'High',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Here's a breakdown of your past month",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Three metric views with theme support
                      _buildMetricView(context, '48%', 'Anxiety Level', 0.48),
                      const SizedBox(height: 24),
                      _buildMetricView(context, '32%', 'Depression Level', 0.32),
                      const SizedBox(height: 24),
                      _buildMetricView(context, '80%', 'Stress Level', 0.80),
                      const SizedBox(height: 24),

                      Text(
                        "Based on your answers previously.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        child: SizedBox(
                          width: 138,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => Onboarding7Screen())
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.isDarkMode
                                  ? Colors.white
                                  :context.blackSectionColor,
                              disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child:  Text(
                              'Next',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode ? context.backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom safe area padding
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}