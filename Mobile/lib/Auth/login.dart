// login.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/GradientWidgets.dart';
// 你已有：数据结构与 Column 不变 ✔️

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  bool passwordVisible = false;
  final _formKey = GlobalKey<FormState>();

  late List<Map<String, dynamic>> loginField;
  final auth = Get.find<AuthController>();
  final useEmailLogin = false.obs;

  @override
  void initState() {
    super.initState();
    _updateLoginField();
  }

  void _updateLoginField() {
    loginField = [
      useEmailLogin.value
          ? { 'label': 'Email', 'key': 'email', 'icon': Icons.email, 'controller': TextEditingController(), 'validator': (v) => v!.isEmpty ? 'Required' : null }
          : { 'label': 'Phone', 'key': 'phone', 'icon': Icons.phone, 'controller': TextEditingController(), 'validator': (v) => v!.isEmpty ? 'Required' : null },
      { 'label': 'Password', 'key': 'password', 'icon': Icons.lock, 'controller': TextEditingController(), 'validator': (v) => v!.isEmpty ? 'Required' : null },
    ];
  }

  // 统一的输入框装饰：遵循 AppTheme.inputDecorationTheme
  InputDecoration _decoration(BuildContext context, String label, IconData icon,
      {Widget? suffix}) {
    return const InputDecoration().copyWith(
      labelText: label,
      prefixIcon: GradientIcon(icon),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

// 只展示 body 结构的改动，逻辑不变 ✅
return Scaffold(
  // ✅ 让 Scaffold 根据键盘高度自动上移
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    // ✅ 用 LayoutBuilder 拿到可视高度，配合约束让内容在大屏也能居中
    child: LayoutBuilder(
      builder: (context, constraints) {
        final cs = Theme.of(context).colorScheme;

        return SingleChildScrollView(
          // ✅ 键盘弹出时，滚动视图底部加上同等 padding，避免被遮挡
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          // ✅ 下拉时自动收起键盘（体验更好）
          keyboardDismissBehavior: ScrollBehavior().copyWith(overscroll: false) is ScrollBehavior
              ? ScrollViewKeyboardDismissBehavior.onDrag
              : ScrollViewKeyboardDismissBehavior.manual, // 兼容写法，保持 onDrag
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== 你的 Logo / 开关 / 表单 原样放回 =====
                // 顶部 Logo 容器：用主题卡片色 & 阴影
                Container(
                  height: 200, 
                  width: 200,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/logo2.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Obx(() => SwitchListTile(
                  title: Text(
                    useEmailLogin.value ? 'Email Login' : 'Phone Login',
                    style: theme.textTheme.titleMedium?.copyWith(color: cs.onBackground),
                  ),
                  value: useEmailLogin.value,
                  onChanged: (v) {
                    FocusScope.of(context).unfocus();
                    useEmailLogin.value = v;
                    _updateLoginField(); // refresh input fields
                  },
                )),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                ...loginField.map((field) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller:
                            field['controller'] as TextEditingController,
                        validator:
                            field['validator'] as String? Function(String?),
                        keyboardType: field['key'] == 'email'
                            ? TextInputType.emailAddress
                            : field['key'] == 'phone'
                                ? TextInputType.phone
                                : TextInputType.text,
                        decoration: _decoration(
                          context,
                          field['label'] as String,
                          field['icon'] as IconData,
                          suffix: field['key'] == 'password'
                              ? IconButton(
                                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                                  icon: GradientIcon(
                                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                )
                              : null,
                        ),
                        obscureText:
                            field['key'] == 'password' && !passwordVisible,
                      ),
                    )),

                const SizedBox(height: 20),

                Obx(() {
                  final loading = auth.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    child: BrandGradientButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!(_formKey.currentState?.validate() ?? false)) return;

                              await auth.loginFlexible(
                                email: useEmailLogin.value
                                    ? (loginField.firstWhere((f) => f['key'] == 'email')['controller'] as TextEditingController).text.trim()
                                    : null,
                                phone: !useEmailLogin.value
                                    ? (loginField.firstWhere((f) => f['key'] == 'phone')['controller'] as TextEditingController).text.trim()
                                    : null,
                                password: (loginField.firstWhere( (f) => f['key'] == 'password')[ 'controller'] as TextEditingController).text.trim(),
                              );

                            },
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Login'),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New user? ', style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Get.toNamed('/signup'),
                      child: const Text('Sign Up New Account Here'),
                    ),
                  ],
                ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
  }
} 
