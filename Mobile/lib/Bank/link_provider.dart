// ==================================================
// Program Name   : link_provider.dart
// Purpose        : Bank provider linking screen
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BankController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/Utils/api_dialogs.dart';

class LinkProviderPage extends StatefulWidget {
  const LinkProviderPage({super.key});

  @override
  State<LinkProviderPage> createState() => _LinkProviderPageState();
}

class _LinkProviderPageState extends State<LinkProviderPage> {
  final api = Get.find<ApiService>();
  final bankC = Get.find<BankController>();

  final _formKey = GlobalKey<FormState>();
  final _bankTypeCtrl = TextEditingController(text: 'MOCKBANK');
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  bool _loadingProviders = true;
  bool _submitting = false;
  bool _refreshingAccounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _bankTypeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _loadProviders();
    await bankC.getBankAccounts();
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() => _loadingProviders = true);
    try {
      final list = await api.listThirdParties();
      final enabled = list.where((p) => p.enabled).toList();
      if (!mounted) return;
      setState(() {
        _providers = enabled;
        _selectedProvider ??= _providers.isNotEmpty ? _providers.first : null;
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ApiDialogs.showError(
          ApiDialogs.formatErrorMessage(e),
          fallbackTitle: 'Load providers failed',
        );
      });
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  Future<void> _linkProvider() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) {
      ApiDialogs.showError('Select a provider', fallbackTitle: 'Validation');
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await api.linkProvider(
        provider: _selectedProvider!.name,
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
          _submitting = false;
          _refreshingAccounts = false;
        });
      }
    }
  }

  void _openLinkDetail(BankAccount b) {
    final linkId = b.bankLinkId;
    if (linkId == null || linkId.isEmpty) {
      ApiDialogs.showError(
        'This account is not linked yet. Link first, then tap again.',
        fallbackTitle: 'Not linked',
      );
      return;
    }

    Get.to(() => BankLinkDetailPage(
          linkId: linkId,
          account: b,
          onRefresh: bankC.getBankAccounts,
        ));
  }

  Widget _buildAccountCard(BankAccount b) {
    final linkId = b.bankLinkId;
    final isLinked = linkId != null && linkId.isNotEmpty;

    return Card(
      child: ListTile(
        onTap: () {
          if (!isLinked) {
            ApiDialogs.showError(
              'This account is not linked yet. Link first, then tap again.',
              fallbackTitle: 'Not linked',
            );
            return;
          }
          _openLinkDetail(b);
        },
        title: Text(
          b.bankName ?? 'Bank Account',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account: ${b.bankAccountNumber ?? '-'}'),
            if (b.bankLinkExternalRef != null)
              Text('External Ref: ${b.bankLinkExternalRef}'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text('Balance: ${b.userBalance ?? 0}')),
                Chip(label: Text('Provider: ${b.bankLinkProviderId ?? '-'}')),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(isLinked ? 'Linked' : 'Not linked'),
          backgroundColor:
              isLinked ? Colors.green.shade100 : Colors.orange.shade100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: 'Bank Provider Link',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_refreshingAccounts)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<ProviderModel>(
                    value: _selectedProvider,
                    items: _providers
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged:
                        _loadingProviders ? null : (val) => setState(() => _selectedProvider = val),
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (_) => _selectedProvider == null ? 'Select provider' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankTypeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Type',
                      hintText: 'e.g. MOCKBANK',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _linkProvider,
                      icon: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_submitting ? 'Linking...' : 'Link Provider'),
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
                  Text('Your bank accounts',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...accounts.map(_buildAccountCard),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class BankLinkDetailPage extends StatefulWidget {
  final String linkId;
  final BankAccount account; 
  final Future<void> Function()? onRefresh;

  const BankLinkDetailPage({
    super.key,
    required this.linkId,
    required this.account,
    this.onRefresh,
  });

  @override
  State<BankLinkDetailPage> createState() => _BankLinkDetailPageState();
}

class _BankLinkDetailPageState extends State<BankLinkDetailPage> {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();
  final walletC = Get.find<WalletController>();

  bool _loading = false;
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await api.providerBalanceByLink(widget.linkId);
      if (!mounted) return;
      setState(() => _balance = res);
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Balance failed',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
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
                      Text('Reload from linked bank',
                          style: Theme.of(ctx).textTheme.titleMedium),
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
        linkId: widget.linkId,
        amount: amount,
        note: null,
      );

      final ref = (res['providerRef'] ??
              res['ref'] ??
              res['transferId'] ??
              res['transactionId'])
          ?.toString();

      final externalSourceId = (ref != null && ref.isNotEmpty)
          ? 'BANKLINK:${widget.linkId}:$ref'
          : 'BANKLINK:${widget.linkId}:${DateTime.now().millisecondsSinceEpoch}';

      await _creditWallet(amount, externalSourceId);

      await _fetchBalance();
      if (widget.onRefresh != null) await widget.onRefresh!();

      ApiDialogs.showSuccess('Reload success', 'Wallet credited successfully!');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/home');
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Reload failed',
      );
    }
  }

  Future<void> _creditWallet(double amount, String externalSourceId) async {
    final roleC = Get.find<RoleController>();
    final walletId = roleC.activeWalletId.value.isNotEmpty
        ? roleC.activeWalletId.value
        : auth.user.value?.userWalletId ?? auth.user.value?.walletId;

    final providerId = widget.account.bankLinkProviderId;

    if (walletId == null || walletId.isEmpty) {
      ApiDialogs.showError('No walletId found', fallbackTitle: 'Wallet');
      return;
    }
    if (providerId == null || providerId.isEmpty) {
      ApiDialogs.showError(
        'No providerId found (check BankAccount.fromJson mapping / backend response)',
        fallbackTitle: 'Wallet',
      );
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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlobalScaffold(
      title: widget.account.bankName ?? 'Linked Bank',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(widget.account.bankName ?? 'Bank link'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Link ID: ${widget.linkId}'),
                        if (widget.account.bankLinkExternalRef != null)
                          Text('External Ref: ${widget.account.bankLinkExternalRef}'),
                        const SizedBox(height: 6),
                        Text('Provider ID: ${widget.account.bankLinkProviderId ?? "-"}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Balance',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loading ? null : _fetchBalance,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_loading)
                          const CircularProgressIndicator()
                        else if (_balance != null)
                          Text(
                            const JsonEncoder.withIndent('  ').convert(_balance),
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13),
                          )
                        else
                          const Text('No balance fetched yet.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _reload,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Reload'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
