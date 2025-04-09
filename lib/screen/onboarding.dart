import 'package:chewata/model/helper_functions.dart';
import 'package:chewata/utils/constants/image_strings.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/constants/text_strings.dart'; // Adjust the path as needed
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
 // Adjust the path as needed

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack (
        children: [
          //horizontal scrollable
          Column (
            children: [
              Lottie.asset( TImages.onBoardingImage1,
              width: THelperFunction.screenWidth()*0.8,
              height: THelperFunction.screenHeight() * 0.6,
      
              ),
              Text(TText.onBoardingTitle1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsize.spaceBtwItems,),
              Text(TText.onBoardingSubTitle1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
        ],
        )

    );
  }
}