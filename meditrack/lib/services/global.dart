import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feature_tour/flutter_feature_tour.dart';
import 'package:meditrack/firebase_options.dart';
import 'package:meditrack/services/storage_services.dart';

class Global {
  static late StorageServices storageServices;

  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    storageServices = await StorageServices().init();
    await OnboardingService().initialize();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // await dotenv.load(fileName: ".env");
  }
}
