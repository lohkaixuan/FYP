import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BankController.dart';
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

  void _applyLinkResponse(Map<String, dynamic> res) {
    final linkId = res['linkId']?.toString();
    final bankAccountId = res['bankAccountId']?.toString();
    if (linkId == null || linkId.isEmpty || bankAccountId == null || bankAccountId.isEmpty) {
      return;
    }

    final idx = bankC.accounts.indexWhere((b) => b.bankAccountId?.toString() == bankAccountId);
    if (idx >= 0) {
      final existing = bankC.accounts[idx];
      bankC.accounts[idx] = existing.copyWith(bankLinkId: linkId);
    }
  }

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
      _applyLinkResponse(res);
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transfer from linked bank',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Send'),
                  ),
                ],
              ),
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
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Transfer failed',
      );
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
          bankName: b.bankName,
          externalRef: b.bankLinkExternalRef,
          onRefresh: bankC.getBankAccounts,
        ));
  }

  Widget _buildAccountCard(BankAccount b) {
    final linkId = b.bankLinkId;
    final isLinked = linkId != null && linkId.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(b.bankName ?? 'Bank Account',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Chip(
                    label: Text(isLinked ? 'Linked' : 'Not linked'),
                    backgroundColor: isLinked
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Account: ${b.bankAccountNumber ?? '-'}'),
              if (b.bankLinkExternalRef != null)
                Text('External Ref: ${b.bankLinkExternalRef}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(label: Text('Balance: ${b.userBalance ?? 0}')),
                  if (b.bankLinkProviderId != null)
                    Chip(label: Text('Provider: ${b.bankLinkProviderId}')),
                ],
              ),
              if (isLinked && linkId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _checkBalance(linkId),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Check balance'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _transfer(linkId),
                      icon: const Icon(Icons.send),
                      label: const Text('Transfer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
            if (_refreshingAccounts) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
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

class BankLinkDetailPage extends StatefulWidget {
  final String linkId;
  final String? bankName;
  final String? externalRef;
  final Future<void> Function()? onRefresh;
  const BankLinkDetailPage({
    super.key,
    required this.linkId,
    this.bankName,
    this.externalRef,
    this.onRefresh,
  });

  @override
  State<BankLinkDetailPage> createState() => _BankLinkDetailPageState();
}

class _BankLinkDetailPageState extends State<BankLinkDetailPage> {
  final api = Get.find<ApiService>();
  bool _loading = false;
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
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
              Text('Transfer from linked bank',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Send'),
                  ),
                ],
              ),
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
      if (widget.onRefresh != null) widget.onRefresh!();
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Transfer failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlobalScaffold(
      title: widget.bankName ?? 'Linked Bank',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                      Text(const JsonEncoder.withIndent('  ')
                          .convert(_balance))
                    else
                      const Text('No balance fetched yet.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _transfer,
                icon: const Icon(Icons.send),
                label: const Text('Transfer'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
