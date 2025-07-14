import 'package:flutter/material.dart';

// inspired from https://medium.com/@mobileatexxeta/onboarding-flow-with-flutter-80e7cbddcff4

class TutorialPage extends StatelessWidget {
  final Color color;
  final String image;
  final String? title;
  final String subtitle;

  const TutorialPage(
      {super.key,
      required this.color,
      required this.image,
      this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    const double verticalSpacing = 20;
    const double horizontalSpacing = 20;

    // OnboardingPage
    return Container(
      padding: const EdgeInsets.only(
        left: horizontalSpacing,
        right: horizontalSpacing,
      ),
      color: color, // BackgroundColor
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: verticalSpacing),
          if (title != null)
            ...[
              Center(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: verticalSpacing),
            ],
          // Subtitle
          Center(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
