import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Utils/api_dialogs.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final merchantPhoneCtrl = TextEditingController();

  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    final u = auth.user.value;

    // 预填现有资料
    emailCtrl.text = u?.email ?? '';
    phoneCtrl.text = u?.phone ?? '';

    if (auth.isMerchant) {
      // 目前 AppUser 拿不到商家电话，就先给空字串
      merchantPhoneCtrl.text = '';
      // 如果你以后在 /me 里加了 merchantPhoneNumber，再从 auth.user 里取
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isMerchant = auth.isMerchant;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!isMerchant) ...[
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: GradientIcon(Icons.email),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: GradientIcon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ⚠️ 这两个密码栏目前只是 UI，后端还没接 change-password
              TextFormField(
                controller: passwordCtrl,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: "New Password (optional)",
                  prefixIcon: const GradientIcon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => passwordVisible = !passwordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: confirmCtrl,
                obscureText: !passwordVisible,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: GradientIcon(Icons.lock),
                ),
              ),
            ],

            if (isMerchant) ...[
              TextFormField(
                controller: merchantPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant Phone',
                  prefixIcon: GradientIcon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],

            const SizedBox(height: 30),

            BrandGradientButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;

                // 校验密码一致（仅在 user 模式且有输入时）
                if (!isMerchant &&
                    passwordCtrl.text.isNotEmpty &&
                    passwordCtrl.text != confirmCtrl.text) {
                  ApiDialogs.showError("Passwords do not match");
                  return;
                }

                if (!isMerchant) {
                  await auth.updateMyProfile(
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    // newPassword: passwordCtrl.text.trim(), // ⚠️ 先留着，等后端有 endpoint 再启用
                  );
                } else {
                  await auth.updateMyProfile(
                    phone: merchantPhoneCtrl.text.trim(),
                  );
                }

                if (!auth.lastOk.value) {
                  ApiDialogs.showError(auth.lastError.value);
                  return;
                }

                // 为了看到最新资料，顺便 refresh 一下 /me
                await auth.refreshMe();

                Get.back();
                Get.snackbar("Updated", "Profile updated successfully!");
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
