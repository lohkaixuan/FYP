import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/SecurityCode.dart';
import 'package:mobile/Controller/BankController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Controller/WalletController.dart';

// For sending details to SecurityCodeScreen for validation.
class TransferDetails {
  final String type;
  final String fromAccountNumber;
  final String toAccountNumber;
  final double amount;
  final String? category;
  final String? detail;
  final String? item;

  TransferDetails({
    required this.type,
    required this.fromAccountNumber,
    required this.toAccountNumber,
    required this.amount,
    this.category,
    this.detail,
    this.item,
  });
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final roleController = Get.find<RoleController>();
  final bankController = Get.find<BankController>();
  final transactionController = Get.find<TransactionController>();
  final walletController = Get.find<WalletController>();

  final toAccountController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final itemController = TextEditingController();
  final categoryController = TextEditingController();

  // To track if the sender drop down box properties.
  bool isExpanded = false;
  late AccountBase? selectedAccount;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    selectedAccount = null;
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    itemController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  void _fetchAccounts() async {
    await bankController.getBankAccounts();
    await walletController.get(roleController.walletId);
  }

  bool _validateInputs() {
    if (selectedAccount == null || selectedAccount!.accId.isEmpty) {
      Get.snackbar("Error", "Please select a source account.");
      return false;
    }

    if (toAccountController.text.trim().isEmpty) {
      Get.snackbar("Error", "Please enter recipient account number.");
      return false;
    }

    if (amountController.text.trim().isEmpty ||
        double.tryParse(amountController.text) == null ||
        double.parse(amountController.text) <= 0) {
      Get.snackbar("Error", "Please enter a valid amount.");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: "Transfer Money",
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(
          () {
            final accounts = [
              ...bankController.accounts,
              if (walletController.wallet.value != null)
                walletController.wallet.value
            ];
            if (selectedAccount != null && accounts.isNotEmpty){
              selectedAccount = accounts.first;
            }

            if (bankController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                .withValues(
                                  red: 128,
                                  green: 128,
                                  blue: 128,
                                ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TransferDropDownButton<AccountBase>(
                          label: "FROM",
                          selectedAccount: selectedAccount,
                          accounts: accounts,
                          onChanged: (value) {
                            setState(() {
                              selectedAccount = value;
                            });
                          },
                          displayId: (account) => account.accId,
                          displayBalance: (account) => "(Balance: RM${account.accBalance?.toStringAsFixed(2) ?? "0.00"})",
                        ),
                      ],
                    ),
                  ),
                  OtherDetails(
                    title: "TO",
                    placeholder: "Enter recipient account number...",
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
                          Get.to(
                            () => SecurityCodeScreen(
                              data: TransferDetails(
                                type: "transfer",
                                fromAccountNumber:
                                    selectedAccount?.accId ?? "",
                                toAccountNumber: toAccountController.text,
                                amount:
                                    double.tryParse(amountController.text) ?? 0,
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
            );
          },
        ),
      ),
    );
  }
}

class TransferDropDownButton<T> extends StatelessWidget {
  final String label;
  final T? selectedAccount;
  final List<T?> accounts;
  final ValueChanged<T?> onChanged;
  final String Function(T) displayId;
  final String Function(T) displayBalance;

  const TransferDropDownButton(
      {super.key,
      required this.label,
      required this.selectedAccount,
      required this.accounts,
      required this.onChanged,
      required this.displayId,
      required this.displayBalance,});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: DropdownButtonFormField(
        isExpanded: false,
        initialValue: selectedAccount,
        hint: Text(
          label == "FROM"
              ? "Select source account"
              : "Select recipient account",
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
                Text(displayId(account as T), overflow: TextOverflow.ellipsis),
                const SizedBox(width: 10),
                Text(
                  displayBalance(account),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(red: 128, green: 128, blue: 128),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
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

  const OtherDetails(
      {super.key,
      required this.title,
      this.placeholder,
      this.textInputType,
      required this.controller,
      this.isRequired = true});

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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(red: 128, green: 128, blue: 128)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
                labelText: placeholder ?? '',
                errorText: controller.text.trim().isEmpty && isRequired
                    ? "Required"
                    : null),
            keyboardType: textInputType,
          ),
        ],
      ),
    );
  }
}
