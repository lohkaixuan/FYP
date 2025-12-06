import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/SecurityCode.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Transfer/transfer.dart';

class ReloadScreen extends StatefulWidget {
  const ReloadScreen({super.key});

  @override
  State<ReloadScreen> createState() => _ReloadScreenState();
}

class _ReloadScreenState extends State<ReloadScreen> {
  final api = Get.find<ApiService>();
  final roleController = Get.find<RoleController>();

  final _amountCtrl = TextEditingController(text: "20.00");

  CardFieldInputDetails? _cardDetails;
  bool _loadingProviders = true;
  bool _isProcessing = false;
  bool _stripeReady = false;
  String? _publishableKey;
  List<ProviderModel> _providers = <ProviderModel>[];
  ProviderModel? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
    });
    try {
      final all = await api.listThirdParties();
      final enabled = all.where((p) => p.enabled).toList();
      setState(() {
        _providers = enabled;
        if (_providers.isNotEmpty) {
          _selectedProvider = _providers.first;
          _applyProviderDefaults(_selectedProvider);
        }
      });
    } catch (ex) {
      Get.snackbar(
        'Providers',
        'Unable to load providers: $ex',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _loadingProviders = false;
      });
    }
  }

  void _applyProviderDefaults(ProviderModel? p) {
    if (p == null) return;
    _fetchProviderKey(p.providerId);
  }

  Future<void> _fetchProviderKey(String providerId) async {
    setState(() {
      _stripeReady = false;
      _publishableKey = null;
    });
    try {
      final detail = await api.getThirdParty(providerId);
      final key = detail.publicKey ?? detail.baseUrl;
      if (key == null || key.isEmpty) {
        throw 'Provider did not return a publishable key';
      }
      await _initStripeKey(key);
    } catch (e) {
      Get.snackbar(
        'Provider',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _initStripeKey(String key) async {
    try {
      Stripe.publishableKey = key;
      await Stripe.instance.applySettings();
      setState(() {
        _publishableKey = key;
        _stripeReady = true;
      });
    } catch (e) {
      setState(() {
        _stripeReady = false;
        _publishableKey = null;
      });
      Get.snackbar(
        'Stripe',
        'Failed to init Stripe: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String? _validate() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }

    final providerId = _selectedProvider?.providerId ?? '';
    if (providerId.isEmpty) {
      return 'Choose or enter a provider (Stripe)';
    }

    if (!_stripeReady || (_publishableKey ?? '').isEmpty) {
      return 'Stripe publishable key unavailable for this provider';
    }

    if (_cardDetails == null || !_cardDetails!.complete) {
      return 'Card details are incomplete';
    }

    if (roleController.walletId.isEmpty) {
      return 'No wallet available for reload';
    }

    return null;
  }

  Future<void> _startStripeTopUp() async {
    final error = _validate();
    if (error != null) {
      Get.snackbar(
        'Missing info',
        error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final amount = double.parse(_amountCtrl.text.trim());
    final providerId = _selectedProvider?.providerId ?? '';
    final walletId = roleController.walletId;
    final publishableKey = _publishableKey ?? '';

    setState(() {
      _isProcessing = true;
    });

    try {
      // publishable key already applied in _initStripeKey
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      Get.to(
        () => SecurityCodeScreen(
          data: TransferDetails(
            type: "topup",
            fromAccountId: providerId,
            toAccountId: walletId,
            amount: amount,
            providerId: providerId,
            externalSourceId: paymentMethod.id,
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Stripe error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlobalScaffold(
      title: 'Reload via Stripe',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(colorScheme: cs),
            const SizedBox(height: 16),
            Text(
              'Provider',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: 8),
            if (_loadingProviders)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_providers.isNotEmpty)
                DropdownButtonFormField<ProviderModel>(
                  value: _selectedProvider,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payment),
                    labelText: 'Select Stripe provider',
                  ),
              items: _providers
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.isEmpty ? p.providerId : p.name),
                    ),
                  )
                  .toList(),
                  onChanged: (p) {
                    setState(() {
                      _selectedProvider = p;
                      _applyProviderDefaults(p);
                    });
                  },
                ),
            ],
            const SizedBox(height: 20),
            Text(
              'Amount',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                labelText: 'Amount to reload',
              ),
              ),
            const SizedBox(height: 20),
            Text(
              'Card details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: 8),
            if (_stripeReady)
              CardFormField(
                style: CardFormStyle(
                  borderColor: cs.outlineVariant,
                  textColor: cs.onSurface,
                  borderRadius: 12,
                ),
                onCardChanged: (details) =>
                    setState(() => _cardDetails = details),
              )
            else
              Text(
                'Stripe key not loaded for this provider.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.flash_on),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _isProcessing ? 'Processing...' : 'Pay with Stripe',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                onPressed: _isProcessing ? null : _startStripeTopUp,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your wallet ID: ${roleController.walletId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _HeaderCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.8),
            colorScheme.primary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: colorScheme.onPrimary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Stripe Reload',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: colorScheme.onPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use card payments through Stripe to reload your wallet instantly.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}
