import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalTabBar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile/Transfer/transfer.dart';

import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Controller/RoleController.dart';

import '../QR/QRUtlis.dart'; // PaymentQrPayload.parse / buildQrScanner / simpleScannerOverlay

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

/// 主组件（Stateful：持有扫描控制器 / 样本索引等）
class QRComponent extends StatefulWidget {
  const QRComponent({super.key});

  @override
  State<QRComponent> createState() => _QRComponentState();
}

class _QRComponentState extends State<QRComponent> {
  final _scannerCtrl = MobileScannerController();
  late final QrTabController tabC;
  /*
  final RxInt _sampleIndex = 0.obs;

  bool _isHandlingScan = false;//防止连环弹窗

  List<String> get _samples => const [
        // 0) Pay (URI)
        'wallet://pay?walletId=DEMO123&userId=USER888&amount=5.50&currency=MYR&note=test',
        // 1) Transfer (URI)
        'wallet://transfer?walletId=3fa85f64-5717-4562-b3fc-2c963f66afa6&userId=REALUSER&amount=12.00&currency=MYR&note=to-friend',
        // 2) JSON
        '{"action":"pay","walletId":"DEMO123","userId":"USER777","amount":9.90,"currency":"MYR","note":"json"}',
      ];
  */
  bool _isHandlingScan = false; // 防止连环弹窗

  late final AuthController authController;
  late final RoleController roleController;

   /// 当前登录用户的「真实钱包」QR 内容
  /// 这里用 URI 形式：wallet://transfer?walletId=...&userId=...
  String get myWalletQrPayload {
    final user = authController.user.value;
    final walletId = roleController.walletId;           // 真实的钱包 ID
    final userName = user?.userName ?? '';             // 显示名字

    return 'wallet://transfer'
        '?walletId=$walletId'
        '&userId=${Uri.encodeComponent(userName)}'
        '&amount=0'
        '&currency=MYR';
  }

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController(), permanent: false);
    authController = Get.find<AuthController>();
    roleController = Get.find<RoleController>();
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _handleScan(String raw) {
    if (_isHandlingScan) return;
    _isHandlingScan = true;
    
    // 把“真正的处理逻辑”放到这一帧 layout 结束之后再做
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    final parsed = PaymentQrPayload.parse(raw);
    
    if (!mounted) {
      _isHandlingScan = false;
      return;
    }

    if (parsed == null) {
      _showError('Invalid QR / 非法二维码');
      _isHandlingScan = false;
      return;
    }

    // 暂停相机，避免在弹 bottom sheet 时还在扫
    await _scannerCtrl.stop();

    // 直接跳转到 TransferScreen，并锁定收款方
    Get.to(() => TransferScreen(
          lockedRecipient: LockedRecipient(
            walletId: parsed.walletId,
            displayName: parsed.userId, // 目前没有 name，就先用 userId 顶着
            phone: '-',                 // 之后 QR 里加 phone 再填真正电话
          ),
        ));

    _isHandlingScan = false;
  });
  }

  Future<void> _showSheet(PaymentQrPayload p) async {
  _placeholderGo(p.action == QrAction.pay ? 'PAY' : 'TRANSFER', p);
  /*final isPay = p.action == QrAction.pay;
  
  return showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 重点：不要占满全屏高度
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPay ? 'Pay Request' : 'Transfer Request',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _kv('Wallet ID', p.walletId),
              _kv('User ID', p.userId),
              _kv('Amount', '${p.amount.toStringAsFixed(2)} ${p.currency}'),
              if (p.note?.isNotEmpty == true) _kv('Note', p.note!),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx); // 先关 sheet

                      if (isPay) {
                        // 未来如果要做 Pay Flow，可以在这里接 pay
                        _placeholderGo('PAY', p);
                      } else {
                        // Transfer Flow：跳到 TransferScreen，锁定对方账号
                        Get.to(() => TransferScreen(
                              lockedRecipient: LockedRecipient(
                                walletId: p.walletId,
                                displayName: p.userId, // 目前没 name，先用 userId 顶一下
                                phone: '-',             // 之后 QR 里加 phone 再换
                              ),
                            ));
                      }
                    },
                    icon: const Icon(Icons.check),
                    label:
                        Text(isPay ? 'Proceed to Pay' : 'Proceed to Transfer'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );*/
}

  void _placeholderGo(String actionName, PaymentQrPayload p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$actionName → ${p.walletId} · ${p.userId} · ${p.amount} ${p.currency}')),
    );
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
              /*final payload = _samples[_sampleIndex.value];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 样本切换
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(3, (i) {
                        const labels = ['Pay URI', 'Transfer URI', 'JSON'];
                        final selected = _sampleIndex.value == i;
                        return ChoiceChip(
                          label: Text(labels[i]),
                          selected: selected,
                          onSelected: (_) => _sampleIndex.value = i,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    // 显示 QR（白底黑码）
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: RepaintBoundary(
                          child: QrImageView(
                            data: payload.trim().isEmpty ? 'demo' : payload.trim(),
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
                    SelectableText(payload, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: payload));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied sample payload')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Payload'),
                    ),
                  ],
                ),
              );*/
              final payload = myWalletQrPayload;   // 👈 用我们刚刚写的 getter

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
                    Text(
                      '让别人扫码这个二维码，就会自动转到你的钱包。',
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
                            const SnackBar(content: Text('Copied wallet QR payload')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Payload'),
                    ),
                  ],
                ),
              );
            } 
            else {
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
        // 小提示
        Text(
          tabC.tab.value == QrTab.show
              ? '让别人扫码你的二维码~'
              : '把二维码对准取景框~',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(v, textAlign: TextAlign.right)),
        ],
      ),
    );
