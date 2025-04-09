import 'package:get/get.dart';

class OnBoardingController extends GetxController{
  static OnBoardingController get instance => Get.find();

  ///variables
  ///
  /// updage current index when page scorll
  void updatePageIndicator(index){}

  //Jump to the specifice dot selected page.
  void dotNavigationClick(index){}

  ///update current index & jump to next page
  void nextPage(){}

  ///update current index & jump to the last page
  void skipPage() {}
}