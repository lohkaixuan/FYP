import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/SecurityCode.dart';
import 'package:mobile/Controller/BankController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/QR/QRUtlis.dart';

// For sending details to SecurityCodeScreen for validation.
class TransferDetails {
  final String type;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? category;
  final String? detail;
  final String? item;

  TransferDetails({
    required this.type,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.category,
    this.detail,
    this.item,
  });
}

/// Represents a pre-resolved recipient that the user cannot edit.
class LockedRecipient {
  final String walletId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? username;
  final String walletType;

  const LockedRecipient({
    required this.walletId,
    required this.displayName,
    this.phone,
    this.email,
    this.username,
    this.walletType = 'user',
  });

  factory LockedRecipient.fromWalletContact(WalletContact contact) {
    return LockedRecipient(
      walletId: contact.walletId,
      displayName: contact.currentDisplayName,
      phone: contact.phone,
      email: contact.email,
      username: contact.username,
      walletType: contact.activeWalletType,
    );
  }

  String get primaryIdentifier =>
      phone ?? email ?? (username == null ? walletId : '@$username');
}

// This is a shared widget between Transfer and Reload.
class TransferScreen extends StatefulWidget {
  final String mode;
  TransferScreen({super.key, required String mode, this.lockedRecipient})
      : mode = mode.toLowerCase().trim();
  final LockedRecipient? lockedRecipient;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final api = Get.find<ApiService>();
  final roleController = Get.find<RoleController>();
  final bankController = Get.find<BankController>();
  final transactionController = Get.find<TransactionController>();
  final walletController = Get.find<WalletController>();

  late TextEditingController toAccountController;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final itemController = TextEditingController();
  final categoryController = TextEditingController();
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // To track if the sender drop down box properties.
  bool isExpanded = false;
  AccountBase? selectedAccount;
  WalletContact? _selectedContact;
  WalletAccountOption? _userWalletOption;
  WalletAccountOption? _merchantWalletOption;
  bool _walletsLoading = false;

  @override
  void initState() {
    super.initState();

    toAccountController = TextEditingController();

    _fetchAccounts();
    selectedAccount = null;

    if (widget.lockedRecipient != null) {
      toAccountController.text = widget.lockedRecipient!.walletId;
    }
  }

  @override
  void dispose() {
    toAccountController.dispose();
    amountController.dispose();
    noteController.dispose();
    itemController.dispose();
    categoryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAccounts() async {
    await bankController.getBankAccounts();
    await walletController.get(roleController.walletId);
    if (isTransfer()) {
      await _loadWalletOptions();
    } else {
      setState(() {
        _walletsLoading = false;
        final currentAccounts = accounts;
        if (currentAccounts.isNotEmpty) {
          if (selectedAccount == null ||
              !currentAccounts.contains(selectedAccount)) {
            selectedAccount = currentAccounts.first;
          }
        } else {
          selectedAccount = null;
        }
        if (!isRecipientLocked) {
          toAccountController = TextEditingController(
              text: walletController.wallet.value?.walletId);
        }
      });
    }
  }

  Future<void> _loadWalletOptions() async {
    if (!isTransfer()) {
      setState(() {
        _walletsLoading = false;
      });
      return;
    }
    setState(() {
      _walletsLoading = true;
    });
    try {
      final me = await api.me();
      roleController.userWalletId.value =
          (me.userWalletId ?? roleController.userWalletId.value);
      if ((me.merchantWalletId ?? '').isNotEmpty) {
        roleController.merchantWalletId.value = me.merchantWalletId!;
      }
      WalletAccountOption? userOption;
      WalletAccountOption? merchantOption;
      if ((me.userWalletId ?? '').isNotEmpty) {
        userOption = WalletAccountOption(
          walletId: me.userWalletId!,
          balance: me.userWalletBalance ?? me.balance,
          label: '${me.userName} Wallet',
        );
      }
      if ((me.merchantWalletId ?? '').isNotEmpty) {
        final name = (me.merchantName?.isNotEmpty ?? false)
            ? me.merchantName!
            : 'Merchant';
        merchantOption = WalletAccountOption(
          walletId: me.merchantWalletId!,
          balance: me.merchantWalletBalance,
          label: '$name Wallet',
        );
      }
      setState(() {
        _userWalletOption = userOption;
        _merchantWalletOption = merchantOption;
        final currentAccounts = accounts;
        if (currentAccounts.isNotEmpty) {
          if (selectedAccount == null ||
              !currentAccounts.contains(selectedAccount)) {
            selectedAccount = currentAccounts.first;
          }
        } else {
          selectedAccount = null;
        }
      });
    } catch (ex) {
      debugPrint('Failed to load wallet options: $ex');
    } finally {
      setState(() {
        _walletsLoading = false;
      });
    }
  }

  List<AccountBase> get accounts {
    if (isReload()) {
      return bankController.accounts.map<AccountBase>((b) => b).toList();
    }
    final list = <AccountBase>[];
    if (_userWalletOption != null) list.add(_userWalletOption!);
    if (_merchantWalletOption != null) list.add(_merchantWalletOption!);
    return list;
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No wallet available to send from."),
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (!isRecipientLocked) {
      //没锁时才检查输入框
      if (toAccountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter recipient account number."), duration: Duration(seconds: 3),));
        return false;
      }
    } else {
      if (toAccountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recipient is not resolved."), duration: Duration(seconds: 3),));
        return false;
      }
    }

    if (amountController.text.trim().isEmpty ||
        double.tryParse(amountController.text) == null ||
        double.parse(amountController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount."), duration: Duration(seconds: 3),));
      return false;
    }

    final fromWalletId = selectedAccount!.accId;
    final toWalletId = toAccountController.text.trim();

    if (fromWalletId == toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sender and recipient cannot be the same."), duration: Duration(seconds: 3),));
      return false;
    }

    return true;
  }

  bool isTransfer() {
    return widget.mode == 'transfer';
  }

  bool isReload() {
    return widget.mode == 'reload';
  }

  bool get isRecipientLocked =>
      widget.lockedRecipient != null || _selectedContact != null;

  Future<void> _onSearchContact() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final contact = await transactionController.lookupContact(q);
    if (contact != null) {
      _applySelectedContact(contact);
    } else {
      Get.snackbar("Not found", "No user or merchant matched this search");
    }
  }

  Future<void> _onScanQr() async {
    final contact = await QRUtils.scanWalletTransfer();
    if (contact != null) {
      _applySelectedContact(contact);
    } else {
      Get.snackbar("QR Error", "Invalid or unsupported QR");
    }
  }

  void _applySelectedContact(WalletContact contact) {
    setState(() {
      _selectedContact = contact;
      toAccountController.text = contact.walletId;
    });
  }

  void _clearSelectedContact() {
    if (_selectedContact == null) return;
    setState(() {
      _selectedContact = null;
      if (widget.lockedRecipient == null) {
        toAccountController.clear();
      }
    });
  }

  void _onWalletTypeChanged(String type) {
    if (_selectedContact == null) return;
    setState(() {
      _selectedContact!.setActiveWalletType(type);
      toAccountController.text = _selectedContact!.walletId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: isTransfer() ? "Transfer Money" : "Reload Wallet",
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(
          () {
            /*final accounts = [
            ...bankController.accounts,
            if (walletController.wallet.value != null)
              walletController.wallet.value
            ];*/

            // final wallet = walletController.wallet.value;

            // final accounts = <AccountBase>[
            //   if (wallet != null) wallet,
            // ];
            final currentAccounts = accounts;

            // 确保 selectedAccount 一定是当前列表里的其中一个，否则重置
            if (currentAccounts.isEmpty) {
              selectedAccount = null;
            } else if (selectedAccount == null ||
                !currentAccounts.contains(selectedAccount)) {
              selectedAccount = currentAccounts.first;
            }

            // // 确保 selectedAccount 一定是当前列表里的其中一个，否则重置
            // if (accounts.isEmpty) {
            //   selectedAccount = null;
            // } else if (selectedAccount == null ||
            //     !accounts.contains(selectedAccount)) {
            //   selectedAccount = accounts.first;
            // }

            if (bankController.isLoading.value || _walletsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. FROM 卡片
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FROM",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 5),
                          GlobalAccountDropDownButton(
                            label: "FROM",
                            selectedAccount: selectedAccount,
                            accounts: currentAccounts,
                            onChanged: (value) {
                              setState(() {
                                selectedAccount = value;
                              });
                            },
                            displayId: (account) => _accountLabel(account),
                            displayBalance: (account) =>
                                "(Balance: RM${account.accBalance?.toStringAsFixed(2) ?? "0.00"})",
                          ),
                        ],
                      ),
                    ),

                    // 2. PAY TO 卡片（只在扫码锁定收款方时显示）
                    if (widget.lockedRecipient != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PAY TO",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(150),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.lockedRecipient!.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                widget.lockedRecipient!.primaryIdentifier,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_selectedContact != null) ...[
                      _RecipientCard(
                        contact: _selectedContact,
                        onScanQr: _onScanQr,
                        onWalletTypeChanged: _onWalletTypeChanged,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearSelectedContact,
                          icon: const Icon(Icons.close),
                          label: const Text("Clear recipient"),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isTransfer() && widget.lockedRecipient == null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "TO",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _searchController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              "Phone / Email / Username / Merchant Name",
                                        ),
                                      ),
                                      
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _onSearchContact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  onPressed: _onScanQr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      OtherDetails(
                        title: "TO",
                        placeholder: "Enter recipient account number...",
                        readOnly: isRecipientLocked || isReload(),
                        isRequired: !isRecipientLocked,
                        textInputType: TextInputType.number,
                        controller: toAccountController,
                      ),
                    ],
                    OtherDetails(
                      title: "AMOUNT",
                      placeholder: "Enter amount...",
                      textInputType: TextInputType.number,
                      controller: amountController,
                    ),
                    OtherDetails(
                      title: "CATEGORY (OPTIONAL)",
                      placeholder: "E.g. Food, Bills",
                      textInputType: TextInputType.text,
                      controller: categoryController,
                      isRequired: false,
                    ),
                    OtherDetails(
                      title: "NOTE (OPTIONAL)",
                      placeholder: "Enter purpose of transfer...",
                      textInputType: TextInputType.text,
                      controller: noteController,
                      isRequired: false,
                    ),
                    OtherDetails(
                      title: "ITEM (OPTIONAL)",
                      placeholder: "E.g. Nasi Lemak + Teh Tarik",
                      textInputType: TextInputType.text,
                      controller: itemController,
                      isRequired: false,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_validateInputs()) {
                            final parsedAmount =
                                double.tryParse(amountController.text) ?? 0;

                            // 🔍 看看原始文字 & 解析后是多少
                            debugPrint(
                              '[TransferScreen] raw="${amountController.text}", parsed=$parsedAmount',
                            );

                            Get.to(
                              () => SecurityCodeScreen(
                                data: TransferDetails(
                                  type: isReload() ? "topup" : "transfer",
                                  fromAccountId: selectedAccount?.accId ?? "",
                                  toAccountId: toAccountController.text,
                                  amount: parsedAmount, //  这里一定要用 parsedAmount
                                  category: categoryController.text,
                                  detail: noteController.text,
                                  item: itemController.text,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text("Continue"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WalletAccountOption implements AccountBase {
  final String walletId;
  final double? balance;
  final String label;
  WalletAccountOption({
    required this.walletId,
    required this.balance,
    required this.label,
  });

  @override
  String get accId => walletId;

  @override
  double? get accBalance => balance;
}

String _accountLabel(AccountBase account) {
  if (account is WalletAccountOption) {
    return account.label;
  }
  return account.accId;
}

class GlobalAccountDropDownButton extends StatelessWidget {
  final String label;
  final AccountBase? selectedAccount;
  final List<AccountBase> accounts;
  final ValueChanged<AccountBase?> onChanged;
  final String Function(AccountBase) displayId;
  final String Function(AccountBase) displayBalance;
  final bool isRequired;

  const GlobalAccountDropDownButton(
      {super.key,
      required this.label,
      required this.selectedAccount,
      required this.accounts,
      required this.onChanged,
      required this.displayId,
      required this.displayBalance,
      this.isRequired = true});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AccountBase>(
      isExpanded: false,
      initialValue: selectedAccount,
      hint: Text(
        label == "FROM" ? "Select source account" : "Select recipient account",
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayId(account), overflow: TextOverflow.ellipsis),
              Text(
                displayBalance(account),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (isRequired) {
          if (value == null) {
            return "Required";
          }
          return null;
        }
        return null;
      },
    );
  }
}

class OtherDetails extends StatelessWidget {
  final String title;
  final String? placeholder;
  final TextInputType? textInputType;
  final TextEditingController controller;
  final bool isRequired;
  final bool readOnly;

  const OtherDetails(
      {super.key,
      required this.title,
      this.placeholder,
      this.textInputType,
      required this.controller,
      this.isRequired = true,
      this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: placeholder ?? '',
              suffixIcon: readOnly ? const Icon(Icons.lock) : null,
            ),
            keyboardType: textInputType,
            validator: (value) {
              if (!readOnly && isRequired) {
                if (value == null || value.trim().isEmpty) {
                  return "Required";
                }

                if (textInputType == TextInputType.number) {
                  if (double.tryParse(value) == null) {
                    return "Invalid number format";
                  }
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
// 收款人卡片：显示名字 + phone/email/username + 扫码按钮
class _RecipientCard extends StatelessWidget {
  final WalletContact? contact;
  final VoidCallback onScanQr;
  final ValueChanged<String>? onWalletTypeChanged;

  const _RecipientCard({
    required this.contact,
    required this.onScanQr,
    this.onWalletTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasToggle = contact?.hasMerchantWallet ?? false;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              contact?.currentDisplayName ?? 'No recipient selected',
            ),
            subtitle: contact == null
                ? const Text(
                    'Scan QR or search by phone/email/username/merchant')
                : Text([
                    if (contact?.phone != null) contact!.phone!,
                    if (contact?.email != null) contact!.email!,
                    if (contact?.username != null) '@${contact!.username!}',
                  ].where((element) => element.isNotEmpty).join(' | ')),
            trailing: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: onScanQr,
            ),
          ),
          if (hasToggle)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('User Wallet'),
                    selected: contact!.activeWalletType == 'user',
                    onSelected: (selected) {
                      if (selected) onWalletTypeChanged?.call('user');
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text(contact!.merchantName ?? 'Merchant Wallet'),
                    selected: contact!.activeWalletType == 'merchant',
                    onSelected: (selected) {
                      if (selected) onWalletTypeChanged?.call('merchant');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

