import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GlobalTabBar.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const GlobalAppBar(title: "Transfer Money"),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: const Column(
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
            () => Row(
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
          Obx(() => isTransfer.value ? ToAccountScreen() : const Placeholder()),
        ],
      ),
    );
  }
}

class ToAccountScreen extends StatelessWidget {
  ToAccountScreen({super.key});

  final options = [
    {
      "label": "FROM",
      "title": "Main Account",
      "subtitle": "Balance: RM2000",
      "onTap": () {} // TODO: Navigate to the select account page.
    },
    {
      "label": "TO",
      "title": "Select Recipient",
      "subtitle": "Base account or contact",
      "onTap": () {} // TODO: Navigate to the select recipient account page.
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option["label"].toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(red: 128, green: 128, blue: 128)),
                ),
                const SizedBox(height: 5),
                ListTile(
                  shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.onSurface)),
                  leading: const Icon(Icons.wallet),
                  title: Text(
                    option["title"].toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    option["subtitle"].toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(red: 128, green: 128, blue: 128), fontSize: 10),
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: option["onTap"] as VoidCallback,
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
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppTheme.brandAccent)),
            onPressed: () {
              const Placeholder(); // TODO: Go to enter security key.
            },
            child: const Text(
              "Continue",
              style: AppTheme.textMediumBlack,
            ),
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(red: 128, green: 128, blue: 128)),
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
