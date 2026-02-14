import 'package:flutter/material.dart';

class TaskPopupScreen extends StatefulWidget {
  const TaskPopupScreen({Key? key}) : super(key: key);

  @override
  _TaskPopupScreenState createState() => _TaskPopupScreenState();
}

class _TaskPopupScreenState extends State<TaskPopupScreen> {
  List<bool> checkboxStates = [false, false, false];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenHeight < 600;

    // Responsive dimensions
    final dialogWidth = isTablet
        ? screenWidth * 0.5
        : screenWidth * 0.9;
    final dialogHeight = isSmallScreen
        ? screenHeight * 0.8
        : screenHeight * 0.5;
    final maxDialogHeight = isSmallScreen ? 400.0 : 450.0;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Container(
              width: dialogWidth,
              height: dialogHeight.clamp(300.0, maxDialogHeight),
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
                minHeight: 300,
                maxHeight: maxDialogHeight,
              ),
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Become top player in team",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: isTablet ? 45 : 40,
                          width: isTablet ? 45 : 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.black,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Progress and Target Row - Responsive layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 300) {
                        // Stack vertically on very small screens
                        return Column(
                          children: [
                            _buildProgressContainer(context, "Last Progress", "Feb 28", 'assets/trending.png'),
                            SizedBox(height: screenHeight * 0.01),
                            _buildProgressContainer(context, "Target Date", "May 18", 'assets/target.png'),
                          ],
                        );
                      } else {
                        // Side by side layout
                        return Row(
                          children: [
                            Expanded(
                              child: _buildProgressContainer(context, "Last Progress", "Feb 28", 'assets/trending.png'),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildProgressContainer(context, "Target Date", "May 18", 'assets/target.png'),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenHeight * 0.025),

                  // Tasks Title
                  Text(
                    "Tasks",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Checkbox Options - Scrollable if needed
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCheckboxOption(
                            0,
                            "Learn to be better at defense",
                            context,
                          ),
                          _buildCheckboxOption(
                            1,
                            "Listen to player calls more attentively",
                            context,
                          ),
                          _buildCheckboxOption(
                            2,
                            "Watch yt vids of pros to learn more",
                            context,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Action Buttons - Responsive layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 280) {
                        // Stack vertically on very small screens
                        return Column(
                          children: [
                            _buildActionButton(
                              context,
                              "Do it later",
                              false,
                                  () => Navigator.pop(context, false),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildActionButton(
                              context,
                              "Do it now",
                              true,
                                  () => Navigator.pop(context, true),
                            ),
                          ],
                        );
                      } else {
                        // Side by side layout
                        return Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                "Do it later",
                                false,
                                    () => Navigator.pop(context, false),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                "Do it now",
                                true,
                                    () => Navigator.pop(context, true),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressContainer(BuildContext context, String label, String value, String assetPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            assetPath,
            width: isTablet ? 20 : 16,
            height: isTablet ? 20 : 16,
          ),
          SizedBox(width: screenWidth * 0.02),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                children: [
                  TextSpan(text: "$label "),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
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

  Widget _buildActionButton(BuildContext context, String text, bool isPrimary, VoidCallback onPressed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Container(
      height: isTablet ? 50 : 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isPrimary ? Colors.black : Colors.white,
        border: isPrimary ? null : Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(55),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : Colors.black,
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(int index, String text, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                checkboxStates[index] = !checkboxStates[index];
              });
            },
            child: Container(
              width: isTablet ? 24 : 20,
              height: isTablet ? 24 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: checkboxStates[index] ? Color(0xFF023E8A) : Colors.grey,
                  width: 2,
                ),
                color: checkboxStates[index] ? Color(0xFF023E8A) : Colors.transparent,
              ),
              child: checkboxStates[index]
                  ? Icon(
                Icons.check,
                size: isTablet ? 16 : 12,
                color: Colors.white,
              )
                  : null,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}