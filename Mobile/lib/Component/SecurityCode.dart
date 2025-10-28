import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:pinput/pinput.dart';

class SecurityCodeScreen extends StatefulWidget {
  const SecurityCodeScreen({super.key});

  @override
  State<SecurityCodeScreen> createState() => _SecurityCodeScreenState();
}

class _SecurityCodeScreenState extends State<SecurityCodeScreen> {
  String error = "";

  //TODO: Verify pin
  void verifyPin(String pin) {
    if (pin != '123456') {
      setState(() {
        error = "Incorrect pin.";
      });
    } else {
      setState(() {
        error = "";
      });
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
