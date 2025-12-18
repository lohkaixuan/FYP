import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Controller/PasscodeController.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Controller/WalletController.dart';
import 'package:mobile/Home/home.dart';
import 'package:mobile/Transfer/transfer.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:pinput/pinput.dart';

class SecurityCodeScreen extends StatefulWidget {
  final TransferDetails data;
  const SecurityCodeScreen({super.key, required this.data});

  @override
  State<SecurityCodeScreen> createState() => _SecurityCodeScreenState();
}

class _SecurityCodeScreenState extends State<SecurityCodeScreen> {
  String error = "";
  final transactionController = Get.find<TransactionController>();
  final walletController = Get.find<WalletController>();
  late final PasscodeController passcodeController;

  @override
  void initState() {
    super.initState();
    passcodeController = Get.isRegistered<PasscodeController>()
        ? Get.find<PasscodeController>()
        : Get.put(PasscodeController());
    passcodeController.fetchPasscode();
  }

  //TODO: Verify pin
  void verifyPin(String pin) async {
    if (pin.length != 6) {
      setState(() {
        error = "Please enter a valid 6-digit pin.";
      });
      return;
    }

    setState(() {
      error = "";
    });

    final isValid = await passcodeController.verifyPasscode(pin);
    if (!isValid) {
      setState(() {
        final passcodeError = passcodeController.lastError.value;
        error = passcodeError.isNotEmpty
            ? passcodeError
            : "Incorrect security code. Please try again.";
      });
      return;
    }

    // ignore: avoid_print
    debugPrint('[SecurityCode] amount = ${widget.data.amount}');

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final data = widget.data;

    try {
      if (data.type == "transfer") {
        await transactionController.walletTransfer(
          fromWalletId: data.fromAccountId,
          toWalletId: data.toAccountId,
          amount: data.amount,
          timestamp: DateTime.now(),
          detail: data.detail,
          categoryCsv: data.category,
        );
      } else if (data.type == "topup") {
        if (data.providerId == null || data.externalSourceId == null) {
          throw Exception("Missing provider information for reload.");
        }
        await walletController.reloadWallet(
          walletId: data.toAccountId,
          providerId: data.providerId!,
          externalSourceId: data.externalSourceId!,
          amount: data.amount,
        );
      }

      if (Get.isDialogOpen ?? false) Get.back();

      ApiDialogs.showSuccess(
        "Success",
        "Transfer completed successfully.",
      );

      Future.delayed(const Duration(seconds: 1), () {
        Get.offAllNamed('/home');
      });
    } catch (ex) {
      if (Get.isDialogOpen ?? false) Get.back();

      final backendError = transactionController.lastError.value;
      final fallbackError = ex.toString();

      setState(() {
        error = backendError.isNotEmpty ? backendError : fallbackError;
      });

      ApiDialogs.showError(
        "Transfer failed: $error",
        fallbackTitle: "Error",
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
      appBar: const GlobalAppBar(title: "Security Code"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter 6-digit pin.',
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
                    border: Border.all(color: AppTheme.brandPrimary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  length: 6,
                  onCompleted: (value) => verifyPin(value),
                  onChanged: (value) => setState(() {
                    error = "";
                  }),
                ),
                const SizedBox(height: 10),
                if (error != "")
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
