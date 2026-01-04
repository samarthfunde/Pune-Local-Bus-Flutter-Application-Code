import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BusSearchController extends GetxController {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final RxBool isWomenOnly = false.obs;
  final RxList<Map<String, dynamic>> placesData = <Map<String, dynamic>>[].obs;

  void toggleWomenOnly(bool value) {
    isWomenOnly.value = value;
  }

  void searchBuses() {
    // Implement your search logic here
    // For example, filter buses based on fromController and toController values
    print('Searching buses from ${fromController.text} to ${toController.text}');
  }
}