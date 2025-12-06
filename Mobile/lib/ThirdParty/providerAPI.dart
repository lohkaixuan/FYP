import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
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
  // 增加一个 Url Controller (因为 Swagger 里有 api_url)
  final _urlCtrl = TextEditingController();

  bool _isPrivateVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  // 1. 加载数据
  void _loadKeys() async {
    try {
      final userId = roleC.userId.value;
      
      // ✅ 方案变更：直接获取用户详情，里面包含了 provider_id
      // (前提：你必须先完成了第一步，给 AppUser 加上了 providerId)
      final userDetails = await api.getUser(userId);
      
      final myProviderId = userDetails.providerId;

      if (myProviderId != null && myProviderId.isNotEmpty) {
        print('✅ Found Provider ID: $myProviderId');
        
        // 如果后端有接口返回 api_url，可以在这里填入
        if (userDetails.providerBaseUrl != null) {
           _urlCtrl.text = userDetails.providerBaseUrl!;
        }
        
        // 注意：Key 通常是只会返回 Public Key，Private Key 为了安全后端一般不返回
        // 所以 _privateKeyCtrl 保持为空是正常的
      } else {
        print('⚠️ No Provider ID found for this user.');
      }
    } catch (e) {
      print('Error loading provider keys: $e');
    }
  }

  // 2. 保存数据
  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = roleC.userId.value;
      
      // 同样，先获取 ID
      final userDetails = await api.getUser(userId);
      final myProviderId = userDetails.providerId;

      if (myProviderId == null || myProviderId.isEmpty) {
        throw "Provider ID not found for this user.";
      }

      // ✅ 调用 updateProviderSecrets
      await api.updateProviderSecrets(
        myProviderId,
        apiUrl: _urlCtrl.text.trim(),
        publicKey: _publicKeyCtrl.text.trim(),
        privateKey: _privateKeyCtrl.text.trim(),
      );

      Get.snackbar('Success', 'API Configuration updated.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
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

              const Text('Callback URL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlCtrl, // 👈 确保用了这个控制器
                decoration: const InputDecoration(
                  hintText: 'https://your-server.com/api/callback',
                  prefixIcon: Icon(Icons.link),
                ),
                // 👇 加上验证：如果不填，不让提交
                validator: (v) =>
                    v == null || v.isEmpty ? 'API URL is required' : null,
              ),
              const SizedBox(height: 24),

              // 1. Public Key Input
              const Text('Public API Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _publicKeyCtrl,
                decoration: InputDecoration(
                    hintText: 'e.g. pk_live_...',
                    prefixIcon: const Icon(Icons.public),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(_isPrivateVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _isPrivateVisible = !_isPrivateVisible),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_publicKeyCtrl.text),
                      ),
                    ])),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Public key is required' : null,
              ),
              const SizedBox(height: 24),

              // 2. Private Key Input (Secret)
              const Text('Private API Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        icon: Icon(_isPrivateVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _isPrivateVisible = !_isPrivateVisible),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_privateKeyCtrl.text),
                      ),
                    ],
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Private key is required' : null,
              ),
              const SizedBox(height: 12),
              /*Align(
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
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
    Get.snackbar('Copied', 'Key copied to clipboard',
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM);
  }
}
