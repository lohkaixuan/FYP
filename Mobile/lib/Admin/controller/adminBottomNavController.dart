import 'package:get/get.dart';

class AdminBottomNavController extends GetxController {
  final selectedIndex = 0.obs;

  // Change tab
  void changeIndex(int i) => selectedIndex.value = i;

  // Map route suffix -> tab index
  final Map<String, int> _routeIndex = {
    '': 0, // /admin -> dashboard
    '/manage-api': 1,
    '/manage-users': 2,
    '/register-third-party': 3,
    '/manage-third-party': 4,
  };

  @override
  void onInit() {
    super.onInit();
    // If opened via deep link like '/admin/manage-users', set correct tab
    final route = Get.currentRoute; // e.g. '/admin/manage-users'
    if (route.startsWith('/admin')) {
      final suffix = route.replaceFirst('/admin', '');
      selectedIndex.value = _routeIndex[suffix] ?? 0;
    }
  }
}
