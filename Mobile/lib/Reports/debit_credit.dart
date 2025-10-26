import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';

class DebitCreditScreen extends StatelessWidget {
  // final List<Map<String, dynamic>> data = Get.arguments;
  const DebitCreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>>? data = Get.arguments as List<Map<String, dynamic>>?;

    return Scaffold(
      appBar: const GlobalAppBar(
        title: 'Debit and Credit Details',
      ),
      body: ListView.builder(
        itemCount: data!.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final title = item['title'];
          final amount = item['amount'] as double? ?? 0.0;
          final color = item['color'];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: DebitCreditCard(
              leading: color,
              title: title,
              trailing: 'RM ${amount.toStringAsFixed(2)}',
            ),
          );
        },
      ),
    );
  }
}

class DebitCreditCard extends StatelessWidget {
  final Color leading;
  final String title;
  final String trailing;

  const DebitCreditCard(
      {super.key,
      required this.leading,
      required this.title,
      required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.square, color: leading),
          const SizedBox(width: 5),
          Text(
            title,
            style: AppTheme.textMediumBlack.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: AppTheme.textMediumBlack.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
