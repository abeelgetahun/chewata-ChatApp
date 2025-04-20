import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:chewata/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log the error or send it to a monitoring service
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  runZonedGuarded(() {
    runApp(const App());
  }, (error, stackTrace) {
    // Handle uncaught asynchronous errors
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  });
}
