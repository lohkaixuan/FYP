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
  void dispose() {
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    merchantPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();

    /// 填入现有资料
    emailCtrl.text = auth.user.value?.email ?? '';
    phoneCtrl.text = auth.user.value?.phone ?? '';

    if (auth.isMerchant) {
      merchantPhoneCtrl.text =
          auth.user.value?.merchantPhone ?? ''; // 如果后端有 merchantPhone 字段
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
              TextFormField(
                controller: passwordCtrl,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: "New Password (optional)",
                  prefixIcon: const GradientIcon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
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

                // 1) 校验两次密码
                if (passwordCtrl.text.isNotEmpty &&
                    passwordCtrl.text != confirmCtrl.text) {
                  ApiDialogs.showError("Passwords do not match");
                  return;
                }

                // 2) 先更新资料
                if (!isMerchant) {
                  await auth.updateMyProfile(
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
                } else {
                  await auth.updateMyProfile(
                    merchantPhone: merchantPhoneCtrl.text.trim(),
                  );
                }

                if (!auth.lastOk.value) {
                  ApiDialogs.showError(auth.lastError.value);
                  return;
                }

                // 3) 再更新密码（如果有填）
                if (!isMerchant && passwordCtrl.text.isNotEmpty) {
                  await auth.changeMyPassword(
                    // 如果后端不需要 currentPassword，就在方法里只传 newPassword
                    currentPassword: '', // 或者加一个 TextFormField 让用户填
                    newPassword: passwordCtrl.text.trim(),
                  );

                  if (!auth.lastOk.value) {
                    ApiDialogs.showError(auth.lastError.value);
                    return;
                  }
                }

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
