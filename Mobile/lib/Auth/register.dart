// register.dart (核心片段)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/authController.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool registerMerchant = false;
  bool passwordVisible = false;

  late List<Map<String, dynamic>> registerField;
  late List<Map<String, dynamic>> merchantField;

  @override
  void initState() {
    super.initState();
    _updateRegisterField();
  }

  void _updateRegisterField() {
    registerField = [
      {'label': 'Full Name','key': 'fullName','icon': Icons.person,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Email','key': 'email','icon': Icons.email,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'IC Number','key': 'ic','icon': Icons.badge,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Phone','key': 'phone','icon': Icons.phone,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Password','key': 'password','icon': Icons.lock,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Confirm Password','key': 'confirm','icon': Icons.lock,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
    merchantField = [
      {'label': 'Merchant ID','key': 'merchantId','icon': Icons.numbers,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Name','key': 'merchantName','icon': Icons.business,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Phone','key': 'merchantPhone','icon': Icons.phone,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
  }


  InputDecoration _decoration(BuildContext context, String label, IconData icon, {Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelText: label,
      prefixIcon: Icon(icon, color: cs.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: cs.onSurface.withOpacity(.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                SwitchListTile(
                  title: Text(
                    registerMerchant ? 'Registering as Merchant' : 'Registering as User',
                    style: theme.textTheme.titleMedium?.copyWith(color: cs.onBackground),
                    textAlign: TextAlign.center,
                  ),
                  value: registerMerchant,
                  onChanged: (value) => setState(() {
                    registerMerchant = value;
                    _updateRegisterField();
                  }),
                ),

                // 用户通用字段
                ...registerField.map((field) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: TextFormField(
                        controller: field['controller'] as TextEditingController,
                        keyboardType: field['key'] == 'email'
                            ? TextInputType.emailAddress
                            : field['key'] == 'phone'
                                ? TextInputType.phone
                                : TextInputType.text,
                        decoration: _decoration(
                          context,
                          field['label'] as String,
                          field['icon'] as IconData,
                          suffix: (field['key'] == 'password' || field['key'] == 'confirm')
                              ? IconButton(
                                  icon: Icon(
                                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: cs.primary,
                                  ),
                                  onPressed: () => setState(() {
                                    passwordVisible = !passwordVisible;
                                  }),
                                )
                              : null,
                        ),
                        obscureText:
                            (field['key'] == 'password' && !passwordVisible) ||
                            (field['key'] == 'confirm' && !passwordVisible),
                        validator: field['validator'] as String? Function(String?)?,
                      ),
                    )),

                // 商家附加字段
                if (registerMerchant)
                  ...merchantField.map((field) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: TextFormField(
                          controller: field['controller'] as TextEditingController,
                          decoration: _decoration(
                            context,
                            field['label'] as String,
                            field['icon'] as IconData,
                          ),
                          validator: field['validator'] as String? Function(String?)?,
                        ),
                      )),

                // 选择文件（可选）
                if (registerMerchant)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text('Please upload your business license:', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            // TODO: pick file -> setState 保存 File 到 state（例如 _docFile）
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choose File'),
                        ),
                      ],
                    ),
                  ),

                // 提交按钮
                Obx(() {
                  final loading = auth.isLoading.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                if (!(_formKey.currentState?.validate() ?? false)) return;
                                // 密码一致性校验
                                await auth.registerUser(
                                  name: (registerField.firstWhere((f) =>                                              f['key'] ==                                              'fullName')['controller'] as TextEditingController)
                                      .text
                                      .trim(),
                                  password: (registerField.firstWhere((f) =>
                                              f['key'] ==
                                              'password')['controller']
                                          as TextEditingController)
                                      .text
                                      .trim(),
                                  ic: (registerField.firstWhere((f) =>
                                              f['key'] == 'ic')['controller']
                                          as TextEditingController)
                                      .text
                                      .trim(),
                                  email: (registerField.firstWhere((f) =>
                                              f['key'] == 'email')['controller']
                                          as TextEditingController)
                                      .text
                                      .trim(),
                                  phone: (registerField.firstWhere((f) =>
                                              f['key'] == 'phone')['controller']
                                          as TextEditingController)
                                      .text
                                      .trim(),
                                );

                                if (registerMerchant) {
                                  // 1) 先注册用户
                                  await auth.registerUser(
                                    name: (registerField.firstWhere((f) =>
                                                f['key'] ==
                                                'fullName')['controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    password: (registerField.firstWhere((f) =>
                                                f['key'] ==
                                                'password')['controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    ic: (registerField.firstWhere((f) =>
                                                f['key'] == 'ic')['controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    email: (registerField.firstWhere((f) =>
                                                f['key'] ==
                                                'email')['controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    phone: (registerField.firstWhere((f) =>
                                                f['key'] ==
                                                'phone')['controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                  );

                                  if (auth.lastError.isNotEmpty) {
                                    Get.snackbar('Register Failed',
                                        auth.lastError.value);
                                    return;
                                  }

                                  // 2) 提交商户申请（示例：ownerUserId 需要你在登录后/注册成功后拿到真实 userId）
                                  await auth.merchantApply(
                                    ownerUserId: auth.user.value?.userId ?? '',
                                    merchantName: (merchantField.firstWhere(
                                                    (f) =>
                                                        f['key'] ==
                                                        'merchantName')[
                                                'controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    merchantPhone: (merchantField.firstWhere(
                                                    (f) =>
                                                        f['key'] ==
                                                        'merchantPhone')[
                                                'controller']
                                            as TextEditingController)
                                        .text
                                        .trim(),
                                    // docFile: _docFile,
                                  );

                                  if (auth.lastError.isNotEmpty) {
                                    Get.snackbar('Merchant Apply Failed',
                                        auth.lastError.value);
                                    return;
                                  }

                                  // 导航（你说要在外层做导航，这里给一行你喜欢的格式；不需要可删）
                                  Get.offAndToNamed('/login');
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Back to Login'),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
