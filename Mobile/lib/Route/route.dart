import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart'; // 你已有
import 'package:mobile/Auth/register.dart'; // 你已有
import 'package:mobile/Component/BottomNav.dart'; // 你的导航壳(Home 在第1个Tab)
import 'package:mobile/Admin/adminDashboard.dart';
import 'package:mobile/Admin/manageUser.dart';
import 'package:mobile/Admin/manageMerchant.dart';
import 'package:mobile/Admin/manageAPI.dart';

class AppPages {
  static const INITIAL = '/login';

  static final routes = <GetPage>[
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/signup', page: () => const Register()),
    GetPage(name: '/home', page: () => const BottomNavApp()), // 登录后进入这里
    GetPage(
        name: '/debit-credit-details',
        page: () =>
            const Placeholder()), // TODO: Place the true debit and credit details page here.
    GetPage(
        name: '/spendingDetails',
        page: () =>
            const Placeholder()), // TODO: Place the true spending details page here.
    GetPage(name: '/adminHome', page: () => const AdminDashboardWidget()),
    GetPage(name: '/userManagement', page: () => const ManageUserWidget()),
    GetPage(
        name: '/merchantManagement', page: () => const ManageMercahntWidget()),
    GetPage(name: '/apiManagement', page: () => const ManageAPIWidget()),
  ];
}
