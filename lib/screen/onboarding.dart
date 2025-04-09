import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/utils/constants/image_strings.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme-aware text colors
    final textColor = Theme.of(context).brightness == Brightness.dark ? 
                       Colors.white : Colors.black;
                       
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Horizontal scrollable
            PageView(
              physics: const BouncingScrollPhysics(),
              children: const [
                OnBoardingPage(
                  image: TImages.onBoardingImage1,
                  title: TText.onBoardingTitle1,
                  subTitle: TText.onBoardingSubTitle1
                ), 
                OnBoardingPage(
                  image: TImages.onBoardingImage2,
                  title: TText.onBoardingTitle2,
                  subTitle: TText.onBoardingSubTitle2
                ),
                OnBoardingPage(
                  image: TImages.onBoardingImage3,
                  title: TText.onBoardingTitle3,
                  subTitle: TText.onBoardingSubTitle3
                ), 
              ],
            ),
            
            // Skip button with better visibility
            Positioned(
              top: 10.0, // Fixed positioning from the top
              right: Tsize.defaultSpace, 
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    // Your navigation logic here
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              color: Theme.of(context).colorScheme.primary
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Tsize.spaceBtwItems),
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}