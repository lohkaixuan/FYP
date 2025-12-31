// lib/Account/Auth/register.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;

  late List<Map<String, dynamic>> registerField;

  @override
  void initState() {
    super.initState();
    _updateRegisterField();
  }

  void _updateRegisterField() {
    registerField = [
      {
        'label': 'Full Name',
        'key': 'fullName',
        'icon': Icons.person,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
      {
        'label': 'Email',
        'key': 'email',
        'icon': Icons.email,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
      {
        'label': 'IC Number',
        'key': 'ic',
        'icon': Icons.badge,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
      {
        'label': 'Phone',
        'key': 'phone',
        'icon': Icons.phone,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
      {
        'label': 'Password',
        'key': 'password',
        'icon': Icons.lock,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
      {
        'label': 'Confirm Password',
        'key': 'confirm',
        'icon': Icons.lock,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null,
      },
    ];
  }

  TextEditingController _regCtrl(String key) =>
      registerField.firstWhere((f) => f['key'] == key)['controller']
          as TextEditingController;

  Future<void> _submitRegister(AuthController auth) async {
    
    if (!(_formKey.currentState?.validate() ?? false)) return;

    
    final pwdCtrl =
        registerField.firstWhere((f) => f['key'] == 'password')['controller']
            as TextEditingController;
    final cfmCtrl =
        registerField.firstWhere((f) => f['key'] == 'confirm')['controller']
            as TextEditingController;

    final pwd = pwdCtrl.text.trim();
    final cfm = cfmCtrl.text.trim();

    if (pwd != cfm) {
      ApiDialogs.showError('Passwords do not match', fallbackTitle: 'Oops');
      return;
    }

    final name = _regCtrl('fullName').text.trim();
    final email = _regCtrl('email').text.trim();
    final phone = _regCtrl('phone').text.trim();
    final ic = _regCtrl('ic').text.trim();

    if (phone.length != 10 || phone.length > 10) {
      ApiDialogs.showError(
        'Please enter valid phone number(10 digit). exp: 0123456789',
        fallbackTitle: 'Format Error',
      );
      return;
    }

    if (ic.length != 12 || ic.length > 12) {
      ApiDialogs.showError(
        'Please enter valid ic number. Need 12 digits',
        fallbackTitle: 'Format Error',
      );
      return;
    }

    
    await auth.registerUser(
      name: name,
      password: pwd,
      ic: ic,
      email: email,
      phone: phone,
    );

    if (!auth.lastOk.value) {
      ApiDialogs.showError(
        auth.lastError.value,
        fallbackTitle: 'Register Failed',
      );
      return;
    }

<<<<<<< HEAD
    
    Get.snackbar(
=======
    // 3) 注册成功 → 回登录页让用户手动登录
    ApiDialogs.showSuccess(
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      'Success',
      'User registered successfully. Please login.',
      onConfirm: () => Get.offNamed('/login'),
    );
  }

  InputDecoration _decoration(
    BuildContext context,
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return const InputDecoration().copyWith(
      labelText: label,
      prefixIcon: GradientIcon(icon),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1,
          child: Form(
            key: _formKey,
            child: Obx(() {
              final loading = auth.isLoading.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Create New Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  ...registerField.map((field) {
                    final key = field['key'] as String;
                    final controller =
                        field['controller'] as TextEditingController;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: TextFormField(
                        controller: controller,
                        keyboardType: key == 'email'
                            ? TextInputType.emailAddress
                            : key == 'phone'
                                ? TextInputType.phone
                                : TextInputType.text,
                        decoration: _decoration(
                          context,
                          field['label'] as String,
                          field['icon'] as IconData,
                          suffix: (key == 'password' || key == 'confirm')
                              ? IconButton(
                                  icon: Icon(
                                    passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: cs.primary,
                                  ),
                                  onPressed: () => setState(
                                      () => passwordVisible = !passwordVisible),
                                )
                              : null,
                        ),
                        obscureText:
                            (key == 'password' && !passwordVisible) ||
                                (key == 'confirm' && !passwordVisible),
                        validator:
                            field['validator'] as String? Function(String?)?,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: BrandGradientButton(
                        onPressed: loading
                            ? null
                            : () async {
                                await _submitRegister(auth);
                              },
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
