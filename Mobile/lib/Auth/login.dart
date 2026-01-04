// ==================================================
// Program Name   : login.dart
// Purpose        : Login screen
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Auth/setPin.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Utils/api_dialogs.dart';

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
  final useEmailLogin = false.obs; // false = phone, true = email

  @override
  void initState() {
    super.initState();
    _updateLoginField();
  }

  void _updateLoginField() {
    loginField = [
      useEmailLogin.value
          ? {
              'label': 'Email',
              'key': 'email',
              'icon': Icons.email,
              'controller': TextEditingController(),
              'validator': (v) => v!.isEmpty ? 'Required' : null
            }
          : {
              'label': 'Phone',
              'key': 'phone',
              'icon': Icons.phone,
              'controller': TextEditingController(),
              'validator': (v) => v!.isEmpty ? 'Required' : null
            },
      {
        'label': 'Password',
        'key': 'password',
        'icon': Icons.lock,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
    ];
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

                      Obx(
                        () => SwitchListTile(
                          title: Text(
                            useEmailLogin.value ? 'Email Login' : 'Phone Login',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: cs.onBackground),
                          ),
                          value: useEmailLogin.value,
                          onChanged: (v) {
                            FocusScope.of(context).unfocus();
                            useEmailLogin.value = v;
                            _updateLoginField();
                          },
                        ),
                      ),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            ...loginField.map(
                              (field) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: field['controller']
                                      as TextEditingController,
                                  validator: field['validator'] as String?
                                      Function(String?)?,
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
                                            onPressed: () => setState(() =>
                                                passwordVisible =
                                                    !passwordVisible),
                                            icon: GradientIcon(
                                              passwordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                          )
                                        : null,
                                  ),
                                  obscureText: field['key'] == 'password' &&
                                      !passwordVisible,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Obx(() {
                              final loading = auth.isLoading.value;
                              return SizedBox(
                                width: double.infinity,
                                child: BrandGradientButton(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) return;

                                          String? email;
                                          String? phone;
                                          final passwordCtrl =
                                              loginField.firstWhere((f) =>
                                                      f['key'] ==
                                                      'password')['controller']
                                                  as TextEditingController;

                                          if (useEmailLogin.value) {
                                            final emailCtrl =
                                                loginField.firstWhere((f) =>
                                                        f['key'] ==
                                                        'email')['controller']
                                                    as TextEditingController;
                                            email = emailCtrl.text.trim();
                                          } else {
                                            final phoneCtrl =
                                                loginField.firstWhere((f) =>
                                                        f['key'] ==
                                                        'phone')['controller']
                                                    as TextEditingController;
                                            phone = phoneCtrl.text.trim();
                                          }

                                          final password =
                                              passwordCtrl.text.trim();
                                          await auth.loginFlexible(
                                            email: email,
                                            phone: phone,
                                            password: password,
                                          );

                                          if (!auth.lastOk.value) {
                                            ApiDialogs.showError(
                                              auth.lastError.value,
                                              fallbackTitle: 'Login Failed',
                                              fallbackMessage:
                                                  'Invalid credentials.',
                                            );
                                            return;
                                          }

                                          try {
                                            final info =
                                                await auth.getMyPasscode();

                                            final hasPass =
                                                (info.passcode?.isNotEmpty ??
                                                    false);
                                            if (!hasPass) {
                                              Get.offAll(
                                                  () => const setPinScreen());
                                            } else {
                                              Get.offAllNamed('/home');
                                            }
                                          } catch (_) {
                                            Get.offAllNamed('/home');
                                          }
                                        },
                                  child: loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Login'),
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('New user? ',
                                    style: theme.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: () => Get.toNamed(
                                    '/signup',
                                    arguments: {
                                      'forceNewUser': true
                                    }, 
                                  ),
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
