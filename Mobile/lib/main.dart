import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Auth/authController.dart';
import 'package:mobile/Component/AppTheme.dart';

import 'package:mobile/Component/BottomNavController.dart';
import 'package:mobile/Role/RoleController.dart';
import 'package:mobile/Route/route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // 持久化存储初始化（保存登录 token）
  Get.put(RoleController(), permanent: true); // 全局单例

  Get.put(AuthController());
  final rc = Get.find<RoleController>();
  // 情况 A：商家用户（可切换两个钱包，显示 subtitle + 按钮）
  rc.setHasMerchant(true);
  rc.setRole(UserRole.merchant); // 或 UserRole.user

  // 全局依赖
  Get.put(BottomNavController(), permanent: true);
  Get.put(TokenController(), permanent: true); // 👈 register it

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "UniPay",
      debugShowCheckedModeBanner: true,
      initialRoute: AppPages.INITIAL, // '/splash'
      getPages: AppPages.routes, // 从 route.dart 读取

      // ✅ Correct: ThemeData here
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // ✅ And control which one to use
      themeMode: ThemeMode.system,
    );
  }
}
