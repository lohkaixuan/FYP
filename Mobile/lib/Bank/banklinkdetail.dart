import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BankController.dart';
import 'package:mobile/Utils/api_dialogs.dart';

class BankLinkDetailPage extends StatefulWidget {
  final String linkId;
  final String? bankName;
  final String? externalRef;
  final Future<void> Function()? onRefresh;
  const BankLinkDetailPage({
    super.key,
    required this.linkId,
    this.bankName,
    this.externalRef,
    this.onRefresh,
  });

  @override
  State<BankLinkDetailPage> createState() => _BankLinkDetailPageState();
}

class _BankLinkDetailPageState extends State<BankLinkDetailPage> {
  final api = Get.find<ApiService>();
  bool _loading = false;
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _loading = true);
    try {
      final res = await api.providerBalanceByLink(widget.linkId);
      setState(() => _balance = res);
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Balance failed',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transfer() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transfer from linked bank',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ApiDialogs.showError('Enter a valid amount', fallbackTitle: 'Validation');
      return;
    }

    try {
      final res = await api.providerTransferByLink(
        linkId: widget.linkId,
        amount: amount,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      ApiDialogs.showSuccess(
        'Transfer sent',
        const JsonEncoder.withIndent('  ').convert(res),
      );
      await _fetchBalance();
      if (widget.onRefresh != null) widget.onRefresh!();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Transfer failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlobalScaffold(
      title: widget.bankName ?? 'Linked Bank',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text(widget.bankName ?? 'Bank link'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Link ID: ${widget.linkId}'),
                    if (widget.externalRef != null)
                      Text('External Ref: ${widget.externalRef}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Balance',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loading ? null : _fetchBalance,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_balance != null)
                      Text(const JsonEncoder.withIndent('  ')
                          .convert(_balance))
                    else
                      const Text('No balance fetched yet.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _transfer,
                icon: const Icon(Icons.send),
                label: const Text('Transfer'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
