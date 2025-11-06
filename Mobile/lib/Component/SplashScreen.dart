import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Component/AppTheme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay a bit for token load
    Future.delayed(const Duration(seconds: 1), () {
      final tokenCtrl = Get.find<TokenController>();

      // Check token.value from GetStorage
      final hasToken = tokenCtrl.token.value.isNotEmpty;

      if (hasToken) {
        Get.offAllNamed('/home'); // Logged in
      } else {
        Get.offAllNamed('/login'); // Not logged in
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary)),
        ),
      ),
    );
  }
}
