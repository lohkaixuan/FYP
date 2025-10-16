import 'package:flutter/material.dart';
import 'package:mobile/Users/home.dart';
import 'package:mobile/Users/qr_payment.dart';

class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/scanQr'){
          return MaterialPageRoute(builder: (_) => const QrPaymentScreen());
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}