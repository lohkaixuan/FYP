import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/Api/token.dart';

import 'package:mobile/Component/BottomNavController.dart';
import 'package:mobile/Role/RoleController.dart';
import 'package:mobile/Route/route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // 持久化存储初始化（保存登录 token）
  Get.put(RoleController(), permanent: true); // 全局单例
  Get.find<RoleController>().setRole(UserRole.merchant); // or UserRole.user

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
      debugShowCheckedModeBanner: true,
      initialRoute: AppPages.INITIAL, // '/splash'
      getPages: AppPages.routes,      // 从 route.dart 读取
      theme: ThemeData(useMaterial3: true),
    );
  }
}
