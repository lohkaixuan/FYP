import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Role/RoleController.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'QRUtlis.dart'; // buildQrImage / buildQrScanner / simpleScannerOverlay / PaymentQrPayload
import 'QRslide.dart'; // 你的滑块 UI（内部用 GetX + Obx）
import 'QRtab.dart'; // 定义 QrTabController / QrTab 枚举 (show/scan)

class QR extends StatefulWidget {
  const QR({super.key});
  @override
  State<QR> createState() => _QRState();
}

class _QRState extends State<QR> {
  final _scannerCtrl = MobileScannerController();
  final RoleController roleC = Get.find<RoleController>();

  // —— 硬编码样本（可被另一台手机直接扫码）——
  final RxInt _sampleIndex = 0.obs; // 0=Pay URI, 1=Transfer URI, 2=JSON
  List<String> get _samples => const [
        // 0) Pay (URI)
        'wallet://pay?walletId=DEMO123&userId=USER888&amount=5.50&currency=MYR&note=test',
        // 1) Transfer (URI)
        'wallet://transfer?walletId=DEMO123&userId=USER999&amount=12.00&currency=MYR&note=to-friend',
        // 2) JSON
        '{"action":"pay","walletId":"DEMO123","userId":"USER777","amount":9.90,"currency":"MYR","note":"json"}',
      ];

  late final QrTabController tabC;

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController());
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  // 扫描结果处理（占位）
  void _handleScan(String raw) {
    final parsed = PaymentQrPayload.parse(raw);
    if (!mounted) return;
    if (parsed == null) {
      _showError('Invalid QR / 非法二维码');
      return;
    }
    _showSheet(parsed);
  }

  void _showSheet(PaymentQrPayload p) {
    final isPay = p.action == QrAction.pay;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPay ? 'Pay Request' : 'Transfer Request',
                style: Theme.of(context).textTheme.titleLarge),
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
                    Navigator.pop(ctx);
                    _placeholderGo(isPay ? 'PAY' : 'TRANSFER', p);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(isPay ? 'Proceed to Pay' : 'Proceed to Transfer'),
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
  }

  void _placeholderGo(String actionName, PaymentQrPayload p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '$actionName → ${p.walletId} · ${p.userId} · ${p.amount} ${p.currency}')),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: 'QR (Wallet)',
        subtitle: 'Welcome back 👋',
        // ✅ 根据全局角色控制器设置 toggle 状态
        activeIcon: Icons.people, // merchant icon
        inactiveIcon: Icons.shopping_cart, // user icon
      ),

      //AppBar(title: const Text('QR (Wallet)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ⛳️ 顶部滑块：Left=Show QR / Right=Scanner
            const QrSlideSwitch(),
            const SizedBox(height: 16),

            // 主内容：根据 tab 切换
            Expanded(
              child: Obx(() {
                if (tabC.tab.value == QrTab.show) {
                  // —— 左侧：固定样本二维码 —— //
                  final payload = _samples[_sampleIndex.value];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 样本选择（3种）
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
                        // 硬编码 QR
                        // 强制可见：白底 + 纯黑模块 + 固定尺寸
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white, // 白色底
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: RepaintBoundary(
                              child: QrImageView(
                                data: payload.trim().isEmpty
                                    ? 'demo'
                                    : payload.trim(),
                                version: QrVersions.auto,
                                size: 220,
                                gapless: true,
                                backgroundColor: Colors.white, // 明确白底
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black, // 眼睛强制黑色
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black, // 模块强制黑色
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(payload, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: payload));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied sample payload')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Payload'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // —— 右侧：扫描器 —— //
                  return buildQrScanner(
                    controller: _scannerCtrl,
                    overlay: simpleScannerOverlay(size: 240),
                    detectOnce: false,
                    onDetect: _handleScan,
                  );
                }
              }),
            ),
          ],
        ),
      ),
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
