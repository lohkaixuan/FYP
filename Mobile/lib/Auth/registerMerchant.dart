// lib/Account/Auth/registerMerchant.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/Auth/auth.dart';
import 'package:mobile/Utils/file_utlis.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Component/GradientWidgets.dart';

class RegisterMerchant extends StatefulWidget {
  const RegisterMerchant({super.key});

  @override
  State<RegisterMerchant> createState() => _RegisterMerchantState();
}

class _RegisterMerchantState extends State<RegisterMerchant> {
  final _formKey = GlobalKey<FormState>();
  final _merchantNameCtrl = TextEditingController();
  final _merchantPhoneCtrl = TextEditingController();
  AppPickedFile? _license; // 营业执照文件

  InputDecoration _decoration(
      BuildContext context, String label, IconData icon) {
    return const InputDecoration().copyWith(
      labelText: label,
      prefixIcon: GradientIcon(icon),
    );
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();

    // 必须是已登录的普通用户（isUserOnly 你在 Account 里也有类似判断）
    if (!auth.isUser) {
      ApiDialogs.showError(
        'Only logged-in user accounts can apply as merchant.',
        fallbackTitle: 'Not allowed',
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ownerId =
        auth.user.value?.userId ?? auth.newlyCreatedUserId.value;
    if (ownerId.isEmpty) {
      ApiDialogs.showError(
        'Missing user id. Please relogin first.',
        fallbackTitle: 'Error',
      );
      return;
    }

    // （可选）强制要求上传执照
    if (_license == null) {
      ApiDialogs.showError(
        'Please upload your business license file.',
        fallbackTitle: 'License required',
      );
      return;
    }
        
    if (_merchantPhoneCtrl .text.trim().length != 10) {
      ApiDialogs.showError(
        'Please enter valid phone number(10 digit). exp: 0123456789',
        fallbackTitle: 'Error',
      );
      return;
    }

    await auth.merchantApply(
      ownerUserId: ownerId,
      merchantName: _merchantNameCtrl.text.trim(),
      merchantPhone: _merchantPhoneCtrl.text.trim(),
      docFile: _license!.file,
      docBytes: _license!.bytes,
      docName: _license!.name,
    );

    if (!auth.lastOk.value) {
      ApiDialogs.showError(
        auth.lastError.value,
        fallbackTitle: 'Merchant Apply Failed',
      );
      return;
    }

    ApiDialogs.showSuccess(
      'Success',
      'Merchant application submitted. Pending admin approval.',
      onConfirm: () => Get.offNamed('/home'),
    );
    // 或者：Get.back();
  }

  @override
  void dispose() {
    _merchantNameCtrl.dispose();
    _merchantPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply as Merchant'),
      ),
      body: Obx(() {
        final loading = auth.isLoading.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merchant Application',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your user account will be used as merchant owner.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Merchant Name
                TextFormField(
                  controller: _merchantNameCtrl,
                  decoration: _decoration(
                    context,
                    'Merchant Name',
                    Icons.business,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Merchant Phone
                TextFormField(
                  controller: _merchantPhoneCtrl,
                  decoration: _decoration(
                    context,
                    'Merchant Phone',
                    Icons.phone,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Upload business license
                Text(
                  'Business License',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: BrandGradientButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final picked = await FileUtils.pickSingle(
                              allowedExtensions: [
                                'pdf',
                                'jpg',
                                'jpeg',
                                'png'
                              ],
                            );
                            if (picked == null) {
                              ApiDialogs.showError(
                                'No file selected',
                                fallbackTitle: 'Canceled',
                              );
                              return;
                            }
                            setState(() => _license = picked);
                            ApiDialogs.showSuccess(
                              'Selected',
                              picked.name,
                            );
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
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: BrandGradientButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Application',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
