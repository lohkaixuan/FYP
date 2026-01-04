// ==================================================
// Program Name   : BottomNavController.dart
// Purpose        : Controller maintaining bottom navigation state
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  void reset() {
    selectedIndex.value = 0;
  }
  
  void index(int index) {
    selectedIndex.value = index;
  } 
}