import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/QRComponent.dart';

class QR extends StatelessWidget {
  const QR({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: GlobalAppBar(title: 'QR (Wallet)'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: QRComponent(), // ← 直接用合并后的组件
      ),
    );
  }
}
