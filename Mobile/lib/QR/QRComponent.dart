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

/// 主组件（Stateful：持有扫描控制器 / tab 控制器等）
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

  /// 当前登录用户的「收款 QR 内容」
  /// 使用我们统一的 TransferQrPayload + buildMyWalletQr
  String get myWalletQrPayload {
    final user = authController.user.value;
    final username = user?.userName ?? '';

    // TODO: 如果你的 user model 以后有 phone/email，可以一起塞进去
    return buildMyWalletQr(
      username: username.isEmpty ? null : username,
      // phone: user?.phoneNumber,
      // email: user?.email,
    );
  }

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController(), permanent: false);
    authController = Get.find<AuthController>();
    roleController = Get.find<RoleController>();
    transactionController = Get.find<TransactionController>();
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  /// 处理扫码结果：
  /// 1. 解析 TransferQrPayload
  /// 2. 通过 phone/email/username lookup 联系人
  /// 3. 跳转到 TransferScreen，并锁定收款人（LockedRecipient）
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

      // 从 payload 拿一个合适的“公开 ID”去查：phone > email > username
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

      // 暂停相机，避免底下 push 页面时还在扫
      await _scannerCtrl.stop();

      // 调 TransactionController 里的 lookupContact（前面我们已经实现过）
      final contact = await transactionController.lookupContact(query);

      if (!mounted) {
        _isHandlingScan = false;
        return;
      }

      if (contact == null) {
        _showError('Recipient not found');
        _isHandlingScan = false;
        await _scannerCtrl.start(); // 继续扫下一张
        return;
      }

      // 拿到 WalletContact → 转成 LockedRecipient，给 TransferScreen 使用
      Get.to(
        () => TransferScreen(
          mode: 'transfer',
          lockedRecipient: LockedRecipient.fromWalletContact(contact),
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
              // 👉 展示“我的收款码”
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
              // 👉 扫描器：用统一的 buildQrScanner
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
