import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/ThemeManager.dart';

class CBTScreen extends StatelessWidget {
  const CBTScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
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
        centerTitle: true,
        title: Text(
          'What Is CBT?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              Text(
                'Cognitive Behavioral Therapy (CBT) is a type of mental health treatment that helps you understand how your thoughts, feelings, and actions are connected.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'It\'s built on the idea that our thoughts influence our emotions and behaviors. When unhelpful patterns—like overthinking or self-doubt—arise, CBT helps us notice them and make small, positive changes.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // How Does CBT Work?
              Text(
                'How Does CBT Work?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildBulletPoint(
                context,
                'Identify unhelpful thoughts',
                'that might be causing you distress, like worrying too much or assuming the worst will happen.',
              ),
              const SizedBox(height: 12),

              _buildBulletPoint(
                context,
                'Challenge these thoughts',
                'by learning to see things in a more balanced and realistic way.',
              ),
              const SizedBox(height: 12),

              _buildBulletPoint(
                context,
                'Take action',
                'by engaging in activities that are meaningful or enjoyable, even if you don\'t feel like it at first. This can help improve your mood and break the cycle of negativity.',
              ),
              const SizedBox(height: 32),

              // Key Ideas in CBT
              Text(
                'Key Ideas in CBT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildBulletPoint(
                context,
                'Thoughts, feelings, and actions are connected.',
                'For example, if you think, "I always mess things up," you might feel anxious or sad, and you might avoid trying new things. CBT helps you change that thought to something like, "I can do things well if I try," which can lead to better feelings and actions.',
              ),
              const SizedBox(height: 12),

              _buildBulletPoint(
                context,
                'Cognitive distortions are unhelpful thinking patterns, like:',
                null,
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubBulletPoint(
                      context,
                      'Seeing things as all good or all bad (e.g., "If I fail this test, I\'m a total failure").',
                    ),
                    const SizedBox(height: 8),
                    _buildSubBulletPoint(
                      context,
                      'Assuming one small mistake means everything will go wrong.',
                    ),
                    const SizedBox(height: 8),
                    _buildSubBulletPoint(
                      context,
                      'CBT teaches you to recognize these patterns and replace them with more realistic thoughts.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildBulletPoint(
                context,
                'Taking action matters.',
                'Sometimes, when we feel down, we avoid doing things that could help us feel better. CBT encourages you to try activities you enjoy or find meaningful, which can lift your mood and boost motivation.',
              ),
              const SizedBox(height: 32),

              // Why is CBT Helpful?
              Text(
                'Why is CBT Helpful?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'CBT is a hands-on approach that gives you tools to manage challenges like stress, anxiety, or depression. It\'s not about dwelling on the past—it\'s about learning skills you can use right now to feel better and handle life\'s ups and downs.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String title, String? description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.primaryTextColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                    height: 1.5,
                  ),
                ),
                if (description != null)
                  TextSpan(
                    text: ' $description',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubBulletPoint(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: context.secondaryTextColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: context.primaryTextColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}