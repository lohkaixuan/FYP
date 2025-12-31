import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/api_dialogs.dart';

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});
  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();
  final auth = Get.find<AuthController>();

  
  // final _formKey = GlobalKey<FormState>(); 

  final _publicKeyCtrl = TextEditingController();
  final _privateKeyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  bool _isPrivateVisible = false;
  bool _isPublicVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  
  void _loadKeys() async {
    try {
      final userId = roleC.userId.value;
      final userDetails = await api.getUser(userId);
      final myProviderId = userDetails.providerId;

      if (myProviderId != null && myProviderId.isNotEmpty) {
        
        if (userDetails.providerBaseUrl != null) {
           _urlCtrl.text = userDetails.providerBaseUrl!;
        }
      }
    } catch (e) {
      print('Error loading provider keys: $e');
    }
  }

  
  Future<void> _saveKeys() async {
    
    final url = _urlCtrl.text.trim();
    final pubKey = _publicKeyCtrl.text.trim();
    final privKey = _privateKeyCtrl.text.trim();

    
    if (url.isEmpty && pubKey.isEmpty && privKey.isEmpty) {
      ApiDialogs.showError(
        'Please fill in at least one field (URL or Keys).',
        fallbackTitle: 'Required',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = roleC.userId.value;
      final userDetails = await api.getUser(userId);
      final myProviderId = userDetails.providerId;

      if (myProviderId == null || myProviderId.isEmpty) {
        throw "Provider ID not found for this user.";
      }

      
      await api.updateProviderSecrets(
        myProviderId,
        apiUrl: url,
        publicKey: pubKey,
        privateKey: privKey,
      );

      ApiDialogs.showSuccess(
        'Success',
        'API Configuration updated.',
      );
    } catch (e) {
      
      if (e is DioException && e.response?.statusCode == 400) {
         final msg = e.response?.data?.toString() ?? 'Backend requires all fields?';
         ApiDialogs.showError(
           msg,
           fallbackTitle: 'Save Failed',
         );
      } else {
         ApiDialogs.showError(
           ApiDialogs.formatErrorMessage(e),
           fallbackTitle: 'Error',
           fallbackMessage: 'Failed to save configuration.',
         );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ApiDialogs.showSuccess(
      'Copied',
      'Copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    
    return GlobalScaffold(
      title: 'API Configuration',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
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
                        'Flexible Config: You can set a Callback URL, or API Keys, or both.',
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
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  hintText: 'https://your-server.com/api/callback',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),

              // 1. Public Key Input
              const Text('Public API Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _publicKeyCtrl,
                obscureText: !_isPublicVisible,
                decoration: InputDecoration(
                    hintText: 'e.g. pk_live_...',
                    prefixIcon: const Icon(Icons.public),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(_isPublicVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _isPublicVisible = !_isPublicVisible),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_publicKeyCtrl.text),
                      ),
                    ])),
              ),
              const SizedBox(height: 24),

              // 2. Private Key Input (Secret)
              const Text('Private API Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _privateKeyCtrl,
                obscureText: !_isPrivateVisible, 
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
              ),
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
    );
  }
}
