
import 'package:chewata/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key, 
    required this.image, 
    required this.title, 
    required this.subTitle,
  });

  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    // Get dimensions based on the current context
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    return Padding(
      padding: const EdgeInsets.all(Tsize.defaultSpace),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.05), // Offset for the skip button
          Lottie.asset(
            image,
            width: screenWidth * 0.8,
            height: screenHeight * 0.5,
            fit: BoxFit.contain,
            frameRate: FrameRate.max,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'WinkySans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Tsize.spaceBtwItems),
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'WinkySans'
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}