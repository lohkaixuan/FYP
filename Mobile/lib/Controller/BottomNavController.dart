// bottom_nav_controller.dart
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  // 默认就是首页
  final selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  void reset() {
    selectedIndex.value = 0;
  }
}