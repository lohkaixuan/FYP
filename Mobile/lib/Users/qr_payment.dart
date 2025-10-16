import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BackButton(
                    color: Colors.black,
                    style: ButtonStyle(
                      fixedSize: WidgetStateProperty.all(Size(20, 20)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'QR Payment',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TabBar(
                tabs: [
                  Tab(text: 'Scan QR'),
                  Tab(text: 'My QR Code'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ScanQrWidget(),
                    MyQrWidget(
                      data: 'https://example.com',
                    ), // TODO: Place QR Code information here.
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanQrWidget extends StatefulWidget {
  const ScanQrWidget({super.key});

  @override
  State<ScanQrWidget> createState() => _ScanQrWidgetState();
}

class _ScanQrWidgetState extends State<ScanQrWidget> {
  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          !isClicked
              ? AspectRatio(
                  aspectRatio: 1,
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      radius: Radius.circular(15),
                      color: Colors.grey,
                      strokeWidth: 2,
                    ),
                    child: Center(
                      child: Text('Position the QR code within this area.'),
                    ),
                  ),
                )
              : SizedBox(
                  height: 300,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isEmpty) {
                        debugPrint('Failed to scan QR Code');
                      } else {
                        for (final barcode in barcodes) {
                          debugPrint('QR Code found: ${barcode.rawValue}');
                          // TODO: Handle payment processing here.
                        }
                      }
                    },
                  ),
                ),
          SizedBox(height: 20),
          !isClicked
              ? ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isClicked = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Scan QR Code'),
                )
              : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isClicked = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Stop Scan'),
                ),
        ],
      ),
    );
  }
}

class MyQrWidget extends StatelessWidget {
  final String data;
  const MyQrWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: EdgeInsets.all(15),
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: PrettyQrView.data(
            data: data,
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSquaresSymbol(),
            ),
          ),
        ),
      ),
    );
  }
}
