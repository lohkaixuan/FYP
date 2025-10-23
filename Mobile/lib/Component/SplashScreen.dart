import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/tokenController.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenCtrl = Get.find<TokenController>();

    Future.delayed(const Duration(seconds: 1), () {
      if (tokenCtrl.isLoggedIn) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
