import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:chewata/screen/auth/login_screen.dart';

class OnBoardingController extends GetxController{
  static OnBoardingController get instance => Get.find();

  ///variables
  final pageController = PageController();
  Rx<int> currentIndex = 0.obs;
  ///
  /// updage current index when page scorll
  void updatePageIndicator(index){
    currentIndex.value = index; 
  }

  //Jump to the specifice dot selected page.
  void dotNavigationClick(index){
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  ///update current index & jump to next page
  void nextPage(){
    if (currentIndex.value == 2) {
      // Navigate to LoginScreen and remove OnBoardingScreen from the stack
      Get.off(() => const LoginScreen());
    } else {
      currentIndex.value += 1; // Increment the current index
      pageController.animateToPage(
        currentIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  ///update current index & jump to the last page
  void skipPage() {
    currentIndex.value = 2;
    pageController.jumpToPage(2);
  }
}