// lib/QR/QRUtlis.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';


/// ===============================
/// 统一的 Transfer QR Payload
/// - 不再放 UUID
/// - 用 phone / email / username 做公开 ID
/// - 可选 amount / currency / note
/// ===============================
class TransferQrPayload {
  final String kind;     // e.g. 'wallet'
  final String action;   // e.g. 'transfer'
  final String? phone;
  final String? email;
  final String? username;
  final double? amount;
  final String? currency;
  final String? note;

  TransferQrPayload({
    this.kind = 'wallet',
    this.action = 'transfer',
    this.phone,
    this.email,
    this.username,
    this.amount,
    this.currency,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'action': action,
        'phone': phone,
        'email': email,
        'username': username,
        'amount': amount,
        'currency': currency,
        'note': note,
      };

  String toJsonString() => jsonEncode(toJson());

  factory TransferQrPayload.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    double? parsedAmount;
    if (amountRaw != null) {
      parsedAmount = amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw.toString());
    }

    return TransferQrPayload(
      kind: json['kind']?.toString() ?? 'wallet',
      action: json['action']?.toString() ?? 'transfer',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      amount: parsedAmount,
      currency: json['currency']?.toString(),
      note: json['note']?.toString(),
    );
  }

  /// 尝试从原始字符串解析（目前只支持 JSON）
  static TransferQrPayload? tryParse(String raw) {
    final v = raw.trim();
    try {
      final m = jsonDecode(v);
      if (m is Map<String, dynamic>) {
        return TransferQrPayload.fromJson(m);
      }
    } catch (_) {
      // 以后如果要兼容 wallet://transfer?... 可以在这里加 URI 解析
    }
    return null;
  }
}

/// ===============================
/// 提供给别的页面用的“联系人模型”
/// UI 只展示 name + phone/email，不展示 UUID
/// ===============================
class WalletContact {
  final String walletId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? username;
  final String? walletNumber;
  final double? walletBalance;
  final String? merchantWalletId;
  final String? merchantWalletNumber;
  final double? merchantWalletBalance;
  final String? merchantName;

  WalletContact({
    required this.walletId,
    required this.displayName,
    this.phone,
    this.email,
    this.username,
    this.walletNumber,
    this.walletBalance,
    this.merchantWalletId,
    this.merchantWalletNumber,
    this.merchantWalletBalance,
    this.merchantName,
  });

  factory WalletContact.fromLookupResult(WalletLookupResult dto) {
    final merchant = dto.merchantWallet;
    return WalletContact(
      walletId: dto.userWallet.walletId,
      displayName: dto.userName,
      phone: dto.phoneNumber,
      email: dto.email,
      username: dto.username,
      walletNumber: dto.userWallet.walletNumber,
      walletBalance: dto.userWallet.balance,
      merchantWalletId: merchant?.wallet.walletId,
      merchantWalletNumber: merchant?.wallet.walletNumber,
      merchantWalletBalance: merchant?.wallet.balance,
      merchantName: merchant?.merchantName,
    );
  }

  bool get hasMerchantWallet => merchantWalletId != null;
}

/// ===============================
/// 生成 QR 字符串（给 QrImageView 用）
/// ===============================

/// 自己收款用的 QR：只放 phone/email/username
String buildMyWalletQr({
  String? phone,
  String? email,
  String? username,
}) {
  final payload = TransferQrPayload(
    kind: 'wallet',
    action: 'transfer',
    phone: phone,
    email: email,
    username: username,
  );
  return payload.toJsonString();
}

/// 商家 / 固定金额收款 QR（可选）
String buildMerchantQr({
  String? phone,
  String? email,
  String? username,
  required double amount,
  String currency = 'MYR',
  String? note,
}) {
  final payload = TransferQrPayload(
    kind: 'wallet',
    action: 'transfer',
    phone: phone,
    email: email,
    username: username,
    amount: amount,
    currency: currency,
    note: note,
  );
  return payload.toJsonString();
}

/// ===============================
/// QR 显示 + 扫描 widget（你原本的也保留）
/// ===============================

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
            Future.delayed(
              const Duration(milliseconds: 400),
              () => last = null,
            );
          }
        },
      ),
      if (overlay != null) IgnorePointer(ignoring: true, child: overlay),
    ],
  );
}

Widget simpleScannerOverlay({double size = 200, Color color = Colors.blue}) {
  return Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: color),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

/// ===============================
/// QRUtils：扫码 + lookup + 返回 WalletContact
/// ===============================
class QRUtils {
  static final api = Get.find<ApiService>();

  /// 打开扫码页面 → 解析 TransferQrPayload
  /// → 用 phone/email/username 去查真正的钱包 → 返回 WalletContact
  static Future<WalletContact?> scanWalletTransfer() async {
    final raw = await _scanRawQrString();
    if (raw == null) return null;

    final payload = TransferQrPayload.tryParse(raw);
    if (payload == null) return null;

    // 只处理钱包转账类型
    if (payload.kind != 'wallet' || payload.action != 'transfer') {
      return null;
    }

    final contact = await _lookupContact(
      phone: payload.phone,
      email: payload.email,
      username: payload.username,
    );
    // 如果以后想让 amount 自动带进去，可以从 payload.amount 传给 UI
    return contact;
  }

  static Future<WalletContact?> _lookupContact({
    String? phone,
    String? email,
    String? username,
  }) async {
    // ???? ApiService ?????,?? WalletContact?

    final dto = await api.lookupWalletContact(
      phone: phone,
      email: email,
      username: username,
    );
    if (dto == null) return null;
    return WalletContact.fromLookupResult(dto);
  }

  static Future<String?> _scanRawQrString() async {
    return await Get.to<String?>(
      () => const WalletQrScanPage(),
    );
  }
}

/// 简单扫码页：扫到就返回 raw string 给上层
class WalletQrScanPage extends StatelessWidget {
  const WalletQrScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan wallet QR")),
      body: buildQrScanner(
        detectOnce: true,
        overlay: simpleScannerOverlay(),
        onDetect: (value) {
          Get.back(result: value);
        },
      ),
    );
  }
}
