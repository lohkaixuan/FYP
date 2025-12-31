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
<<<<<<< HEAD
        padding: EdgeInsets.all(16),
        child: QRComponent(), 
=======
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: QRComponent()),
            FilledButton.icon(
              onPressed: () => Get.to(() => const NfcPayPage()),
              icon: const Icon(Icons.nfc),
              label: const Text('Tap to pay with NFC'),
            ),
            const SizedBox(height: 80),
          ],
        ),
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      ),
    );
  }
}
