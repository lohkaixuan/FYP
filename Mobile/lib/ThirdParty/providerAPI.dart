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
  final auth = Get.find<AuthController>();
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();

  // 模拟的 API Secret (实际项目中应从后端获取)
  String _mockSecret = "sk_live_51MzQ2FkZj... (Hidden)";
  bool _showSecret = false;
  bool _isRegenerating = false;

  // Base URL 编辑
  final _urlCtrl = TextEditingController();
  bool _isSavingUrl = false;

  @override
  void initState() {
    super.initState();
    // 初始化 Base URL
    final user = auth.user.value;
    _urlCtrl.text = user?.providerBaseUrl ?? 'https://api.yourdomain.com/v1/callback';
    
    // 初始化一个看起来像真的 Key
    _generateMockKey();
  }

  void _generateMockKey() {
    // 演示用：生成一个随机字符串
    final part = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    setState(() {
      _mockSecret = "sk_live_${part}x9d8s7f6g5h4j3k2l1";
    });
  }

  // 保存 Base URL 到后端
  Future<void> _saveBaseUrl() async {
    setState(() => _isSavingUrl = true);
    try {
      final uid = roleC.userId.value;
      // 调用 updateUser 接口更新 providerBaseUrl
      // 注意：这里假设后端 updateUser 支持更新 'providerBaseUrl' 字段
      // 如果后端不支持，这步会报错，但 UI 上我们先做成通的
      await api.updateUser(uid, {
        'providerBaseUrl': _urlCtrl.text.trim(),
      });
      
      // 刷新本地 User 数据
      await auth.refreshMe();
      
      Get.snackbar('Success', 'Callback URL updated successfully', 
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update URL: $e', 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSavingUrl = false);
    }
  }

  // 模拟重置密钥
  Future<void> _regenerateKey() async {
    // 弹窗确认
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Regenerate API Secret?'),
        content: const Text(
          'This will invalidate the old secret immediately.\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true), 
            child: const Text('Regenerate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRegenerating = true);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));
    
    _generateMockKey();
    setState(() => _isRegenerating = false);
    
    Get.snackbar('Success', 'New API Secret generated.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // 获取当前 Provider ID (User ID)
    final providerId = roleC.userId.value;

    return GlobalScaffold(
      title: 'API Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Credentials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these keys to authenticate your API requests.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. Client ID (Provider ID)
            _KeyCard(
              label: 'Provider ID (Client ID)',
              value: providerId,
              isSecret: false,
              onCopy: () => _copy(providerId),
            ),
            
            const SizedBox(height: 16),

            // 2. Client Secret
            _KeyCard(
              label: 'API Secret Key',
              value: _mockSecret,
              isSecret: true,
              isVisible: _showSecret,
              onToggleVisibility: () => setState(() => _showSecret = !_showSecret),
              onCopy: () => _copy(_mockSecret),
              action: TextButton.icon(
                onPressed: _isRegenerating ? null : _regenerateKey,
                icon: _isRegenerating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
                label: Text(_isRegenerating ? 'Generating...' : 'Regenerate'),
                style: TextButton.styleFrom(foregroundColor: cs.error),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 20),

            // 3. Configuration
            const Text(
              'Integration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Callback Base URL',
                hintText: 'https://your-server.com/api/callback',
                helperText: 'We will send transaction webhooks to this URL.',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: BrandGradientButton(
                onPressed: _isSavingUrl ? null : _saveBaseUrl,
                child: _isSavingUrl 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', 'Copied to clipboard', 
      duration: const Duration(seconds: 1),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// 封装一个小组件来显示 Key
class _KeyCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecret;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  final VoidCallback onCopy;
  final Widget? action;

  const _KeyCard({
    required this.label,
    required this.value,
    required this.isSecret,
    this.isVisible = true,
    this.onToggleVisibility,
    required this.onCopy,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 如果是 Secret 且不可见，显示星号
    final displayValue = (isSecret && !isVisible) 
        ? '••••••••••••••••••••••••••••' 
        : value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'Monospace', 
                    fontSize: 15,
                    color: cs.onSurfaceVariant,
                    letterSpacing: isSecret && !isVisible ? 2 : 0,
                  ),
                ),
              ),
              if (isSecret)
                IconButton(
                  icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: cs.primary),
                  onPressed: onToggleVisibility,
                  tooltip: isVisible ? 'Hide' : 'Show',
                ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: onCopy,
                tooltip: 'Copy',
              ),
            ],
          ),
        ],
      ),
    );
  }
}