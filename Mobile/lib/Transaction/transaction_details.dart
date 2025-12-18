import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TransactionDetails extends StatefulWidget {
  const TransactionDetails({super.key});

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  final transactionController = Get.find<TransactionController>();

  /// 用来截图收据区域
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final String? transactionId = Get.parameters['id'];
    if (transactionId != null) {
      Future.microtask(() => transactionController.get(transactionId));
    }
  }

  // 🔥 动态标题 icon + 文案
  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case "pay":
        return Icons.shopping_bag_rounded;
      case "transfer":
        return Icons.sync_alt_rounded;
      case "topup":
      case "top_up":
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _typeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case "pay":
        return "Payment Receipt";
      case "transfer":
        return "Transfer Receipt";
      case "topup":
      case "top_up":
        return "Top-Up Receipt";
      default:
        return "Transaction Receipt";
    }
  }

  // Status color
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'success') return AppTheme.cSuccess;
    if (s == 'failed') return AppTheme.cError;
    if (s == 'pending') return AppTheme.cWarning;
    return Colors.grey;
  }

  String _displayValue(dynamic item) {
    if (item == null) return '-';
    if (item is DateTime) return _formatTimestamp(item);
    if (item is double) return 'RM ${item.toStringAsFixed(2)}';
    return item.toString();
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// 把收据区域转成 PNG 文件
  Future<File?> _captureReceiptPng() async {
    final boundary =
        _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      ApiDialogs.showError(
        'Unable to capture receipt',
        fallbackTitle: 'Error',
      );
      return null;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  // 🔽 Download / Share 按钮
  Future<void> _downloadReceipt() async {
    final file = await _captureReceiptPng();
    if (file == null) return;
    ApiDialogs.showSuccess(
      'Download',
      'Receipt saved: ${file.path}',
    );
  }

  Future<void> _shareReceipt() async {
    final file = await _captureReceiptPng();
    if (file == null) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Transaction receipt',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const GlobalAppBar(title: 'Transaction Details'),
      body: Obx(() {
        if (transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final tx = transactionController.transaction.value;
        if (tx == null) {
          return const Center(
            child:
                Text('Invalid transaction!', style: TextStyle(color: Colors.red)),
          );
        }

        final typeIcon = _typeIcon(tx.type);
        final typeLabel = _typeLabel(tx.type);

        // 原始 map
        final raw = tx.toMap();

        // 🟣 单独拿出 From / To
        // final fromValue = raw['From'];
        // final toValue = raw['To'];

        // 🟣 过滤掉不想显示的字段：Amount / Category / Payment Method / Status / Last Update / Type / From / To
        final entries = raw.entries
            .where((e) =>
                e.value != null &&
                !{
                  'Amount',
                  'Category',
                  'Payment Method',
                  'Status',
                  'Last Update',
                  'Type',
                  'Timestamp',
                }.contains(e.key))
            .toList();

        final String? category = tx.category;
        final String? paymentMethod = tx.paymentMethod;

        return Column(
          children: [
            // ========= 可滚动 + 可截图区域 =========
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: Column(
                    children: [
                      // =========================
                      // 🔵 收据头（含图标 + title + amount + tag）
                      // =========================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.rLg),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow,
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(typeIcon, color: cs.onPrimary, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              typeLabel,
                              style: AppTheme.textMediumBlack.copyWith(
                                color: cs.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 💰 金额
                            Text(
                              'RM ${tx.amount.toStringAsFixed(2)}',
                              style: AppTheme.textBigBlack.copyWith(
                                color: cs.onPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 🟩 状态 + Category + Payment method tag
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // status tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(tx.status ?? '')
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _getStatusColor(tx.status ?? '')
                                          .withOpacity(0.7),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    (tx.status ?? "").toUpperCase(),
                                    style: AppTheme.textMediumBlack.copyWith(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                if (category != null &&
                                    category.trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.onPrimary.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                        color: cs.onPrimary.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: AppTheme.textMediumBlack.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                if (paymentMethod != null &&
                                    paymentMethod.trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.onPrimary.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                        color: cs.onPrimary.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      paymentMethod,
                                      style: AppTheme.textMediumBlack.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Text(
                              _formatTimestamp(tx.timestamp!),
                              style: AppTheme.textSmallGrey.copyWith(
                                color: cs.onPrimary.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // 📄 收据内容卡片
                      // =========================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppTheme.rLg),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.list_alt_rounded,
                                    color: cs.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Transaction Details",
                                  style: AppTheme.textMediumBlack.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(color: cs.outline),

                            const SizedBox(height: 4),

                         
                            // 🟣 其他字段照旧一行一块
                            ...entries.map((e) {
                              final label = e.key;
                              final value = _displayValue(e.value);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: AppTheme.textSmallGrey.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      value,
                                      style: AppTheme.textMediumBlack
                                          .copyWith(
                                        color: cs.onSurface,
                                      ),
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Divider(
                                        color:
                                            cs.outline.withOpacity(0.4)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================
            // 🟣 底部 ACTION BAR：Download / Share
            // =========================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async => _downloadReceipt(),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text("Download"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: cs.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.rMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async => _shareReceipt(),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text("Share"),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.rMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
