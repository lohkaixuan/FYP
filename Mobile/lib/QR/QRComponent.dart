import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalTabBar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mobile/Transfer/transfer.dart';      // TransferScreen + LockedRecipient
import 'package:mobile/Auth/auth.dart';               // AuthController
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionController.dart';

import 'QRUtlis.dart'; // TransferQrPayload / buildMyWalletQr / buildQrScanner / simpleScannerOverlay / WalletContact

/// 标签选项
enum QrTab { show, scan }

/// GetX 控制器
class QrTabController extends GetxController {
  final Rx<QrTab> tab = QrTab.show.obs;
  void setTab(QrTab? t) {
    if (t != null) tab.value = t;
  }
}

/// 顶部滑块（用 Obx 绑定）
class QrSlideSwitch extends GetView<QrTabController> {
  const QrSlideSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isShow = controller.tab.value == QrTab.show;
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            globalTabBar(
              context,
              label: 'Show QR',
              selected: isShow,
              onTap: () => controller.setTab(QrTab.show),
            ),
            globalTabBar(
              context,
              label: 'Scanner',
              selected: !isShow,
              onTap: () => controller.setTab(QrTab.scan),
            ),
          ],
        ),
      );
    });
  }
}

/// 主组件
class QRComponent extends StatefulWidget {
  const QRComponent({super.key});

  @override
  State<QRComponent> createState() => _QRComponentState();
}

class _QRComponentState extends State<QRComponent> {
  final _scannerCtrl = MobileScannerController();
  late final QrTabController tabC;

  late final AuthController authController;
  late final RoleController roleController;
  late final TransactionController transactionController;

  bool _isHandlingScan = false; // 防止连环触发

  /// ✅ 自己的钱包联系信息（来自 API）
  WalletContact? _selfContact;
  bool _loadingSelf = true;

  /// 当前登录用户的「收款 QR 内容」
  /// 优先用 API 拿到的 phone/email/username，避免 null
  String get myWalletQrPayload {
    if (_selfContact != null) {
      return buildMyWalletQr(
        phone: _selfContact!.phone,
        email: _selfContact!.email,
        username:
            _selfContact!.username ?? _selfContact!.displayName, // 保底不会空
      );
    }

    // 还没从 API 拿到，就先用 username 顶着
    final user = authController.user.value;
    final username = user?.userName;
    return buildMyWalletQr(
      username: (username == null || username.isEmpty) ? null : username,
    );
  }

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController(), permanent: false);
    authController = Get.find<AuthController>();
    roleController = Get.find<RoleController>();
    transactionController = Get.find<TransactionController>();

    _loadSelfContact(); // 👈 用 API 查「自己」，避免 null
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  /// 🔍 用 lookupContact API 查自己（根据 username）
  Future<void> _loadSelfContact() async {
    try {
      final user = authController.user.value;
      final baseQuery = user?.userName ?? '';

      if (baseQuery.isEmpty) {
        setState(() {
          _loadingSelf = false;
        });
        return;
      }

      // 这里会走到 ApiService.lookupWalletContact → 后端
      final contact = await transactionController.lookupContact(baseQuery);

      setState(() {
        _selfContact = contact;
        _loadingSelf = false;
      });
    } catch (e) {
      setState(() {
        _loadingSelf = false;
      });
      // 失败也没关系，fallback 还会用 username 生成 QR
    }
  }

  /// 处理扫码结果：
  void _handleScan(String raw) {
    if (_isHandlingScan) return;
    _isHandlingScan = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = TransferQrPayload.tryParse(raw);

      if (!mounted) {
        _isHandlingScan = false;
        return;
      }

      if (payload == null) {
        _showError('Invalid wallet QR');
        _isHandlingScan = false;
        return;
      }

      // 从 payload 拿一个合适的 lookup key
      String? query;
      if (payload.phone != null && payload.phone!.isNotEmpty) {
        query = payload.phone;
      } else if (payload.email != null && payload.email!.isNotEmpty) {
        query = payload.email;
      } else if (payload.username != null && payload.username!.isNotEmpty) {
        query = payload.username;
      }

      if (query == null) {
        _showError('QR has no contact info');
        _isHandlingScan = false;
        return;
      }

      await _scannerCtrl.stop();

      final contact = await transactionController.lookupContact(query);

      if (!mounted) {
        _isHandlingScan = false;
        return;
      }

      if (contact == null) {
        _showError('Recipient not found');
        _isHandlingScan = false;
        await _scannerCtrl.start();
        return;
      }

      Get.to(
        () => TransferScreen(
          mode: 'transfer',
          lockedRecipient: LockedRecipient(
            walletId: contact.walletId,
            displayName: contact.displayName,
            phone: contact.phone ?? '-',
          ),
        ),
      );

      _isHandlingScan = false;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QrSlideSwitch(),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            if (tabC.tab.value == QrTab.show) {
              if (_loadingSelf) {
                return const Center(child: CircularProgressIndicator());
              }

              final payload = myWalletQrPayload;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: RepaintBoundary(
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 220,
                            gapless: true,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '让别人扫码这个二维码，就会自动找到你的钱包账号。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      payload,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: payload));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied wallet QR payload'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Payload'),
                    ),
                  ],
                ),
              );
            } else {
              // 扫描器
              return buildQrScanner(
                controller: _scannerCtrl,
                overlay: simpleScannerOverlay(size: 240),
                detectOnce: false,
                onDetect: _handleScan,
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        Text(
          tabC.tab.value == QrTab.show
              ? '让别人打开 Scanner 来扫你的二维码~'
              : '把二维码对准取景框，中间框内即可自动识别~',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
