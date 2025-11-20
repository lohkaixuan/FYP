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
  final String? walletId;
  final String? walletType;
  final String? phone;
  final String? email;
  final String? username;
  final double? amount;
  final String? currency;
  final String? note;

  TransferQrPayload({
    this.kind = 'wallet',
    this.action = 'transfer',
    this.walletId,
    this.walletType,
    this.phone,
    this.email,
    this.username,
    this.amount,
    this.currency,
    this.note,
  });

  /// ✅ 只把「有值」的字段放进 JSON，避免 "xxx": null
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'kind': kind,
      'action': action,
    };

    if (walletId != null && walletId!.isNotEmpty) {
      map['wallet_id'] = walletId;
    }
    if (walletType != null && walletType!.isNotEmpty) {
      map['wallet_type'] = walletType;
    }
    if (phone != null && phone!.isNotEmpty) {
      map['phone'] = phone;
    }
    if (email != null && email!.isNotEmpty) {
      map['email'] = email;
    }
    if (username != null && username!.isNotEmpty) {
      map['username'] = username;
    }
    if (amount != null) {
      map['amount'] = amount;
    }
    if (currency != null && currency!.isNotEmpty) {
      map['currency'] = currency;
    }
    if (note != null && note!.isNotEmpty) {
      map['note'] = note;
    }

    return map;
  }

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
      walletId: json['wallet_id']?.toString(),
      walletType: json['wallet_type']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      amount: parsedAmount,
      currency: json['currency']?.toString(),
      note: json['note']?.toString(),
    );
  }

  static TransferQrPayload? tryParse(String raw) {
    final v = raw.trim();
    try {
      final m = jsonDecode(v);
      if (m is Map<String, dynamic>) {
        return TransferQrPayload.fromJson(m);
      }
    } catch (_) {}
    return null;
  }
}

/// ===============================
/// 提供给别的页面用的“联系人模型”
/// UI 只展示 name + phone/email，不展示 UUID
/// ===============================
class WalletContact {
  final String displayName;
  final String? phone;
  final String? email;
  final String? username;
  final WalletSummary userWallet;
  final MerchantWalletInfo? merchantWallet;
  final String? merchantName;
  String _activeWalletType;

  WalletContact({
    required this.displayName,
    this.phone,
    this.email,
    this.username,
    required this.userWallet,
    this.merchantWallet,
    this.merchantName,
    String? preferredWalletType,
  }) : _activeWalletType =
            (preferredWalletType == 'merchant' && merchantWallet != null)
                ? 'merchant'
                : 'user';

  factory WalletContact.fromLookupResult(WalletLookupResult dto) {
    return WalletContact(
      displayName: dto.userName,
      phone: dto.phoneNumber,
      email: dto.email,
      username: dto.username,
      userWallet: dto.userWallet,
      merchantWallet: dto.merchantWallet,
      merchantName: dto.merchantWallet?.merchantName,
      preferredWalletType: dto.preferredWalletType,
    );
  }

  bool get hasMerchantWallet => merchantWallet != null;

  String get activeWalletType => _activeWalletType;

  String get walletId => (activeWalletType == 'merchant' && merchantWallet != null)
      ? merchantWallet!.wallet.walletId
      : userWallet.walletId;

  WalletSummary get currentWalletSummary =>
      (activeWalletType == 'merchant' && merchantWallet != null)
          ? merchantWallet!.wallet
          : userWallet;

  String get currentDisplayName =>
      (activeWalletType == 'merchant' && (merchantName?.isNotEmpty ?? false))
          ? merchantName!
          : displayName;

  void setActiveWalletType(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'merchant' && merchantWallet == null) return;
    _activeWalletType = normalized == 'merchant' ? 'merchant' : 'user';
  }
}

/// ===============================
/// 生成 QR 字符串（给 QrImageView 用）
/// ===============================

/// 自己收款用的 QR：只放 phone/email/username
String buildMyWalletQr({
  String? phone,
  String? email,
  String? username,
  String? walletId,
  String? walletType,
}) {
  final payload = TransferQrPayload(
    kind: 'wallet',
    action: 'transfer',
    walletId: walletId,
    walletType: walletType,
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
  String? walletId,
  required double amount,
  String currency = 'MYR',
  String? note,
}) {
  final payload = TransferQrPayload(
    kind: 'wallet',
    action: 'transfer',
    walletId: walletId,
    walletType: 'merchant',
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

    if (payload.kind != 'wallet' || payload.action != 'transfer') {
      return null;
    }

    WalletContact? contact;
    if (payload.walletId != null && payload.walletId!.isNotEmpty) {
      contact = await _lookupContact(walletId: payload.walletId);
      if (contact != null && payload.walletType != null) {
        contact.setActiveWalletType(payload.walletType!);
      }
    } else {
      final searchValue = payload.phone ?? payload.email ?? payload.username;
      if (searchValue == null || searchValue.isEmpty) return null;
      contact = await _lookupContact(search: searchValue);
    }
    return contact;
  }

  static Future<WalletContact?> _lookupContact({
    String? search,
    String? walletId,
  }) async {
    final dto = await api.lookupWalletContact(
      search: search,
      walletId: walletId,
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
