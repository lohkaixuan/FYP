import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
            _segBtn(
              context,
              label: 'Show QR',
              selected: isShow,
              onTap: () => controller.setTab(QrTab.show),
            ),
            _segBtn(
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

  Widget _segBtn(BuildContext ctx,
      {required String label, required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(ctx);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
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
  final RxInt _sampleIndex = 0.obs;

  List<String> get _samples => const [
        // 0) Pay (URI)
        'wallet://pay?walletId=DEMO123&userId=USER888&amount=5.50&currency=MYR&note=test',
        // 1) Transfer (URI)
        'wallet://transfer?walletId=DEMO123&userId=USER999&amount=12.00&currency=MYR&note=to-friend',
        // 2) JSON
        '{"action":"pay","walletId":"DEMO123","userId":"USER777","amount":9.90,"currency":"MYR","note":"json"}',
      ];

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController(), permanent: false);
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

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
              final payload = _samples[_sampleIndex.value];
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
