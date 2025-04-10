
import 'package:chewata/controller/onboarding_controller.dart';
import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/utils/constants/color.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
        onPressed: () {
          OnBoardingController.instance.nextPage();
        }, 
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: dark?  TColor.primary : Colors.black
        ),
        child: const Icon(Iconsax.arrow_right_3,
        color: Colors.white,),
      ));
  }
}
