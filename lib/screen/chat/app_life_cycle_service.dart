
import 'package:chewata/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

// In app_life_cycle_service.dart
class AppLifecycleService extends GetxService {
  final AuthService auth = Get.find();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Create a more reliable lifecycle observer
    final lifecycleObserver = LifecycleEventHandler(
      resumeCallBack: () {
        print('App resumed - setting user online');
        auth.updatePresence(true);
        isConnected.value = true;
      },
      suspendCallBack: () {
        print('App suspended - setting user offline');
        auth.updatePresence(false);
        isConnected.value = false;
      },
    );
    
    WidgetsBinding.instance.addObserver(lifecycleObserver);
    
    // Initial status setup based on current app state
    auth.updatePresence(true);
  }
  
  @override
  void onClose() {
    // Ensure user is marked offline when service is closed
    auth.updatePresence(false);
    super.onClose();
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Function resumeCallBack;
  final Function suspendCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
    required this.suspendCallBack,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        suspendCallBack();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state same as other inactive states
        suspendCallBack();
        break;
    }
  }
}