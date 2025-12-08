import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile/Controller/ReloadController.dart';

class ReloadScreen extends StatelessWidget {
  const ReloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReloadController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Reload via Stripe")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      cs.primaryContainer.withOpacity(0.8),
                      cs.primary.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: cs.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      "Stripe Reload",
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PROVIDER
              Text("Provider"),
              const SizedBox(height: 6),

              if (c.loadingProviders.value)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField(
                  value: c.selectedProvider.value,
                  items: c.providers
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (p) {
                    c.selectedProvider.value = p;
                    c.fetchProviderKey(p!.providerId);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payment),
                    labelText: "Choose Stripe Provider",
                  ),
                ),

              const SizedBox(height: 20),

              // AMOUNT
              Text("Amount"),
              const SizedBox(height: 6),

              TextField(
                controller: c.amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money),
                  labelText: "Enter amount",
                ),
              ),

              const SizedBox(height: 20),

              // CARD FORM
              Text("Card Details"),
              const SizedBox(height: 6),

              if (c.stripeReady.value)
                CardFormField(
                  onCardChanged: (details) => c.card.value = details,
                )
              else
                const Text("Stripe not ready (missing publishable key)"),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: c.processing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.flash_on),
                  label: Text(c.processing.value
                      ? "Processing..."
                      : "Reload via Stripe"),
                  onPressed: c.processing.value ? null : c.startReload,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
