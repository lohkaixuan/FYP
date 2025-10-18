// login.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 你已有：数据结构与 Column 不变 ✔️

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  bool useEmailLogin = false;
  bool passwordVisible = false;

  late List<Map<String, dynamic>> loginField;

  @override
  void initState() {
    super.initState();
    _updateLoginField();
  }

  void _updateLoginField() {
    loginField = [
      useEmailLogin
          ? {'label': 'Email', 'key': 'email', 'icon': Icons.email, 'validator': (v) => v!.isEmpty ? 'Required' : null}
          : {'label': 'Phone', 'key': 'phone', 'icon': Icons.phone, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Password', 'key': 'password', 'icon': Icons.lock, 'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
  }

  // 统一的输入框装饰（只加样式，不改结构）
  InputDecoration _decoration(BuildContext context, String label, IconData icon, {Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: cs.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withOpacity(.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 顶部 Logo 容器：用主题卡片色 & 阴影
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
                    ),
                  ),
                ),

                SwitchListTile(
                  title: Text(useEmailLogin ? 'Email Login' : 'Phone Login',
                      style: theme.textTheme.titleMedium?.copyWith(color: cs.onBackground)),
                  value: useEmailLogin,
                  onChanged: (value) => setState(() {
                    useEmailLogin = value;
                    _updateLoginField();
                  }),
                ),

                ...loginField.map((field) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
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
                                  icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: cs.primary),
                                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                                )
                              : null,
                        ),
                        obscureText: field['key'] == 'password' && !passwordVisible,
                      ),
                    )),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // 你的原逻辑不变
                    },
                    child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New user? ', style: theme.textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => Get.toNamed('/signup'),
                      child: Text(
                        'Sign Up New Account Here',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
