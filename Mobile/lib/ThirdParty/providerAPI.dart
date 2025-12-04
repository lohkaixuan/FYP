import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/RoleController.dart';

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();
  final auth = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final _publicKeyCtrl = TextEditingController();
  final _privateKeyCtrl = TextEditingController();

  bool _isPrivateVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  // 模拟从后端加载现有的 Key
  // 实际项目中，这里应该从 api.getThirdParty(id) 获取真实数据
  void _loadKeys() {
    // 假设 User 对象里暂时没有这两个字段，我们先留空，或者给个 Mock 值方便你演示
    // _publicKeyCtrl.text = "pk_test_123456..."; 
    // _privateKeyCtrl.text = "sk_test_abcdef...";
  }

  @override
  void dispose() {
    _publicKeyCtrl.dispose();
    _privateKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final providerId = roleC.userId.value; // 或者用 merchantId/providerId

      // 调用后端更新接口 (假设后端支持接收 credentials 字段)
      // 如果后端还没适配，这步可以先注释掉，只做 UI 演示
      /*
      await api.updateThirdParty(providerId, {
        'public_key': _publicKeyCtrl.text.trim(),
        'private_key': _privateKeyCtrl.text.trim(),
      });
      */
      
      // 模拟网络请求延迟
      await Future.delayed(const Duration(seconds: 1));

      Get.snackbar(
        'Success', 
        'API Keys updated successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to save keys: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 辅助功能：生成随机 Key (方便用户填入)
  void _generateRandomKeys() {
    final time = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _publicKeyCtrl.text = 'pk_live_${time}_pub';
      _privateKeyCtrl.text = 'sk_live_${time}_priv_${(time/2).floor()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlobalScaffold(
      title: 'API Configuration',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部说明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Configure your Public and Private keys to authenticate API requests.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Public Key Input
              const Text('Public API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _publicKeyCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. pk_live_...',
                  prefixIcon: const Icon(Icons.public),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                  children:[
                    IconButton(
                        icon: Icon(_isPrivateVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPrivateVisible = !_isPrivateVisible),
                      ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(_publicKeyCtrl.text),
                  ),
                  ])
                ),
                validator: (v) => v == null || v.isEmpty ? 'Public key is required' : null,
              ),
              
              const SizedBox(height: 24),

              // 2. Private Key Input (Secret)
              const Text('Private API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _privateKeyCtrl,
                obscureText: !_isPrivateVisible, // 隐藏/显示逻辑
                decoration: InputDecoration(
                  hintText: 'e.g. sk_live_...',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPrivateVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPrivateVisible = !_isPrivateVisible),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_privateKeyCtrl.text),
                      ),
                    ],
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Private key is required' : null,
              ),

              /*const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _generateRandomKeys,
                  icon: const Icon(Icons.autorenew, size: 16),
                  label: const Text('Generate Random Keys'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),*/

              const SizedBox(height: 40),

              // 3. Save Button
              SizedBox(
                width: double.infinity,
                child: BrandGradientButton(
                  onPressed: _isSaving ? null : _saveKeys,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Credentials'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', 'Key copied to clipboard', duration: const Duration(seconds: 1), snackPosition: SnackPosition.BOTTOM);
  }
}