import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalTabBar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mobile/Transfer/transfer.dart'; // TransferScreen + LockedRecipient
import 'package:mobile/Controller/auth.dart'; // AuthController
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Utils/api_dialogs.dart';

import 'QRUtlis.dart'; // TransferQrPayload / buildMyWalletQr / buildQrScanner / simpleScannerOverlay / WalletContact

<<<<<<< HEAD

enum QrTab { show, scan }


=======
/// QR tabs
enum QrTab { show, scan }

>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
class QrTabController extends GetxController {
  final Rx<QrTab> tab = QrTab.show.obs;
  void setTab(QrTab? t) {
    if (t != null) tab.value = t;
  }
}

<<<<<<< HEAD

=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
class QrSlideSwitch extends GetView<QrTabController> {
  const QrSlideSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isShow = controller.tab.value == QrTab.show;
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            globalTabBar(
              context,
              label: 'Show QR',
              selected: isShow,
              onTap: () => controller.setTab(QrTab.show),
            ),
            globalTabBar(
              context,
              label: 'Scanner',
              selected: !isShow,
              onTap: () => controller.setTab(QrTab.scan),
            ),
          ],
        ),
      );
    });
  }
}

<<<<<<< HEAD

=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
class QRComponent extends StatefulWidget {
  const QRComponent({super.key});

  @override
  State<QRComponent> createState() => _QRComponentState();
}

class _QRComponentState extends State<QRComponent> {
  final _scannerCtrl = MobileScannerController();
  late final QrTabController tabC;

  late final AuthController authController;
  late final RoleController roleController;
  late final TransactionController transactionController;

<<<<<<< HEAD
  bool _isHandlingScan = false; 

  
  WalletContact? _selfContact;
  bool _loadingSelf = true;

  
  
=======
  bool _isHandlingScan = false;
  WalletContact? _selfContact;
  bool _loadingSelf = true;

  /// Build QR payload based on active wallet (user/merchant)
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  String get myWalletQrPayload {
    final activeWalletId = roleController.activeWalletId.value.isNotEmpty
        ? roleController.activeWalletId.value
        : roleController.walletId;
    String walletType = 'user';
    if (activeWalletId == roleController.merchantWalletId.value &&
        activeWalletId.isNotEmpty) {
      walletType = 'merchant';
    } else if (roleController.activeRole.value == 'merchant') {
      walletType = 'merchant';
    }
    final contact = _selfContact;
    final user = authController.user.value;
    final username = contact?.username ?? user?.userName;

    // Debug log
    // ignore: avoid_print
    print(
        "[QR] build payload walletId=$activeWalletId walletType=$walletType activeRole=${roleController.activeRole.value}");

    return buildMyWalletQr(
      walletId: activeWalletId.isEmpty ? null : activeWalletId,
      walletType: walletType,
      phone: contact?.phone,
      email: contact?.email,
      username: (username == null || username.isEmpty) ? null : username,
    );
  }

  @override
  void initState() {
    super.initState();
    tabC = Get.put(QrTabController(), permanent: false);
    authController = Get.find<AuthController>();
    roleController = Get.find<RoleController>();
    transactionController = Get.find<TransactionController>();
<<<<<<< HEAD

    _loadSelfContact(); 
=======
    _loadSelfContact();
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  Future<void> _loadSelfContact() async {
    try {
      final user = authController.user.value;
      final baseQuery = user?.userName ?? '';
      if (baseQuery.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingSelf = false;
          });
        }
        return;
      }
<<<<<<< HEAD

      
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      final contact = await transactionController.lookupContact(baseQuery);
      if (!mounted) return;
      setState(() {
        _selfContact = contact;
        _loadingSelf = false;
      });
<<<<<<< HEAD
    } catch (e) {
      setState(() {
        _loadingSelf = false;
      });
      
    }
  }

  
=======
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSelf = false;
        });
      }
    }
  }

>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  void _handleScan(String raw) {
    if (_isHandlingScan) return;
    _isHandlingScan = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = TransferQrPayload.tryParse(raw);

      if (!mounted) {
        _isHandlingScan = false;
        return;
      }

      if (payload == null) {
        _showError('Invalid wallet QR');
        _isHandlingScan = false;
        return;
      }

<<<<<<< HEAD
      
=======
      // Prefer wallet_id from payload; fall back to phone/email/username
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      String? query;
      if (payload.phone != null && payload.phone!.isNotEmpty) {
        query = payload.phone;
      } else if (payload.email != null && payload.email!.isNotEmpty) {
        query = payload.email;
      } else if (payload.username != null && payload.username!.isNotEmpty) {
        query = payload.username;
      }

      await _scannerCtrl.stop();

      final contact = await transactionController.lookupContact(
        query ?? '',
        walletId: payload.walletId,
      );

      if (!mounted) {
        _isHandlingScan = false;
        return;
      }

      if (contact == null) {
        _showError('Recipient not found');
        _isHandlingScan = false;
        await _scannerCtrl.start();
        return;
      }

      if (payload.walletType != null) {
        contact.setActiveWalletType(payload.walletType!);
      }

      Get.to(
        () => TransferScreen(
          mode: 'transfer',
          lockedRecipient: LockedRecipient(
            walletId: contact.walletId,
            displayName: contact.displayName,
            phone: contact.phone ?? '-',
            walletType: payload.walletType ?? contact.activeWalletType,
          ),
        ),
      );

      _isHandlingScan = false;
    });
  }

  void _showError(String msg) {
    ApiDialogs.showError(
      msg,
      fallbackTitle: 'QR Error',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QrSlideSwitch(),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            if (tabC.tab.value == QrTab.show) {
              if (_loadingSelf) {
                return const Center(child: CircularProgressIndicator());
              }

              final payload = myWalletQrPayload;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: RepaintBoundary(
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 220,
                            gapless: true,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
<<<<<<< HEAD
                    const Text(
                      'Scanning this QR code will automatically direct others to your wallet account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      payload,
                      textAlign: TextAlign.center,
                    ),
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: payload));
                        if (context.mounted) {
                          ApiDialogs.showSuccess(
                            'Copied',
                            'Copied wallet QR payload',
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Payload'),
                    ),
                  ],
                ),
              );
            } else {
<<<<<<< HEAD
              
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
              return buildQrScanner(
                controller: _scannerCtrl,
                overlay: simpleScannerOverlay(size: 240),
                detectOnce: false,
                onDetect: _handleScan,
              );
            }
          }),
        ),
        const SizedBox(height: 6),
<<<<<<< HEAD
        Text(
          tabC.tab.value == QrTab.show
              ? 'Let others scan your QR code.'
              : 'Align the QR code inside the frame to scan.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      ],
    );
  }
}
