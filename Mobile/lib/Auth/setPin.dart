// lib/Account/Auth/setPin.dart
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

  void _onCompleted(String pin) async {
  if (pin.length != 6) {
    setState(() {
      error = "Please enter a valid 6-digit pin.";
    });
    return;
  }

  setState(() => error = "");

  Get.dialog(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  final auth = Get.find<AuthController>();

  try {
    await auth.registerPasscode(pin);

    // ✅ 如果刚刚是 409 已有 passcode，我们在 registerPasscode 里会填到 lastError
    if (!auth.lastOk.value &&
        auth.lastError.value.contains('Passcode already registered')) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Info",
        "You already have a security PIN. Using the existing one.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/home');
      return;
    }

    if (!auth.lastOk.value) {
      if (Get.isDialogOpen ?? false) Get.back();
      setState(() => error = auth.lastError.value);
      Get.snackbar(
        "Error",
        "Failed to save PIN",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar(
      "Success",
      "Security PIN has been set.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
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
