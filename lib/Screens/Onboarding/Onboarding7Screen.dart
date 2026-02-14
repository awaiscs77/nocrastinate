import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager
import 'Onboarding8Screen.dart';

class Onboarding7Screen extends StatelessWidget {
  const Onboarding7Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.blackSectionColor,
      body: CustomScrollView(
        slivers: [
          // Top section with graph
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top padding
                  const SizedBox(height: 40),

                  // Graph SVG with theme-aware coloring
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SvgPicture.asset(
                      'assets/svg/graph.svg',
                      // You can add color filters here if needed for theme adaptation
                    ),
                  ),

                  // 40 height padding
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Main scrollable content
          SliverFillRemaining(
            hasScrollBody: false,
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
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      // Main text
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                          children: const [
                            TextSpan(text: "Based on your answers, "),
                            TextSpan(
                              text: "Nocrastinate",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: " can help you to:"),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Section SVG with theme adaptation
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SvgPicture.asset(
                          'assets/svg/section.svg',
                          // Add color filter if needed for dark theme
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fist bump image with theme-aware container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? context.cardBackgroundColor.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          'assets/Oncoming Fist.png',
                          // You can add color filters here if the image needs theme adaptation
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Let's solidify it with a fist bump.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Button
                      SizedBox(
                        width: 229,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const Onboarding8Screen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.isDarkMode
                                ? Colors.white
                                : context.blackSectionColor,
                            disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                            // Add subtle shadow for better visibility in dark theme
                            shadowColor: context.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                          child: Text(
                            'Tap to continue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode
                                  ? context.backgroundColor
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
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