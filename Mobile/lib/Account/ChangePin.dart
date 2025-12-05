import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GradientWidgets.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final api = Get.find<ApiService>();
  final _formKey = GlobalKey<FormState>();

  // 这里的 Passcode 是 6位数字，和 Password (字符串) 不同
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPin = false; // 控制是否显示数字

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 收起键盘
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // 🔥 调用 apis.dart 里的 changePasscode (PUT /api/auth/passcode/change)
      await api.changePasscode(
        currentPasscode: _currentPinCtrl.text.trim(),
        newPasscode: _newPinCtrl.text.trim(),
      );

      Get.snackbar(
        'Success',
        'Payment PIN updated successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      await Future.delayed(const Duration(seconds: 1));
      // 这比 Get.back() 更稳，因为它直接操作页面栈，无视 Snackbar
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      String errorMsg = 'Failed to update PIN';

      // 🕵️‍♂️ 专门捕捉 401 错误 (旧 PIN 错误)
      if (e.response?.statusCode == 401) {
        errorMsg = 'Current PIN is incorrect.';
      } else {
        // 其他错误解析
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['message']?.toString() ?? errorMsg;
        } else if (data is String) {
          errorMsg = data;
        }
      }

      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Change Security PIN'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter your current 6-digit PIN and set a new one.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 1. Old Passcode
              _PinInput(
                controller: _currentPinCtrl,
                label: 'Current PIN',
                visible: _showPin,
              ),
              const SizedBox(height: 16),

              // 2. New Passcode
              _PinInput(
                controller: _newPinCtrl,
                label: 'New PIN',
                visible: _showPin,
              ),
              const SizedBox(height: 16),

              // 3. Confirm New Passcode
              _PinInput(
                controller: _confirmPinCtrl,
                label: 'Confirm New PIN',
                visible: _showPin,
                validator: (val) {
                  if (val != _newPinCtrl.text) return 'PINs do not match';
                  return null;
                },
              ),

              // Toggle Visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Show PIN'),
                  Switch(
                    value: _showPin,
                    onChanged: (v) => setState(() => _showPin = v),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: BrandGradientButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Update PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 封装一个简单的 PIN 输入框 (只允许数字，限长 6 位)
class _PinInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final String? Function(String?)? validator;

  const _PinInput({
    required this.controller,
    required this.label,
    required this.visible,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      keyboardType: TextInputType.number,
      maxLength: 6, // Passcode 只有 6 位
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        counterText: '', // 隐藏计数器
      ),
      validator: (v) {
        if (v == null || v.length != 6) return 'Must be 6 digits';
        if (validator != null) return validator!(v);
        return null;
      },
    );
  }
}
