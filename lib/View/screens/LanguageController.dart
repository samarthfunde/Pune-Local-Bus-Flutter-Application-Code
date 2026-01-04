import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final List<String> languages = ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu'];
  String selectedLanguage = '';

  void selectLanguage(String language) {
    selectedLanguage = language;
    update(); // Update UI using GetX
  }

  Future<void> saveLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', selectedLanguage);
    Get.updateLocale(Locale(getLocaleCode(selectedLanguage))); // Set GetX locale
  }

  Future<void> loadLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('language') ?? 'English';
    update();
  }

  String getLocaleCode(String language) {
    switch (language) {
      case 'Hindi':
        return 'hi';
      case 'Marathi':
        return 'mr';
      case 'Tamil':
        return 'ta';
      case 'Telugu':
        return 'te';
      default:
        return 'en';
    }
  }
}
