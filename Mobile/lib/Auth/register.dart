// lib/Account/Auth/register.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Auth/setPin.dart';
import 'package:mobile/Utils/file_utlis.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Component/GradientWidgets.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool registerMerchant = false;
  bool passwordVisible = false;
  AppPickedFile? _license; // 选中的执照

  late List<Map<String, dynamic>> registerField;
  late List<Map<String, dynamic>> merchantField;

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
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
        'label': 'Email',
        'key': 'email',
        'icon': Icons.email,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
        'label': 'IC Number',
        'key': 'ic',
        'icon': Icons.badge,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
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
      {
        'label': 'Confirm Password',
        'key': 'confirm',
        'icon': Icons.lock,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
    ];

    merchantField = [
      {
        'label': 'Merchant Name',
        'key': 'merchantName',
        'icon': Icons.business,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
        'label': 'Merchant Phone',
        'key': 'merchantPhone',
        'icon': Icons.phone,
        'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
    ];
  }

  TextEditingController _regCtrl(String key) =>
      registerField.firstWhere((f) => f['key'] == key)['controller']
          as TextEditingController;

  TextEditingController _merchCtrl(String key) =>
      merchantField.firstWhere((f) => f['key'] == key)['controller']
          as TextEditingController;

  Future<void> _submitRegisterOrMerchant({
    required AuthController auth,
    required bool loggedIn,
    required bool merchantMode,
  }) async {
    // 0) 基本校验
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 未登录时才校验两次密码一致
    if (!loggedIn) {
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
    }

    // 🔑 不管哪种模式，先把 email / phone / password 拿出来（后面要自动登录）
    final emailCtrl =
        registerField.firstWhere((f) => f['key'] == 'email')['controller']
            as TextEditingController;
    final phoneCtrl =
        registerField.firstWhere((f) => f['key'] == 'phone')['controller']
            as TextEditingController;
    final pwdCtrl =
        registerField.firstWhere((f) => f['key'] == 'password')['controller']
            as TextEditingController;

    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final password = pwdCtrl.text.trim();

    // A) 已登录 + 商家模式：只走商家申请（不动 PIN）
    if (loggedIn && merchantMode) {
      final ownerId = auth.user.value?.userId ?? auth.newlyCreatedUserId.value;
      if (ownerId.isEmpty) {
        Get.snackbar('Error', 'Missing user id. Please relogin.');
        return;
      }

      await auth.merchantApply(
        ownerUserId: ownerId,
        merchantName: (merchantField
                    .firstWhere((f) => f['key'] == 'merchantName')['controller']
                as TextEditingController)
            .text
            .trim(),
        merchantPhone: (merchantField.firstWhere(
                    (f) => f['key'] == 'merchantPhone')['controller']
                as TextEditingController)
            .text
            .trim(),
        docFile: _license?.file,
        docBytes: _license?.bytes,
        docName: _license?.name,
      );

      if (!auth.lastOk.value) {
        ApiDialogs.showError(
          auth.lastError.value,
          fallbackTitle: 'Merchant Apply Failed',
        );
        return;
      }

      Get.snackbar(
        'Success',
        'Merchant application submitted. Pending admin approval.',
      );
      Get.offNamed('/home');
      return;
    }

    // B) 未登录 + 用户模式：注册用户 → 自动登录 → 跳去设 PIN
    if (!loggedIn && !merchantMode) {
      await auth.registerUser(
      name: (registerField.firstWhere((f) => f['key'] == 'fullName')['controller'] as TextEditingController).text.trim(),
      password: (registerField.firstWhere((f) => f['key'] == 'password')['controller'] as TextEditingController).text.trim(),
      ic: (registerField.firstWhere((f) => f['key'] == 'ic')['controller'] as TextEditingController).text.trim(),
      email: (registerField.firstWhere((f) => f['key'] == 'email')['controller'] as TextEditingController).text.trim(),
      phone: (registerField.firstWhere((f) => f['key'] == 'phone')['controller'] as TextEditingController).text.trim(),
    );

    if (!auth.lastOk.value) {
      ApiDialogs.showError(auth.lastError.value, fallbackTitle: 'Register Failed');
      return;
    }

    Get.snackbar('Success', 'User registered successfully. Please login.');
    Get.offNamed('/login');   // ✅ 这里只回 Login，不再跳 setPin
    return;
  }

    // C) 未登录 + 商家模式：注册用户 → 自动登录 → 商家申请 → 跳去设 PIN
    if (!loggedIn && merchantMode) {
      await auth.registerUser(
        name: (registerField
                    .firstWhere((f) => f['key'] == 'fullName')['controller']
                as TextEditingController)
            .text
            .trim(),
        password: password,
        ic: (registerField.firstWhere((f) => f['key'] == 'ic')['controller']
                as TextEditingController)
            .text
            .trim(),
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

      // 先自动登录，拿 token & userId
      await auth.login(
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
        password: password,
      );

      if (!auth.isLoggedIn.value) {
        ApiDialogs.showError(
          'Auto login after register failed',
          fallbackTitle: 'Login Failed',
        );
        return;
      }

      final ownerId = auth.user.value?.userId ?? auth.newlyCreatedUserId.value;

      await auth.merchantApply(
        ownerUserId: ownerId,
        merchantName: (merchantField
                    .firstWhere((f) => f['key'] == 'merchantName')['controller']
                as TextEditingController)
            .text
            .trim(),
        merchantPhone: (merchantField.firstWhere(
                    (f) => f['key'] == 'merchantPhone')['controller']
                as TextEditingController)
            .text
            .trim(),
        docFile: _license?.file,
        docBytes: _license?.bytes,
        docName: _license?.name,
      );

      if (!auth.lastOk.value) {
        ApiDialogs.showError(
          auth.lastError.value,
          fallbackTitle: 'Merchant Apply Failed',
        );
        return;
      }

      Get.snackbar(
        'Success',
        'User registered. Merchant application submitted and pending admin approval.',
      );

      // 最后同样跳去设 PIN
      Get.to(() => const setPinScreen());
      return;
    }
  }

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
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1,
          child: Form(
            key: _formKey,
            child: Obx(() {
              final loggedIn = auth.isLoggedIn.value;
              final merchantMode = loggedIn ? true : registerMerchant;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // 切换 user / merchant
                  SwitchListTile(
                    title: Text(
                      merchantMode
                          ? 'Registering as Merchant'
                          : 'Registering as User',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    value: merchantMode,
                    onChanged: loggedIn
                        ? null
                        : (value) {
                            setState(() {
                              registerMerchant = value;
                              _updateRegisterField();
                            });
                          },
                  ),

                  // 用户字段（未登录时才显示）
                  if (!loggedIn) ...[
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
                                    onPressed: () => setState(() =>
                                        passwordVisible = !passwordVisible),
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
                    }),
                  ],

                  // 商家字段
                  if (merchantMode) ...[
                    ...merchantField.map((field) {
                      final controller =
                          field['controller'] as TextEditingController;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: TextFormField(
                          controller: controller,
                          decoration: _decoration(
                            context,
                            field['label'] as String,
                            field['icon'] as IconData,
                          ),
                          validator:
                              field['validator'] as String? Function(String?)?,
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Please upload your business license:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: BrandGradientButton(
                              onPressed: () async {
                                final picked = await FileUtils.pickSingle(
                                  allowedExtensions: [
                                    'pdf',
                                    'jpg',
                                    'jpeg',
                                    'png'
                                  ],
                                );
                                if (picked == null) {
                                  Get.snackbar('Canceled', 'No file selected');
                                  return;
                                }
                                setState(() => _license = picked);
                                Get.snackbar('Selected', picked.name);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.upload_file,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _license == null
                                        ? 'Choose File'
                                        : 'Selected: ${_license!.name}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 提交按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: BrandGradientButton(
                        onPressed: auth.isLoading.value
                            ? null
                            : () async {
                                final loggedIn = auth.isLoggedIn.value;
                                final merchantMode =
                                    loggedIn ? true : registerMerchant;
                                await _submitRegisterOrMerchant(
                                  auth: auth,
                                  loggedIn: loggedIn,
                                  merchantMode: merchantMode,
                                );
                              },
                        child: auth.isLoading.value
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
                  const SizedBox(height: 60),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
