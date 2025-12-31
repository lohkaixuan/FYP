import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Controller/BankController.dart';

import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Controller/BudgetController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/Route/route.dart';
import 'package:mobile/Controller/TransactionController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); 

  
  Get.put(BottomNavController(), permanent: true);
  Get.put<TokenController>(TokenController(), permanent: true);
  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<AuthController>(
      AuthController(Get.find<ApiService>(), Get.find<TokenController>()),
      permanent: true);
  Get.put<WalletController>(WalletController(), permanent: true);
  Get.put<TransactionController>(TransactionController(), permanent: true);
  Get.put<BudgetController>(BudgetController(), permanent: true);
  Get.put<BankController>(BankController(), permanent: true);
  Get.put<RoleController>(RoleController(), permanent: true);
  Get.put(AdminController(), permanent: true);
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
      getPages: AppPages.routes, 

      // ✅ Correct: ThemeData here
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // ✅ And control which one to use
      themeMode: ThemeMode.system,
    );
  }
}
