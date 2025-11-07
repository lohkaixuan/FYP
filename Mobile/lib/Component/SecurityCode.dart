import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Home/home.dart';
import 'package:mobile/Transfer/transfer.dart';
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

  //TODO: Verify pin
  void verifyPin(String pin) async {
    if (pin != '123456') {
      setState(() {
        error = "Incorrect pin.";
      });
    } else {
      setState(() {
        error = "";
      });
      final data = widget.data;
      try {
        // Try creating a transaction.
        await transactionController.create(
          type: data.type,
          from: data.fromAccountNumber,
          to: data.toAccountNumber,
          amount: data.amount,
          timestamp: DateTime.now(),
          item: data.item,
          detail: data.detail,
        );
        Get.snackbar(
          "Success",
          "Transaction completed successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Go to Home Page upon success.
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAll(() => const HomeScreen());
        });
      } catch (ex) {
        setState(() {
          error = transactionController.lastError.value;
        });
      }
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
