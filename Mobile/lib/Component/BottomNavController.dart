// bottom_nav_controller.dart
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final selectedIndex = 0.obs;
  void changeIndex(int i) => selectedIndex.value = i;
}
