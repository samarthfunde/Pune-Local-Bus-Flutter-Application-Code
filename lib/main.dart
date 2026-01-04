import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:pmpml_app/View/screens/translations.dart'; // ✅ FIX: full correct path
import 'package:pmpml_app/View/screens/splash_screen.dart'; 
//updated code by samarth 18 may 2025

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
 @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PMPML Bus App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Add translations
      translations: AppTranslations(),
      locale: const Locale('en'), // Default locale
      fallbackLocale: const Locale('en'),
      home: SplashScreen(),
    );
  }
}