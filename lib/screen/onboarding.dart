import 'package:chewata/controller/onboarding_controller.dart';
import 'package:chewata/screen/widgets/onboarding_dot_navigation.dart';
import 'package:chewata/screen/widgets/onboarding_next_button.dart';
import 'package:chewata/screen/widgets/onboarding_page.dart';
import 'package:chewata/screen/widgets/onboarding_skip.dart';
import 'package:chewata/utils/constants/image_strings.dart';
import 'package:chewata/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Preload the login background image
    precacheImage(
      const AssetImage("assets/images/auth_images/login_background.jpg"),
      context,
    );

    final controller = Get.put(OnBoardingController());

    return Scaffold(
      body: Stack(
        children: [
          // Horizontal scrollable
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              OnBoardingPage(
                image: TImages.onBoardingImage1,
                title: TText.onBoardingTitle1,
                subTitle: TText.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage2,
                title: TText.onBoardingTitle2,
                subTitle: TText.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage3,
                title: TText.onBoardingTitle3,
                subTitle: TText.onBoardingSubTitle3,
              ),
            ],
          ),

          // Skip button with better visibility
          const onBoardingSkip(),

          // Smooth page indicator
          onBordingDotNavigation(),

          // Floating button
          onBoardingNextButton(),
        ],
      ),
    );
  }
}
