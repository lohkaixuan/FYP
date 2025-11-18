// lib/Screen/transferwallet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/QR/QRUtlis.dart';

class WalletTransferScreen extends StatefulWidget {
  const WalletTransferScreen({super.key});

  @override
  State<WalletTransferScreen> createState() => _WalletTransferScreenState();
}

class _WalletTransferScreenState extends State<WalletTransferScreen> {
  final transactionController = Get.find<TransactionController>();
  final walletController = Get.find<WalletController>();

  WalletContact? _selectedContact;

  final _amountController = TextEditingController();
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  final _itemController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    _noteController.dispose();
    _itemController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _onScanQr() async {
    final contact = await QRUtils.scanWalletTransfer();
    if (contact != null) {
      setState(() => _selectedContact = contact);
    } else {
      Get.snackbar("QR Error", "Invalid or unsupported QR");
    }
  }

  Future<void> _onSearchContact() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    // 这里假设你在 TransactionController 里实现了 lookupContact(query)
    final contact = await transactionController.lookupContact(q);
    if (contact != null) {
      setState(() => _selectedContact = contact);
    } else {
      Get.snackbar("Not found", "No user with this phone/email/username");
    }
  }

  Future<void> _onSubmit() async {
    if (_selectedContact == null) {
      Get.snackbar("Missing", "Please select recipient");
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar("Invalid", "Please enter valid amount");
      return;
    }

    final myWalletId = walletController.wallet.value?.walletId ?? "";
    if (myWalletId.isEmpty) {
      Get.snackbar("Error", "Wallet not loaded");
      return;
    }

    if (myWalletId == _selectedContact!.walletId) {
      Get.snackbar("Error", "Sender and recipient cannot be the same");
      return;
    }

    // ✅ 这里直接用 create() 调用后端 transfer API
    await transactionController.create(
      type: "transfer",
      from: myWalletId,
      to: _selectedContact!.walletId,
      amount: amount,
      // 如果后端支持，可以把 note/category/item 也带进去
      detail: _noteController.text.isEmpty ? null : _noteController.text,
      item: _itemController.text.isEmpty ? null : _itemController.text,
      overrideCategoryCsv: _categoryController.text.isEmpty
          ? null
          : _categoryController.text,
    );

    // 成功后简单返回或提示
    Get.back();
    Get.snackbar("Success", "Transfer submitted");
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: "Wallet Transfer",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _RecipientCard(
              contact: _selectedContact,
              onScanQr: _onScanQr,
            ),
            const SizedBox(height: 12),

            // 搜索栏：phone / email / username
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Phone / Email / Username",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearchContact,
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: "Category (optional)",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Note (optional)",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: "Item (optional)",
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSubmit,
                child: const Text("Confirm & Pay"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 收款人卡片：显示名字 + phone/email/username + 扫码按钮
class _RecipientCard extends StatelessWidget {
  final WalletContact? contact;
  final VoidCallback onScanQr;

  const _RecipientCard({
    required this.contact,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(
          contact?.displayName ?? "No recipient selected",
        ),
        subtitle: contact == null
            ? const Text("Scan QR or search by phone/email/username")
            : Text([
                if (contact?.phone != null) contact!.phone!,
                if (contact?.email != null) contact!.email!,
                if (contact?.username != null) "@${contact!.username!}",
              ].join(" · ")),
        trailing: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: onScanQr,
        ),
      ),
    );
  }
}
