import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mobile/Controller/RoleController.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();
  final roleC = Get.find<RoleController>();

  bool _loading = true;
  bool _docLoading = false;
  Merchant? _myMerchant;

  @override
  void initState() {
    super.initState();
    _fetchMyMerchantData();
  }

  // Use /users/me to locate the current user's merchant record
  Future<void> _fetchMyMerchantData() async {
    try {
      final me = await api.me();
      Merchant merchant;

      if ((me.merchantId ?? '').isNotEmpty) {
        // Build merchant object directly from /me payload to avoid extra fetch
        merchant = Merchant.fromJson({
          'merchant_id': me.merchantId,
          'merchant_name': me.merchantName ?? '',
          'merchant_phone_number': me.merchantPhoneNumber,
          'merchant_doc': me.merchantDocUrl,
          'merchant_doc_url': me.merchantDocUrl,
          'owner_user_id': me.userId,
          'status': me.isDeleted == true ? 'Inactive' : (me.roleName ?? 'Active'),
        });
      } else {
        // Fallback: locate merchant by owner id if /me lacks merchantId
        final allMerchants = await api.listMerchants();
        merchant = allMerchants.firstWhere(
          (m) => m.ownerUserId == me.userId,
          orElse: () => throw Exception("Merchant profile not found"),
        );
      }

      setState(() {
        _myMerchant = merchant;
        _loading = false;
      });
    } catch (e) {
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Error',
        fallbackMessage: 'Failed to load merchant profile.',
      );
      setState(() => _loading = false);
    }
  }

  bool _isPdf(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  Future<void> _viewDocument() async {
    if (_myMerchant == null) return;

    setState(() => _docLoading = true);
    try {
      final res = await api.downloadMerchantDoc(_myMerchant!.merchantId);
      final data = res.data;

      if (data == null || data.isEmpty) {
        ApiDialogs.showError(
          'No document found for this merchant.',
          fallbackTitle: 'Document',
        );
        return;
      }

      final bytes = Uint8List.fromList(data);

      await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: _isPdf(bytes)
                  ? SfPdfViewer.memory(bytes)
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
          );
        },
      );
    } catch (e) {
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Error',
        fallbackMessage: 'Failed to load document.',
      );
    } finally {
      if (mounted) setState(() => _docLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const GlobalScaffold(
        title: 'Merchant Profile',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myMerchant == null) {
      return const GlobalScaffold(
        title: 'Merchant Profile',
        body: Center(child: Text('No merchant profile found.')),
      );
    }

    return GlobalScaffold(
      title: 'Merchant Profile',
      actions: [
        IconButton(
          tooltip: 'Edit Merchant Info',
          icon: const Icon(Icons.edit_rounded),
          onPressed: () async {
            // ??????,???????
            final result = await Get.to(() => UpdateMerchantPage(merchant: _myMerchant!));
            // ????????? true,?????
            if (result == true) {
              _fetchMyMerchantData();
            }
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             // 1. ???? (??????)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.store_rounded, size: 50, color: cs.onSecondaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _myMerchant!.merchantName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                (_myMerchant!.status ?? 'Active').toUpperCase(),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 32),

            // 2. ????
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  _InfoTile(icon: Icons.store, label: 'Merchant Name', value: _myMerchant!.merchantName),
                  const Divider(height: 1),
                  _InfoTile(icon: Icons.phone, label: 'Business Phone', value: _myMerchant!.merchantPhoneNumber),
                  const Divider(height: 1),
                  // ????
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.grey),
                    title: const Text('Business License', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: const Text('Uploaded (Contact Admin to update)', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _docLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.description),
                label: const Text('View Merchant Document'),
                onPressed: _docLoading ? null : _viewDocument,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === ???? (Internal Widget) ===
class UpdateMerchantPage extends StatefulWidget {
  final Merchant merchant;
  const UpdateMerchantPage({super.key, required this.merchant});

  @override
  State<UpdateMerchantPage> createState() => _UpdateMerchantPageState();
}

class _UpdateMerchantPageState extends State<UpdateMerchantPage> {
  final _formKey = GlobalKey<FormState>();
  final api = Get.find<ApiService>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.merchant.merchantName);
    _phoneCtrl = TextEditingController(text: widget.merchant.merchantPhoneNumber ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // ?? API ??
      await api.updateMerchant(widget.merchant.merchantId, {
        'merchantName': _nameCtrl.text.trim(),
        'merchantPhoneNumber': _phoneCtrl.text.trim(),
      });
      
      ApiDialogs.showSuccess(
        'Success',
        'Merchant info updated',
        onConfirm: () => Get.back(result: true),
      );
    } catch (e) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(e),
        fallbackTitle: 'Error',
        fallbackMessage: 'Update failed.',
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Edit Merchant Info'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Merchant / Shop Name', prefixIcon: Icon(Icons.store)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Business Phone', prefixIcon: Icon(Icons.phone)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: BrandGradientButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoTile({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value?.isEmpty ?? true ? '-' : value!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

