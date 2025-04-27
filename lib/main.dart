import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:chewata/app.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:get/get.dart';

void main() async {
  // Ensure Flutter bindings are initialized in the same zone
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize theme controller
  await Get.putAsync(() async => await ThemeController().init());

  // Set up global error handling
  runZonedGuarded(() {
    runApp(const App());
  }, (error, stackTrace) {
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  });
}