// register.dart
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  bool registerMerchant = false;
  bool passwordVisible = false;
  bool confirm = false;
  late List<Map<String, dynamic>> registerField;
  late List<Map<String, dynamic>> MerchantField;

  @override
  void initState() {
    super.initState();
    _updateRegisterField();
  }

  void _updateRegisterField() {
    registerField = [
      {'label': 'Full Name', 'key': 'fullName', 'icon': Icons.person, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Email', 'key': 'email', 'icon': Icons.email, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'IC Number', 'key': 'IC', 'icon': Icons.card_giftcard, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Phone', 'key': 'phone', 'icon': Icons.phone, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Password', 'key': 'password', 'icon': Icons.lock, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Confirm Password', 'key': 'confirm', 'icon': Icons.lock, 'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
    MerchantField = [
      {'label': 'Merchant ID', 'key': 'MerchantID', 'icon': Icons.upload_file, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Name', 'key': 'MerchantName', 'icon': Icons.business, 'validator': (v) => v!.isEmpty ? 'Required' : null},
      {'label': 'Merchant Phone', 'key': 'MerchantPhone', 'icon': Icons.phone, 'validator': (v) => v!.isEmpty ? 'Required' : null},
    ];
  }

  InputDecoration _decoration(BuildContext context, String label, IconData icon, {Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
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
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1.1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwitchListTile(
                title: Text(registerMerchant ? 'Registering as Merchant' : 'Registering as User',
                    style: theme.textTheme.titleMedium?.copyWith(color: cs.onBackground)),
                value: registerMerchant,
                onChanged: (value) => setState(() {
                  registerMerchant = value;
                  _updateRegisterField();
                }),
              ),
              // 用户通用字段
              ...registerField.map((field) => Container(
                    height: 100,
                    padding: const EdgeInsets.all(30.0),
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
                        suffix: (field['key'] == 'password' || field['key'] == 'confirm')
                            ? IconButton(
                                icon: Icon(
                                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: cs.primary,
                                ),
                                onPressed: () => setState(() {
                                  passwordVisible = !passwordVisible;
                                  confirm = !confirm;
                                }),
                              )
                            : null,
                      ),
                      obscureText:
                          (field['key'] == 'password' && !passwordVisible) ||
                          (field['key'] == 'confirm' && !passwordVisible),
                    ),
                  )),
              // 商家附加字段
              if (registerMerchant)
                ...MerchantField.map((field) => Container(
                      height: 100,
                      padding: const EdgeInsets.all(30.0),
                      child: TextFormField(
                        decoration: _decoration(
                          context,
                          field['label'] as String,
                          field['icon'] as IconData,
                        ),
                      ),
                    )),
              if (registerMerchant)
                Padding(
                  padding: const EdgeInsets.all(15.0),
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
                          // 你原本的上传逻辑
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose File'),
                      ),
                    ],
                  ),
                ),

              // Register 按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (registerMerchant) {
                        // merchant 注册逻辑…
                      } else {
                        // user 注册逻辑…
                      }
                    },
                    child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
