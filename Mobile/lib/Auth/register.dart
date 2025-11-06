// register.dart (核心片段)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Utils/file_utlis.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool registerMerchant = false;
  bool passwordVisible = false;
  AppPickedFile? _license;  // 选中的执照

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
      /// auto fill in app no by user {'label': 'Merchant ID','key': 'merchantId','icon': Icons.numbers,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Name','key': 'merchantName','icon': Icons.business,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Phone','key': 'merchantPhone','icon': Icons.phone,'controller': TextEditingController(),'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
  }

  Future<void> _submitRegisterOrMerchant({
    required AuthController auth,
    required bool loggedIn,
    required bool merchantMode,
    // File? docFile, // 如果你后面要带文件，一并传进来
  }) async {
    // 0) 基本校验
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 未登录时才校验两次密码一致
    if (!loggedIn) {
      final pwd = (registerField.firstWhere((f) => f['key'] == 'password')['controller'] as TextEditingController).text.trim();
      final cfm = (registerField.firstWhere((f) => f['key'] == 'confirm')['controller'] as TextEditingController).text.trim();
      if (pwd != cfm) {
        Get.snackbar('Oops', 'Passwords do not match');
        return;
      }
    }

    // A) 已登录 + 商家模式：只走商家申请
    if (loggedIn && merchantMode) {
      final ownerId = auth.user.value?.userId ?? auth.newlyCreatedUserId.value;
      if (ownerId.isEmpty) {
        Get.snackbar('Error', 'Missing user id. Please relogin.');
        return;
      }

      await auth.merchantApply(
        ownerUserId: ownerId,
        merchantName: (merchantField.firstWhere((f) => f['key'] == 'merchantName')['controller'] as TextEditingController).text.trim(),
        merchantPhone: (merchantField.firstWhere((f) => f['key'] == 'merchantPhone')['controller'] as TextEditingController).text.trim(),
        docFile:   _license?.file,   // ✅ mobile/desktop
        docBytes:  _license?.bytes,  // ✅ web
        docName:   _license?.name,
      );

      if (!auth.lastOk.value) {
        Get.snackbar('Merchant Apply Failed', auth.lastError.value);
        return;
      }
      Get.snackbar('Success', 'Merchant application submitted. Pending admin approval.');
      Get.offNamed('/home');
      return;
    }

    // B) 未登录 + 用户模式：仅注册用户
    if (!loggedIn && !merchantMode) {
      await auth.registerUser(
        name: (registerField.firstWhere((f) => f['key'] == 'fullName')['controller'] as TextEditingController).text.trim(),
        password: (registerField.firstWhere((f) => f['key'] == 'password')['controller'] as TextEditingController).text.trim(),
        ic: (registerField.firstWhere((f) => f['key'] == 'ic')['controller'] as TextEditingController).text.trim(),
        email: (registerField.firstWhere((f) => f['key'] == 'email')['controller'] as TextEditingController).text.trim(),
        phone: (registerField.firstWhere((f) => f['key'] == 'phone')['controller'] as TextEditingController).text.trim(),
      );
      if (!auth.lastOk.value) {
        Get.snackbar('Register Failed', auth.lastError.value);
        return;
      }
      Get.snackbar('Success', 'User registered successfully.');
      Get.offNamed('/login');
      return;
    }

    // C) 未登录 + 商家模式：先注册用户 → 再商家申请
    if (!loggedIn && merchantMode) {
      final pwd = (registerField.firstWhere((f) => f['key'] == 'password')['controller'] as TextEditingController).text.trim();

      await auth.registerUser(
        name: (registerField.firstWhere((f) => f['key'] == 'fullName')['controller'] as TextEditingController).text.trim(),
        password: pwd,
        ic: (registerField.firstWhere((f) => f['key'] == 'ic')['controller'] as TextEditingController).text.trim(),
        email: (registerField.firstWhere((f) => f['key'] == 'email')['controller'] as TextEditingController).text.trim(),
        phone: (registerField.firstWhere((f) => f['key'] == 'phone')['controller'] as TextEditingController).text.trim(),
      );
      if (!auth.lastOk.value) {
        Get.snackbar('Register Failed', auth.lastError.value);
        return;
      }

      final ownerId = auth.newlyCreatedUserId.value.isNotEmpty
          ? auth.newlyCreatedUserId.value
          : (auth.user.value?.userId ?? '');

      await auth.merchantApply(
        ownerUserId: ownerId,
        merchantName: (merchantField.firstWhere((f) => f['key'] == 'merchantName')['controller'] as TextEditingController).text.trim(),
        merchantPhone: (merchantField.firstWhere((f) => f['key'] == 'merchantPhone')['controller'] as TextEditingController).text.trim(),
        // docFile: docFile,
      );
      if (!auth.lastOk.value) {
        Get.snackbar('Merchant Apply Failed', auth.lastError.value);
        return;
      }
      Get.snackbar('Success', 'User registered. Merchant application submitted and pending admin approval.');
      Get.offNamed('/login');
      return;
    }
  }

  InputDecoration _decoration(BuildContext context, String label, IconData icon, {Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return const InputDecoration().copyWith(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF4655F7)),
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
          final loggedIn = auth.isLoggedIn.value; // 🟢 是否已登录（有 token）
          // 已登录时强制进入“商家申请模式”
          final merchantMode = loggedIn ? true : registerMerchant;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // 🔀 开关（已登录时禁用 + 显示为商家）
              SwitchListTile(
                title: Text(
                  merchantMode ? 'Registering as Merchant' : 'Registering as User',
                  style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                value: merchantMode,
                onChanged: loggedIn
                    ? null // 已登录 → 开关禁用，只能商家申请
                    : (value) => setState(() {
                        registerMerchant = value; // 未登录可切换：用户 or 用户+商家
                        _updateRegisterField();
                      }),
              ),

              // 🧍‍♂️ 用户字段：只有 “未登录且开关=关” 或 “未登录且开关=开(需要先注册用户)” 时显示
              if (!loggedIn) ...[
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
                                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                                )
                              : null,
                        ),
                        obscureText:
                            (field['key'] == 'password' && !passwordVisible) ||
                            (field['key'] == 'confirm' && !passwordVisible),
                        validator: field['validator'] as String? Function(String?)?,
                      ),
                    )),
              ],

              // 🛍️ 商家字段：已登录时显示；未登录且开关=开时也显示
              if (merchantMode) ...[
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

                // 可选：上传执照
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Please upload your business license:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),

                      // ✅ ElevatedButton.icon 正确的参数顺序与花括号
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // 简单日志，确认按钮被点到
                            debugPrint('[pick] tapped');
                        
                            final picked = await FileUtils.pickSingle(
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            );
                        
                            if (picked == null) {
                              Get.snackbar('Canceled', 'No file selected');
                              return;
                            }
                        
                            setState(() => _license = picked);
                            Get.snackbar('Selected', picked.name);
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _license == null ? 'Choose File' : 'Selected: ${_license!.name}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

                  // 提交按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading.value
                            ? null
                            : () async {
                                final loggedIn = auth.isLoggedIn.value;
                                final merchantMode = loggedIn
                                    ? true
                                    : registerMerchant; // 已登录强制商家模式

                                await _submitRegisterOrMerchant(
                                  auth: auth,
                                  loggedIn: loggedIn,
                                  merchantMode: merchantMode,
                                  // docFile: _docFile,
                                );
                              },
                        child: auth.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Submit'),
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
