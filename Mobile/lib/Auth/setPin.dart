import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';

class setPinScreen extends StatefulWidget {
  const setPinScreen({super.key});

  @override
  State<setPinScreen> createState() => _setPinScreenState();
}

class _setPinScreenState extends State<setPinScreen> {
  String error = "";
  final auth = Get.find<AuthController>();

  // 真正调用后端 /api/auth/passcode/register
  Future<void> _savePin(String pin) async {
    await auth.registerPasscode(pin);

    if (!auth.lastOk.value) {
      throw auth.lastError.value;
    }
  }

  void _onCompleted(String pin) async {
    if (pin.length != 6) {
      setState(() {
        error = "Please enter a valid 6-digit pin.";
      });
      return;
    }

    setState(() => error = "");

    // loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await _savePin(pin);

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "Success",
        "Security PIN has been set.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // 这里用户已经是登入状态，设完 PIN 直接去 Home 就好
      Get.offAllNamed('/home');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      setState(() {
        error = "Failed to save PIN: $e";
      });

      Get.snackbar(
        "Error",
        "Failed to save PIN",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: const GlobalAppBar(title: "Set Security PIN"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please set your 6-digit security pin.',
                  style: AppTheme.textMediumBlack.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Pinput(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  enableSuggestions: false,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(
                        color: AppTheme.brandPrimary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  length: 6,
                  onCompleted: _onCompleted,
                  onChanged: (_) {
                    if (error.isNotEmpty) {
                      setState(() => error = "");
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Text(
                      error,
                      style: AppTheme.textMediumBlack.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withRed(255),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
