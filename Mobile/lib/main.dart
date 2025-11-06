import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Auth/authcontroller.dart';
import 'package:mobile/Component/AppTheme.dart';

import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Route/route.dart';
import 'package:mobile/Controller/TransactionController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // 持久化存储初始化（保存登录 token）

  // 全局依赖
  Get.put(BottomNavController(), permanent: true);
  Get.put<TokenController>(TokenController(), permanent: true);
  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<AuthController>(AuthController(Get.find<ApiService>(), Get.find<TokenController>()), permanent: true);
  Get.put<TransactionController>(TransactionController(), permanent: true);
  Get.put<RoleController>(RoleController(), permanent: true);
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
