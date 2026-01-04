// ==================================================
// Program Name   : QRpage.dart
// Purpose        : QR payment page
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
            Expanded(child: QRComponent()),
            FilledButton.icon(
              onPressed: () => Get.to(() => const NfcPayPage()),
              icon: const Icon(Icons.nfc),
              label: const Text('Tap to pay with NFC'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}



