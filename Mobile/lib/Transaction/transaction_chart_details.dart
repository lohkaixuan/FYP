import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Transaction/Transactionpage.dart';

class ChartDetails extends StatelessWidget {
  final String appBarTitle;
  const ChartDetails({super.key, required String title}): appBarTitle = title;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>>? data =
        Get.arguments as List<Map<String, dynamic>>?;

    return Scaffold(
      appBar: GlobalAppBar(
        title: appBarTitle,
      ),
      body: ListView.builder(
        itemCount: data!.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final title = item['title'];
          final amount = item['amount'] as double? ?? 0.0;
          final color = item['color'];

          return Padding(
            padding: const EdgeInsets.all(5),
            child: DetailsCard(
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

class DetailsCard extends StatelessWidget {
  final Color leading;
  final String title;
  final String trailing;

  const DetailsCard(
      {super.key,
      required this.leading,
      required this.title,
      required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => const Transactions(),
            arguments: {"filter": title.toLowerCase()}),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Icons.square, color: leading),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.textMediumBlack.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
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
        ),
      ),
    );
  }
}
