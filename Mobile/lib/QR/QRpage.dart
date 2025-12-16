import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/NFC/nfc_pay.dart';
import 'package:mobile/QR/QRComponent.dart';

class QR extends StatelessWidget {
  const QR({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: 'Scan & Pay',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(child: QRComponent()),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Get.to(() => const NfcPayPage()),
              icon: const Icon(Icons.nfc),
              label: const Text('Tap to pay with NFC'),
            ),
          ],
        ),
      ),
    );
  }
}
