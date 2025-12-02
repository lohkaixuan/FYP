import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
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
  Merchant? _myMerchant;

  @override
  void initState() {
    super.initState();
    _fetchMyMerchantData();
  }

  // 🔍 核心逻辑：找到属于当前用户的 Merchant 档案
  Future<void> _fetchMyMerchantData() async {
    try {
      final userId = roleC.userId.value;
      // 1. 获取所有商家 (或者后端如果有 /merchants/me 接口更好)
      // 这里假设用 listMerchants 过滤 ownerUserId
      final allMerchants = await api.listMerchants();
      
      // 2. 找到 owner_user_id == 当前 userId 的那个商家
      final me = allMerchants.firstWhere(
        (m) => m.ownerUserId == userId, 
        orElse: () => throw Exception("Merchant profile not found"),
      );

      setState(() {
        _myMerchant = me;
        _loading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load merchant profile: $e');
      setState(() => _loading = false);
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
            // 跳转到修改页，并等待返回结果
            final result = await Get.to(() => UpdateMerchantPage(merchant: _myMerchant!));
            // 如果修改成功返回了 true，则刷新页面
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
             // 1. 商家图标 (用首字母模拟)
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

            // 2. 信息列表
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
                  _InfoTile(icon: Icons.location_on, label: 'Address', value: _myMerchant!.address),
                  const Divider(height: 1),
                  // 执照只读
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.grey),
                    title: const Text('Business License', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: const Text('Uploaded (Contact Admin to update)', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === 修改页面 (Internal Widget) ===
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
  late TextEditingController _addrCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.merchant.merchantName);
    _phoneCtrl = TextEditingController(text: widget.merchant.merchantPhoneNumber ?? '');
    _addrCtrl = TextEditingController(text: widget.merchant.address ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // 调用 API 更新
      await api.updateMerchant(widget.merchant.merchantId, {
        'merchantName': _nameCtrl.text.trim(),
        'merchantPhoneNumber': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
      });
      
      Get.snackbar('Success', 'Merchant info updated', backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(result: true); // 返回 true 通知上一页刷新
    } catch (e) {
      Get.snackbar('Error', 'Update failed: $e', backgroundColor: Colors.red, colorText: Colors.white);
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _addrCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Business Address', prefixIcon: Icon(Icons.location_on)),
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