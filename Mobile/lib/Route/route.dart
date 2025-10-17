import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart';         // 你已有
import 'package:mobile/Auth/register.dart';      // 你已有
import 'package:mobile/Component/BottomNav.dart';// 你的导航壳(Home 在第1个Tab)

class AppPages {
  static const INITIAL = '/splash';

  static final routes = <GetPage>[
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/signup', page: () => const Register()),
    GetPage(name: '/home', page: () => BottomNavApp()), // 登录后进入这里
  ];
}
