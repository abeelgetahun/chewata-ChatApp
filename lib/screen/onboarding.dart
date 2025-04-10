import 'package:chewata/controller/onboarding_controller.dart';
import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/screen/widgets/onboarding_dot_navigation.dart';
import 'package:chewata/screen/widgets/onboarding_next_button.dart';
import 'package:chewata/screen/widgets/onboarding_page.dart';
import 'package:chewata/screen/widgets/onboarding_skip.dart';
import 'package:chewata/utils/constants/color.dart';
import 'package:chewata/utils/constants/image_strings.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/constants/text_strings.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:iconsax/iconsax.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme-aware text colors
    final controller = Get.put(OnBoardingController());
                       
    return Scaffold(
      body:Stack(
          children: [
            // Horizontal scrollable
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.updatePageIndicator,
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
      );
  }
}
