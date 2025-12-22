import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BankController.dart';
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
  final auth = Get.find<AuthController>();
  final walletC = Get.find<WalletController>();

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
    _load();
  }

  @override
  void dispose() {
    _bankTypeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_loadProviders(), bankC.getBankAccounts()]);
  }

  Future<void> _loadProviders() async {
    setState(() => _loadingProviders = true);
    try {
      final list = await api.listThirdParties();
      setState(() {
        _providers = list.where((p) => p.enabled).toList();
        if (_providers.isNotEmpty && _selectedProvider == null) {
          _selectedProvider = _providers.first;
        }
      });
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Load providers failed',
      );
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

  Future<void> _checkBalance(String linkId) async {
    try {
      final res = await api.providerBalanceByLink(linkId);
      ApiDialogs.showSuccess(
        'Balance',
        const JsonEncoder.withIndent('  ').convert(res),
      );
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Balance failed',
      );
    }
  }

  Future<void> _transfer(String linkId) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reload from linked bank',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Amount to reload'),
              ),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(96, 44),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Reload'),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
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
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      ApiDialogs.showSuccess(
        'Transfer sent',
        const JsonEncoder.withIndent('  ').convert(res),
      );
      await auth.refreshMe(); // Refresh wallet balances after reload
      await _creditWalletFromLink(linkId, amount);
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Transfer failed',
      );
    }
  }

  void _openLinkDetail(BankAccount b) {
    final linkId = b.bankLinkId;
    if (linkId == null) return;
    Get.to(() => BankLinkDetailPage(
          linkId: linkId,
          bankName: b.bankName,
          externalRef: b.bankLinkExternalRef,
          providerId: b.bankLinkProviderId,
          onRefresh: bankC.getBankAccounts,
        ));
  }

  Future<void> _creditWalletFromLink(String linkId, double amount) async {
    final walletId =
        auth.user.value?.userWalletId ?? auth.user.value?.walletId;
    if (walletId == null || walletId.isEmpty) return;

    final acct = bankC.accounts
        .firstWhereOrNull((b) => b.bankLinkId == linkId);
    final providerId = acct?.bankLinkProviderId;
    if (providerId == null || providerId.isEmpty) return;

    try {
      // Treat provider transfer as a reload into the active wallet
      await walletC.reloadWallet(
        walletId: walletId,
        amount: amount,
        providerId: providerId,
        externalSourceId: linkId,
      );
      await auth.refreshMe();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Wallet reload failed',
        fallbackMessage:
            'Bank debited but wallet was not credited. Please refresh.',
      );
    }
  }

  Widget _buildAccountCard(BankAccount b) {
    final linkId = b.bankLinkId;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: () {
          if (linkId == null) {
            ApiDialogs.showError(
              'This account is not linked yet. Link first, then tap again.',
              fallbackTitle: 'Not linked',
            );
            return;
          }
          _openLinkDetail(b);
        },
        title: Text(b.bankName ?? 'Bank Account',
            style: Theme.of(context).textTheme.titleMedium),
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
                if (b.bankLinkProviderId != null)
                  Chip(label: Text('Provider: ${b.bankLinkProviderId}')),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(linkId == null ? 'Not linked' : 'Linked'),
          backgroundColor:
              linkId == null ? Colors.orange.shade100 : Colors.green.shade100,
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
                    onChanged: _loadingProviders
                        ? null
                        : (val) => setState(() => _selectedProvider = val),
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (_) =>
                        _selectedProvider == null ? 'Select provider' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankTypeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Type',
                      hintText: 'e.g. MOCKBANK',
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
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _linkProvider,
                      icon: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link),
                      label:
                          Text(_submitting ? 'Linking...' : 'Link Provider'),
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
// Detail page for a single linked bank account (inlined for now)
class BankLinkDetailPage extends StatefulWidget {
  final String linkId;
  final String? bankName;
  final String? externalRef;
  final String? providerId;
  final Future<void> Function()? onRefresh;

  const BankLinkDetailPage({
    super.key,
    required this.linkId,
    this.bankName,
    this.externalRef,
    this.providerId,
    this.onRefresh,
  });

  @override
  State<BankLinkDetailPage> createState() => _BankLinkDetailPageState();
}

class _BankLinkDetailPageState extends State<BankLinkDetailPage> {
  final api = Get.find<ApiService>();
  final bankC = Get.find<BankController>();
  final auth = Get.find<AuthController>();
  final walletC = Get.find<WalletController>();
  BankAccount? _account;
  bool _loading = false;
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _account = bankC.accounts
        .firstWhereOrNull((b) => b.bankLinkId == widget.linkId);
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _loading = true);
    try {
      final res = await api.providerBalanceByLink(widget.linkId);
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

  Future<void> _transfer() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reload from linked bank',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Amount to reload'),
              ),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(96, 44),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Reload'),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
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
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      ApiDialogs.showSuccess(
        'Transfer sent',
        const JsonEncoder.withIndent('  ').convert(res),
      );
      await _fetchBalance();
      await _creditWallet(amount);
      await auth.refreshMe(); // Refresh wallet balances after reload
      if (widget.onRefresh != null) widget.onRefresh!();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Transfer failed',
      );
    }
  }

  Future<void> _creditWallet(double amount) async {
    final walletId =
        auth.user.value?.userWalletId ?? auth.user.value?.walletId;
    final providerId = widget.providerId ?? _account?.bankLinkProviderId;
    if (walletId == null || walletId.isEmpty) return;
    if (providerId == null || providerId.isEmpty) return;
    try {
      await walletC.reloadWallet(
        walletId: walletId,
        amount: amount,
        providerId: providerId,
        externalSourceId: widget.linkId,
      );
      await auth.refreshMe();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Wallet update failed',
        fallbackMessage: 'Reloaded bank, but failed to credit wallet.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlobalScaffold(
      title: widget.bankName ?? 'Linked Bank',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(widget.bankName ?? 'Bank link'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Link ID: ${widget.linkId}'),
                        if (widget.externalRef != null)
                          Text('External Ref: ${widget.externalRef}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Balance',
                                style:
                                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          )
                        else
                          const Text('No balance fetched yet.'),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Builder(builder: (ctx) {
              final halfWidth = MediaQuery.of(ctx).size.width * 0.5;
              final btnWidth = halfWidth.clamp(0.0, 360.0);
              return Center(
                child: SizedBox(
                  width: btnWidth,
                  height: 48,
                  child: FilledButton(
                    onPressed: _transfer,
                    child: const Text('Reload'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: Size(btnWidth, 48),
                    ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
