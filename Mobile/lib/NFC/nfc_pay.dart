import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:mobile/QR/QRUtlis.dart';
import 'package:ndef/ndef.dart' as ndef;

import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Transfer/transfer.dart';

class NfcPayPage extends StatefulWidget {
  const NfcPayPage({super.key});

  @override
  State<NfcPayPage> createState() => _NfcPayPageState();
}

class _NfcPayPageState extends State<NfcPayPage> {
  String status = "Hold your phone near the merchant's NFC tag.";
  bool _handlingTag = false;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    if (_sessionActive) {
      FlutterNfcKit.finish();
    }
    super.dispose();
  }

  // ✅ Open NFC settings (Samsung/Android reliable)
  Future<void> _openNfcSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.NFC_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
    } catch (_) {
      // fallback: general settings
      const fallback = AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await fallback.launch();
    }
  }

  Future<void> _startSession() async {
    // Stop any previous session
    if (_sessionActive) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
      _sessionActive = false;
    }

    if (!mounted) return;
    setState(() => status = "Hold your phone near the merchant's NFC tag...");
    _sessionActive = true;

    if (_handlingTag) return;
    _handlingTag = true;

    try {
      // ✅ Don't rely on availability (can be wrong).
      // ✅ Poll is the real check. If NFC is OFF see catch.
      await FlutterNfcKit.poll(timeout: const Duration(seconds: 20));

      final records = await FlutterNfcKit.readNDEFRecords();
      if (records.isEmpty) {
        throw Exception("Empty NFC tag. Write NDEF Text: MERCHANT:<id>");
      }

      final merchantId = _extractMerchantId(records.first);
      if (merchantId.isEmpty) {
        throw Exception("Merchant ID missing in tag.");
      }

      await FlutterNfcKit.finish();
      _sessionActive = false;

      // Look up contact (optional)
      final tx = Get.find<TransactionController>();
      WalletContact? contact;
      try {
        contact = await tx.lookupContact(merchantId, walletId: merchantId);
      } catch (_) {}

      final recipient = contact != null
          ? LockedRecipient.fromWalletContact(contact)
          : LockedRecipient(
              walletId: merchantId,
              displayName: 'Merchant $merchantId',
              walletType: 'merchant',
            );

      if (!mounted) return;

      // ✅ jump into your existing transfer/pay flow
      Get.to(() => TransferScreen(mode: 'transfer', lockedRecipient: recipient));
    } catch (e) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
      _sessionActive = false;

      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      final looksLikeNfcOff = msg.contains("nfc") &&
          (msg.contains("disabled") ||
              msg.contains("not available") ||
              msg.contains("off"));

      setState(() {
        status = looksLikeNfcOff
            ? "NFC is OFF.\nEnable NFC in Settings, then tap 'Restart scan'."
            : "NFC error: $e";
      });
    } finally {
      _handlingTag = false;
    }
  }

  String _extractMerchantId(ndef.NDEFRecord record) {
    final text = _decodePayload(record.payload);

    // ✅ Clean BOM / whitespace
    final cleaned = text.trim().replaceAll('\uFEFF', '');

    const prefix = "MERCHANT:";
    if (!cleaned.toUpperCase().startsWith(prefix)) {
      throw Exception("Invalid tag content: $cleaned");
    }
    return cleaned.substring(prefix.length).trim();
  }

  String _decodePayload(dynamic payload) {
    if (payload is String) return payload.trim();
    if (payload is List<int>) return _decodeTextBytes(payload);
    return payload.toString().trim();
  }

  String _decodeTextBytes(List<int> bytes) {
    if (bytes.isEmpty) throw Exception("No payload in tag.");

    // NDEF Text payload:
    // [statusByte][languageCode...][text...]
    // lower 6 bits of statusByte = language code length
    final langLength = bytes.first & 0x3F;

    if (bytes.length > langLength + 1) {
      return utf8.decode(bytes.sublist(1 + langLength)).trim();
    }
    return utf8.decode(bytes).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlobalScaffold(
      title: 'NFC Pay',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.nfc, size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              status,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),

            // ✅ Open NFC Settings
            FilledButton.tonalIcon(
              onPressed: _openNfcSettings,
              icon: const Icon(Icons.settings),
              label: const Text("Open NFC Settings"),
            ),
            const SizedBox(height: 10),

            // ✅ Restart Scan
            FilledButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Restart scan'),
            ),
          ],
        ),
      ),
    );
  }
}
