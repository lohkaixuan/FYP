import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Controller/WalletController.dart';
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
  final walletController = Get.find<WalletController>();

  //TODO: Verify pin
  void verifyPin(String pin) async {
  if (pin.length != 6) {
    setState(() {
      error = "Please enter a valid 6-digit pin.";
    });
    return;
  }

  // 清空旧错误
  setState(() {
    error = "";
  });

  // 🔍 看看传进来的金额是多少
  // ignore: avoid_print
  debugPrint('[SecurityCode] amount = ${widget.data.amount}');

  // 显示 loading
  Get.dialog(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  final data = widget.data;

  try {
    // 1) 调用钱包转账（/api/wallet/transfer）
    if (data.type == "transfer"){
      await transactionController.walletTransfer(
        fromWalletId: data.fromAccountId,
        toWalletId: data.toAccountId,
        amount: data.amount,
        timestamp: DateTime.now(),
        detail: data.detail,
        categoryCsv: data.category,
      );
    } else if (data.type == "topup") {
      await walletController.topUpWallet(
        walletId: data.toAccountId,
        fromBankAccountId: data.fromAccountId,
        amount: data.amount,
      );
    }
    

    // 2) 关掉 loading
    if (Get.isDialogOpen ?? false) Get.back();

    // 3) 成功提示
    Get.snackbar(
      "Success",
      "Transfer completed successfully.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // 4) 跳回 Home
    Future.delayed(const Duration(seconds: 1), () {
      Get.offAll(() => const HomeScreen());
    });
  } catch (ex) {
    // ❗ 这里是失败逻辑

    // 关掉 loading
    if (Get.isDialogOpen ?? false) Get.back();

    // 从 TransactionController 拿后端错误（如果有）
    final backendError = transactionController.lastError.value;
    final fallbackError = ex.toString();

    // 显示在页面上的红字
    setState(() {
      error = backendError.isNotEmpty ? backendError : fallbackError;
    });

    // Snackbar 也提示一下
    Get.snackbar(
      "Error",
      "Transfer failed: $error",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
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
