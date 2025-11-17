import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
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
  final roleController = Get.find<RoleController>();
  final bankController = Get.find<BankController>();
  final transactionController = Get.find<TransactionController>();
  final walletController = Get.find<WalletController>();

  late TextEditingController toAccountController;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final itemController = TextEditingController();
  final categoryController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // To track if the sender drop down box properties.
  bool isExpanded = false;
  late AccountBase? selectedAccount;
  bool isRecipientLocked = false;

  @override
  void initState() {
    super.initState();

    toAccountController = TextEditingController();

    _fetchAccounts();
    selectedAccount = null;

    if (widget.lockedRecipient != null) {
      isRecipientLocked = true;
      // 这里“收款账号”直接填入锁定的钱包ID
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
    super.dispose();
  }

  void _fetchAccounts() async {
    await bankController.getBankAccounts();
    await walletController.get(roleController.walletId);

    setState(() {
      if (isReload() && !isRecipientLocked) {
        toAccountController = TextEditingController(
            text: walletController.wallet.value?.walletId);
      }

      // if (selectedAccount != null && accounts.isNotEmpty) {
      //   selectedAccount = accounts.first;
      // }
    });
  }

  List<AccountBase> get accounts {
    // TODO: Use parameters to show only bank accounts or both.
    final list = bankController.accounts.whereType<AccountBase>().toList();

    // If Transfer mode, include the wallet for the sender dropdown (AccountBase is the supertype)
    if (isTransfer() && walletController.wallet.value != null) {
      list.add(walletController.wallet.value!);
    }
    return list;
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) {
      return true;
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

            if (bankController.isLoading.value) {
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
                          GlobalAccountDropDownButton<AccountBase>(
                            label: "FROM",
                            selectedAccount: selectedAccount,
                            accounts: currentAccounts,
                            onChanged: (value) {
                              setState(() {
                                selectedAccount = value;
                              });
                            },
                            displayId: (account) => account.accId,
                            displayBalance: (account) =>
                                "(Balance: RM${account.accBalance?.toStringAsFixed(2) ?? "0.00"})",
                          ),
                        ],
                      ),
                    ),

                    // 2. PAY TO 卡片（只在扫码锁定收款方时显示）
                    if (isRecipientLocked) ...[
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
                                widget.lockedRecipient!.phone,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OtherDetails(
                      title: "TO",
                      placeholder: isRecipientLocked
                          ? "Recipient account is locked"
                          : "Enter recipient account number...",
                      readOnly: isRecipientLocked || isReload(),
                      isRequired: !isRecipientLocked,
                      textInputType: TextInputType.number,
                      controller: toAccountController,
                    ),
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

class GlobalAccountDropDownButton<T> extends StatelessWidget {
  final String label;
  final T? selectedAccount;
  final List<T> accounts;
  final ValueChanged<T?> onChanged;
  final String Function(T) displayId;
  final String Function(T) displayBalance;
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
    return DropdownButtonFormField<T>(
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

// TODO: Maybe Removed.
// class ToContactScreen extends StatefulWidget {
//   const ToContactScreen({super.key});

//   @override
//   State<ToContactScreen> createState() => _ToContactScreenState();
// }

// class _ToContactScreenState extends State<ToContactScreen> {
//   Map<String, String> phoneNumbers = {};

//   final options = [
//     {
//       "label": "FROM",
//       "title": "Sender phone number",
//       "subtitle": "e.g. 012-3456789",
//     },
//     {
//       "label": "TO",
//       "title": "Recipient phone number",
//       "subtitle": "e.g. 012-3456789",
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ...options.map((option) {
//           return Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(option['label']!),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: TextField(
//                     keyboardType: TextInputType.phone,
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(
//                           RegExp(r'^\+?6?0?[0-9\s\-]*$')),
//                     ],
//                     decoration: InputDecoration(
//                       labelText: option["title"],
//                       hintText: option["subtitle"],
//                       border: const OutlineInputBorder(),
//                     ),
//                     onChanged: (value) =>
//                         phoneNumbers[option['label']!] = value,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//         const OtherDetails(
//           title: "AMOUNT",
//           placeholder: "Enter amount...",
//           textInputType: TextInputType.number,
//         ),
//         const OtherDetails(
//           title: "NOTE (OPTIONAL)",
//           placeholder: "Enter purpose of transfer...",
//           textInputType: TextInputType.text,
//         ),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: () {
//               Get.to(() => const SecurityCodeScreen());
//             },
//             child: const Text("Continue"),
//           ),
//         ),
//       ],
//     );
//   }
// }

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
