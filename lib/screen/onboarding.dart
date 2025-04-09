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
          PageView(
            children: [
              OnBoardingPage(image: TImages.onBoardingImage1,
                title: TText.onBoardingTitle1,
                subTitle: TText.onBoardingSubTitle1
              ), 
              OnBoardingPage(image: TImages.onBoardingImage2,
                title: TText.onBoardingTitle2,
                subTitle: TText.onBoardingSubTitle2
              ),
              OnBoardingPage(image: TImages.onBoardingImage3,
                title: TText.onBoardingTitle3,
                subTitle: TText.onBoardingSubTitle3
              ), 
            ],
          )
        ],
        )

    );
  }
}

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key, required this.image, required this.title, required this.subTitle,
  });

  final String image, title , subTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tsize.defaultSpace),
      child: Column (
        children: [
          Lottie.asset( image,
          width: THelperFunction.screenWidth()*0.8,
          height: THelperFunction.screenHeight() * 0.6,
                
          ),
          Text(title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Tsize.spaceBtwItems,),
          Text(subTitle,
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