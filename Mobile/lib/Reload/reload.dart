// ==================================================
// Program Name   : reload.dart
// Purpose        : Reload funds screen
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Bank/link_provider.dart';
import 'package:mobile/Controller/BankController.dart';
import 'package:mobile/Controller/ReloadController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Utils/api_dialogs.dart';

class ReloadScreen extends StatefulWidget {
  const ReloadScreen({super.key});

  @override
  State<ReloadScreen> createState() => _ReloadScreenState();
}

class _ReloadScreenState extends State<ReloadScreen> {
  final reloadC = Get.put(ReloadController());
  final bankC = Get.isRegistered<BankController>()
      ? Get.find<BankController>()
      : Get.put(BankController());
  final api = Get.find<ApiService>();
  final walletC = Get.find<WalletController>();
  final auth = Get.find<AuthController>();
  final roleC = Get.find<RoleController>();

  final _mockFormKey = GlobalKey<FormState>();
  final _bankTypeCtrl = TextEditingController(text: 'MOCKBANK');
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _linking = false;
  bool _refreshingAccounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bankC.getBankAccounts();
    });
  }

  @override
  void dispose() {
    _bankTypeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _isStripeProvider(ProviderModel? p) {
    final name = (p?.name ?? '').toLowerCase();
    final id = (p?.providerId ?? '').toLowerCase();
    return name.contains('stripe') || id.contains('stripe');
  }

  bool _isMockbankProvider(ProviderModel? p) {
    final name = (p?.name ?? '').toLowerCase();
    final id = (p?.providerId ?? '').toLowerCase();
    return name.contains('mock') || id.contains('mock');
  }

  void _onProviderChanged(ProviderModel? provider) {
    if (provider == null) return;
    reloadC.selectedProvider.value = provider;

    if (_isStripeProvider(provider)) {
      reloadC.fetchProviderKey(provider.providerId);
    } else {
      reloadC.stripeReady.value = false;
    }

    if (_isMockbankProvider(provider)) {
      bankC.getBankAccounts();
    }
  }

  Future<void> _linkProvider() async {
    if (!_mockFormKey.currentState!.validate()) return;

    final provider = reloadC.selectedProvider.value;
    if (provider == null) {
      ApiDialogs.showError(
        'Select a provider first',
        fallbackTitle: 'Validation',
      );
      return;
    }

    setState(() => _linking = true);
    try {
      final res = await api.linkProvider(
        provider: provider.name,
        bankType: _bankTypeCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      ApiDialogs.showSuccess(
        'Linked',
        res['message']?.toString() ?? 'Linked / Updated',
      );

      setState(() => _refreshingAccounts = true);
      await bankC.getBankAccounts();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Link failed',
      );
    } finally {
      if (mounted) {
        setState(() {
          _linking = false;
          _refreshingAccounts = false;
        });
      }
    }
  }

  String? _activeWalletId() {
    final activeId = roleC.activeWalletId.value;
    if (activeId.isNotEmpty) return activeId;
    return auth.user.value?.userWalletId ?? auth.user.value?.walletId;
  }

  void _openLinkDetail(BankAccount account) {
    final linkId = account.bankLinkId;
    if (linkId == null || linkId.isEmpty) {
      ApiDialogs.showError(
        'This account is not linked yet. Link first, then tap again.',
        fallbackTitle: 'Not linked',
      );
      return;
    }

    Get.to(() => BankLinkDetailPage(
          linkId: linkId,
          account: account,
          onRefresh: bankC.getBankAccounts,
        ));
  }

  Future<void> _reloadFromLinkedBank(BankAccount account) async {
    final linkId = account.bankLinkId;
    final providerId = account.bankLinkProviderId;
    if (linkId == null || linkId.isEmpty) {
      ApiDialogs.showError(
        'This account is not linked yet.',
        fallbackTitle: 'Not linked',
      );
      return;
    }
    if (providerId == null || providerId.isEmpty) {
      ApiDialogs.showError(
        'Missing provider ID for this linked account.',
        fallbackTitle: 'Provider',
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reload from linked bank',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount to reload',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Reload'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (ok != true) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ApiDialogs.showError('Enter a valid amount', fallbackTitle: 'Validation');
      return;
    }

    try {
      final res = await api.providerTransferByLink(
        linkId: linkId,
        amount: amount,
        note: null,
      );

      final ref = (res['providerRef'] ??
              res['ref'] ??
              res['transferId'] ??
              res['transactionId'])
          ?.toString();

      final externalSourceId = (ref != null && ref.isNotEmpty)
          ? 'BANKLINK:$linkId:$ref'
          : 'BANKLINK:$linkId:${DateTime.now().millisecondsSinceEpoch}';

      final walletId = _activeWalletId();
      if (walletId == null || walletId.isEmpty) {
        ApiDialogs.showError('No walletId found', fallbackTitle: 'Wallet');
        return;
      }

      await walletC.reloadWallet(
        walletId: walletId,
        amount: amount,
        providerId: providerId,
        externalSourceId: externalSourceId,
      );

      await walletC.get(walletId);
      await auth.refreshMe();
      await bankC.getBankAccounts();

      ApiDialogs.showSuccess('Reload success', 'Wallet credited successfully!');
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Reload failed',
      );
    }
  }

  Widget _buildStripeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Amount"),
        const SizedBox(height: 6),
        TextField(
          controller: reloadC.amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.attach_money),
            labelText: "Enter amount",
          ),
        ),
        const SizedBox(height: 20),
        Text("Card Details"),
        const SizedBox(height: 6),
        reloadC.stripeReady.value
            ? stripe.CardField(
                enablePostalCode: false,
                onCardChanged: (details) => reloadC.card.value = details,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              )
            : const Text("Stripe not ready (missing publishable key)"),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: reloadC.processing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.flash_on),
            label: Text(
              reloadC.processing.value ? "Processing..." : "Continue reload",
            ),
            onPressed: reloadC.processing.value ? null : reloadC.startReload,
          ),
        ),
      ],
    );
  }

  Widget _buildMockbankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_refreshingAccounts) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
        Form(
          key: _mockFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bankTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Type',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _linking ? null : _linkProvider,
                  icon: _linking
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_linking ? 'Linking...' : 'Link Provider'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (bankC.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = bankC.accounts;
          if (accounts.isEmpty) {
            return const Text('No bank accounts found.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linked accounts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...accounts.map(_buildBankCard),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBankCard(BankAccount account) {
    final linkId = account.bankLinkId;
    final isLinked = linkId != null && linkId.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.bankName ?? 'Bank Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Account: ${account.bankAccountNumber ?? '-'}'),
            if (account.bankLinkExternalRef != null)
              Text('External Ref: ${account.bankLinkExternalRef}'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text('Balance: ${account.userBalance ?? 0}')),
                Chip(label: Text('Provider: ${account.bankLinkProviderId ?? '-'}')),
                Chip(label: Text(isLinked ? 'Linked' : 'Not linked')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLinked ? () => _openLinkDetail(account) : null,
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        isLinked ? () => _reloadFromLinkedBank(account) : null,
                    child: const Text('Reload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Reload")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final provider = reloadC.selectedProvider.value;
          final isStripe = _isStripeProvider(provider);
          final isMockbank = _isMockbankProvider(provider);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    Expanded(
                      child: Text(
                        provider == null
                            ? "Select a provider to reload"
                            : provider.name,
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text("Provider"),
              const SizedBox(height: 6),
              reloadC.loadingProviders.value
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<ProviderModel>(
                      value: provider,
                      items: reloadC.providers
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (p) => _onProviderChanged(p),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.payment),
                        labelText: "Choose provider",
                      ),
                    ),
              const SizedBox(height: 20),
              if (isStripe)
                _buildStripeSection()
              else if (isMockbank)
                _buildMockbankSection()
              else
                const Text(
                    "Choose Stripe for card reloads or MockBank to link and reload."),
            ],
          );
        }),
      ),
    );
  }
}
