import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GlobalTabBar.dart';
import 'package:mobile/Component/SecurityCode.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalScaffold(
      title: "Transfer Money",
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [TransferTabView()],
        ),
      ),
    );
  }
}

class TransferTabView extends StatefulWidget {
  const TransferTabView({super.key});
  @override
  State<TransferTabView> createState() => _TransferTabViewState();
}

class _TransferTabViewState extends State<TransferTabView> {
  final isTransfer = true.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  globalTabBar(
                    context,
                    label: "To Account",
                    selected: isTransfer.value,
                    onTap: () => isTransfer.value = true,
                  ),
                  globalTabBar(
                    context,
                    label: "To Contact",
                    selected: !isTransfer.value,
                    onTap: () => isTransfer.value = false,
                  ),
                ],
              ),
            ),
          ),
          Obx(() => isTransfer.value
              ? const ToAccountScreen()
              : const ToContactScreen()),
        ],
      ),
    );
  }
}

class FromToModel {
  final bool from;
  final String accountName;
  final double amount;

  FromToModel({
    required this.from,
    required this.accountName,
    required this.amount,
  });
}

class ToAccountScreen extends StatefulWidget {
  const ToAccountScreen({super.key});

  @override
  State<ToAccountScreen> createState() => _ToAccountScreenState();
}

class _ToAccountScreenState extends State<ToAccountScreen> {
  Map<String, bool> isExpanded = {"FROM": false, "TO": false};

  Map<String, FromToModel?> selectedAccount = {"FROM": null, "TO": null};

  // TODO: Retrieve the balance from database.
  final options = [
    {
      "label": "FROM",
      "title": "Main Account",
      "subtitle": "Balance: RM2000",
    },
    {
      "label": "TO",
      "title": "Select Recipient",
      "subtitle": "Base account or contact",
    },
  ];

  // TODO: Set the sender and receipient account options.
  final List<FromToModel> dropDownOptions = [
    FromToModel(from: true, accountName: "Main Account", amount: 2000),
    FromToModel(from: true, accountName: "Savings Account", amount: 5000),
    FromToModel(from: true, accountName: "Investment Account", amount: 10000),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...options.map((option) {
            final label = option["label"]!;

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option["label"].toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                            red: 128,
                            green: 128,
                            blue: 128,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TransferDropDownButton(
                    label: label,
                    selectedAccount: selectedAccount[label],
                    accounts: dropDownOptions,
                    onChanged: (value) {
                      setState(() {
                        selectedAccount[label] = value;
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const OtherDetails(
            title: "AMOUNT",
            placeholder: "Enter amount...",
            textInputType: TextInputType.number,
          ),
          const OtherDetails(
            title: "NOTE (OPTIONAL)",
            placeholder: "Enter purpose of transfer...",
            textInputType: TextInputType.text,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.to(() => const SecurityCodeScreen());
              },
              child: const Text("Continue"),
            ),
          ),
        ],
      ),
    );
  }
}

class TransferDropDownButton extends StatelessWidget {
  final String label;
  final FromToModel? selectedAccount;
  final List<FromToModel> accounts;
  final ValueChanged<FromToModel?> onChanged;

  const TransferDropDownButton({
    super.key,
    required this.label,
    required this.selectedAccount,
    required this.accounts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FromToModel>(
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
        return DropdownMenuItem<FromToModel>(
          value: account,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(account.accountName),
              const SizedBox(width: 10),
              Text(
                "(Balance: RM${account.amount.toStringAsFixed(2)})",
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
    );
  }
}

class ToContactScreen extends StatefulWidget {
  const ToContactScreen({super.key});

  @override
  State<ToContactScreen> createState() => _ToContactScreenState();
}

class _ToContactScreenState extends State<ToContactScreen> {
  Map<String, String> phoneNumbers = {};

  final options = [
    {
      "label": "FROM",
      "title": "Sender phone number",
      "subtitle": "e.g. 012-3456789",
    },
    {
      "label": "TO",
      "title": "Recipient phone number",
      "subtitle": "e.g. 012-3456789",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option['label']!),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\+?6?0?[0-9\s\-]*$')),],
                    decoration: InputDecoration(
                      labelText: option["title"],
                      hintText: option["subtitle"],
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        phoneNumbers[option['label']!] = value,
                  ),
                ),
              ],
            ),
          );
        }),
        const OtherDetails(
          title: "AMOUNT",
          placeholder: "Enter amount...",
          textInputType: TextInputType.number,
        ),
        const OtherDetails(
          title: "NOTE (OPTIONAL)",
          placeholder: "Enter purpose of transfer...",
          textInputType: TextInputType.text,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Get.to(() => const SecurityCodeScreen());
            },
            child: const Text("Continue"),
          ),
        ),
      ],
    );
  }
}

class OtherDetails extends StatelessWidget {
  final String title;
  final String? placeholder;
  final TextInputType? textInputType;

  const OtherDetails(
      {super.key, required this.title, this.placeholder, this.textInputType});

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
          TextField(
            decoration: InputDecoration(labelText: placeholder ?? ''),
            keyboardType: textInputType,
          ),
        ],
      ),
    );
  }
}
