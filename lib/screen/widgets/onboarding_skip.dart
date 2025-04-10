
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/device/device_utility.dart';
import 'package:flutter/material.dart';

class onBoardingSkip extends StatelessWidget {
  const onBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(), // Fixed positioning from the top
      right: Tsize.defaultSpace, 
      child: Container(
       
        child: TextButton(
          onPressed: () {
            // Your navigation logic here
          },
        
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
    );
  }
}
