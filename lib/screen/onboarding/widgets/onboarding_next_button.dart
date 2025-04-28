import 'package:chewata/controller/onboarding_controller.dart';
import 'package:chewata/utils/helper_functions.dart';
import 'package:chewata/utils/constants/color.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class onBoardingNextButton extends StatelessWidget {
  const onBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunction.isDarkMode(context);
    final controller = OnBoardingController.instance;
    
    return Positioned(
      right: TSize.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: Obx(
        () => ElevatedButton(
          onPressed: () => controller.nextPage(),
          style: ElevatedButton.styleFrom(
            shape: controller.currentIndex.value == 2 
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSize.buttonRadius))
                : const CircleBorder(),
            backgroundColor: dark ? TColor.primary : Colors.black,
            padding: controller.currentIndex.value == 2
                ? const EdgeInsets.symmetric(horizontal: TSize.lg, vertical: TSize.sm)
                : const EdgeInsets.all(TSize.md),
          ),
          child: controller.currentIndex.value == 2
              ? const Text("Continue", style: TextStyle(color: Colors.white))
              : const Icon(Iconsax.arrow_right_3, color: Colors.white),
        ),
      ),
    );
  }
}
