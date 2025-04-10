import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/screen/widgets/onboarding_dot_navigation.dart';
import 'package:chewata/screen/widgets/onboarding_page.dart';
import 'package:chewata/screen/widgets/onboarding_skip.dart';
import 'package:chewata/utils/constants/color.dart';
import 'package:chewata/utils/constants/image_strings.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/constants/text_strings.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:iconsax/iconsax.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme-aware text colors
                       
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
            const onBoardingSkip(),

            //smoth page indicator
            onBordingDotNavigation(),

            //floating button
            onBoardingNextButton()
          ],
        ),
      ),
    );
  }
}

class onBoardingNextButton extends StatelessWidget {
  const onBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark= THelperFunction.isDarkMode(context);
    return Positioned(
      right: Tsize.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () {}, 
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: dark? TColor.light: TColor.primary,
        ),
        child: const Icon(Iconsax.arrow_right_3,),
      ));
  }
}
