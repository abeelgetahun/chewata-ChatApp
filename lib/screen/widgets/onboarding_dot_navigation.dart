import 'package:chewata/controller/onboarding_controller.dart';
import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/utils/constants/color.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class onBordingDotNavigation extends StatelessWidget {
  const onBordingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    
    final controller = OnBoardingController.instance;
    final dark = THelperFunction.isDarkMode(context);
    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: TSize.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        count: 3,
        onDotClicked: controller.dotNavigationClick,
        effect: ExpandingDotsEffect(
          dotWidth: 10.0,
          dotHeight: 6.0,
          activeDotColor: dark ? TColor.light : TColor.dark
         
        )
      ),
    );
  }
}
