import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/database_service.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/storage_service.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/cloud_functions_service.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/repositories/auth.repositories.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/screens/login/login.dart';
import 'package:ai_voice_to_hand_signs_project/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    // NOTE: Remove demoProjectId for production Firebase
  );

  // Initialize App Check for security (Android-only)
  // This protects your Firebase backend from unauthorized access
  await FirebaseAppCheck.instance.activate(
    // Use Play Integrity for production (requires app to be on Play Store)
    // Use Debug provider for development/testing
    // TEMPORARY: Force debug provider for local release testing
    androidProvider: AndroidProvider.debug,
  );

  // NOTE: Comment out emulator when testing on physical device
  // Physical devices cannot reach "localhost" - use your computer's IP instead
  // or use production Firebase
  // await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);

  // Initialize Google Sign-In with serverClientId (Web Client ID from google-services.json)
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '37627043520-iarcpu2agpqqavqemu0suc0n87c64t0v.apps.googleusercontent.com',
  );

  // Initialize Database Services
  Get.put(DatabaseService());

  // Initialize Cloud Storage Services
  Get.put(StorageService());

  // Initialize Cloud Functions Services
  Get.put(CloudFunctionsService());

  // Initialize Authentication Controller
  Get.put(AuthRepositories());

  // Request Permissions
  await [Permission.camera, Permission.microphone].request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hackathon Project',
      theme: ThemeData(fontFamily: 'Poppins', brightness: Brightness.dark),
      home: const LoginScreen(),
    );
  }
}
