import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrAction { pay, transfer }

class PaymentQrPayload {
  final QrAction action;
  final String walletId;
  final String userId;
  final double amount;
  final String currency;
  final String? note;

  PaymentQrPayload({
    required this.action,
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.currency,
    this.note,
  });

  // ---- Encode to URI form ----
  String toUriString() {
    final act = action == QrAction.pay ? 'pay' : 'transfer';
    final q = Uri(
      scheme: 'wallet',
      host: act,
      queryParameters: {
        'walletId': walletId,
        'userId': userId,
        'amount': amount.toString(),
        'currency': currency,
        if (note != null && note!.isNotEmpty) 'note': note!,
      },
    );
    return q.toString(); // e.g. wallet://pay?walletId=...&...
  }

  // ---- Encode to JSON form ----
  String toJsonString() => jsonEncode({
        'action': action == QrAction.pay ? 'pay' : 'transfer',
        'walletId': walletId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        if (note != null) 'note': note,
      });

  // ---- Try parse (URI first, then JSON) ----
  static PaymentQrPayload? parse(String raw) {
    final v = raw.trim();

    // 1) URI form: wallet://pay or wallet://transfer
    if (v.startsWith('wallet://')) {
      final uri = Uri.tryParse(v);
      if (uri != null && (uri.host == 'pay' || uri.host == 'transfer')) {
        final act = uri.host == 'pay' ? QrAction.pay : QrAction.transfer;
        final walletId = uri.queryParameters['walletId'] ?? '';
        final userId   = uri.queryParameters['userId'] ?? '';
        final amountS  = uri.queryParameters['amount'] ?? '0';
        final currency = uri.queryParameters['currency'] ?? 'MYR';
        final note     = uri.queryParameters['note'];

        final amount = double.tryParse(amountS) ?? 0.0;
        if (walletId.isEmpty || userId.isEmpty) return null;

        return PaymentQrPayload(
          action: act,
          walletId: walletId,
          userId: userId,
          amount: amount,
          currency: currency,
          note: note,
        );
      }
    }

    // 2) JSON form
    try {
      final m = jsonDecode(v);
      if (m is Map<String, dynamic>) {
        final actStr = (m['action'] ?? '').toString().toLowerCase();
        final act = actStr == 'transfer' ? QrAction.transfer : QrAction.pay;
        final walletId = (m['walletId'] ?? '').toString();
        final userId   = (m['userId'] ?? '').toString();
        final amount   = (m['amount'] is num)
            ? (m['amount'] as num).toDouble()
            : double.tryParse('${m['amount']}') ?? 0.0;
        final currency = (m['currency'] ?? 'MYR').toString();
        final note     = (m['note']?.toString());

        if (walletId.isEmpty || userId.isEmpty) return null;

        return PaymentQrPayload(
          action: act,
          walletId: walletId,
          userId: userId,
          amount: amount,
          currency: currency,
          note: note,
        );
      }
    } catch (_) {
      // ignore
    }

    return null;
  }
}

/// ---- Pure QR image (no styling) ----
Widget buildQrImage(
  String data, {
  double size = 240,
  Color backgroundColor = Colors.white,
  QrEyeStyle eyeStyle = const QrEyeStyle(eyeShape: QrEyeShape.square),
  QrDataModuleStyle dataModuleStyle =
      const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
}) {
  return QrImageView(
    data: data.isEmpty ? ' ' : data,
    version: QrVersions.auto,
    size: size,
    gapless: true,
    backgroundColor: backgroundColor,
    eyeStyle: eyeStyle,
    dataModuleStyle: dataModuleStyle,
  );
}

/// ---- Scanner surface (you style overlay outside) ----
Widget buildQrScanner({
  required void Function(String value) onDetect,
  MobileScannerController? controller,
  bool detectOnce = false,
  Widget? overlay,
}) {
  final ctrl = controller ??
      MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.normal,
      );
  String? last;
  return Stack(
    children: [
      MobileScanner(
        controller: ctrl,
        onDetect: (capture) {
          final codes = capture.barcodes;
          if (codes.isEmpty) return;
          final value = codes.first.rawValue;
          if (value == null || value.isEmpty) return;
          if (last == value) return;
          last = value;
          HapticFeedback.mediumImpact();
          onDetect(value);
          if (detectOnce) {
            ctrl.stop();
          } else {
            Future.delayed(const Duration(milliseconds: 400), () => last = null);
          }
        },
      ),
      if (overlay != null) IgnorePointer(ignoring: true, child: overlay),
    ],
  );
}

Widget simpleScannerOverlay({double size = 260, Color color = Colors.blue}) {
  return Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(width:2, color: color),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
