import 'package:flutter/material.dart';
import 'package:nocrastinate/ThemeManager.dart';

class PopupQuestionScreen extends StatelessWidget {
  final String title;
  final String yesString;
  final String noString;

  final VoidCallback? onYes;
  final VoidCallback? onNo;

  const PopupQuestionScreen({
    Key? key,
    required this.title,
    this.onYes,
    this.onNo,
    required this.yesString,
    required this.noString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBackgroundColor, // Use theme card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with flexible height
              const SizedBox(height: 10),

              // Question text - will expand based on content
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4, // Line height for better readability
                    color: context.primaryTextColor, // Use theme text color
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // No button
                  Expanded(
                    child: GestureDetector(
                      onTap: onNo ?? () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.cardBackgroundColor, // Use theme card background
                          border: Border.all(
                              color: context.blackSectionColor, // Use theme black section color
                              width: 1
                          ),
                          borderRadius: BorderRadius.circular(55),
                        ),
                        child: Text(
                          noString,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: context.blackSectionColor, // Use theme black section color
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Yes button
                  Expanded(
                    child: GestureDetector(
                      onTap: onYes ?? () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.blackSectionColor, // Use theme black section color
                          borderRadius: BorderRadius.circular(55),
                        ),
                        child: Text(
                          yesString,
                          style: TextStyle(
                            color: context.isDarkMode ? Colors.white : Colors.white, // Button text remains white
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}