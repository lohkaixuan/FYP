import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mobile/Component/AppTheme.dart'; //
import 'package:mobile/Component/GradientWidgets.dart'; //

class ViewDocumentWidget extends StatefulWidget {
  final DirectoryAccount merchantAccount;

  const ViewDocumentWidget({super.key, required this.merchantAccount});

  @override
  State<ViewDocumentWidget> createState() => _ViewDocumentWidgetState();
}

class _ViewDocumentWidgetState extends State<ViewDocumentWidget> {
  final AdminController adminC = Get.find<AdminController>();

  bool isPending = true;
  bool isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  void _initLoad() async {
    final mid = widget.merchantAccount.merchantId;
    if (mid != null) {
      adminC.fetchMerchantDocument(mid);
    } else {
      adminC.docErrorMessage.value = "Error: No Merchant ID found.";
    }

    if (widget.merchantAccount.ownerUserId != null) {
      try {
        AppUser? owner =
            await adminC.getUserDetail(widget.merchantAccount.ownerUserId!);

        if (mounted && owner != null) {
          setState(() {
            if (owner.roleName?.toLowerCase() == 'merchant') {
              isPending = false;
            } else {
              isPending = true;
            }
            isCheckingStatus = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isCheckingStatus = false);
      }
    } else {
      if (mounted) setState(() => isCheckingStatus = false);
    }
  }

  // Helper: Check for PDF signature
  bool _isPdf(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return GlobalScaffold(
      title: "${widget.merchantAccount.name}'s Document",
      body: Column(
        children: [
          // ---------------- DOCUMENT VIEWER ----------------
          Expanded(
            child: Obx(() {
              if (adminC.isDocLoading.value) {
                return Center(
                    child: CircularProgressIndicator(color: cs.primary));
              }
              if (adminC.docErrorMessage.value.isNotEmpty) {
                return Center(
                    child: Text(adminC.docErrorMessage.value,
                        style: txt.bodyLarge?.copyWith(color: cs.error)));
              }
              final bytes = adminC.currentDocBytes.value;
              if (bytes != null && bytes.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Documents usually need white backing
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isPdf(bytes)
                        ? SfPdfViewer.memory(bytes)
                        : Image.memory(bytes, fit: BoxFit.contain),
                  ),
                );
              }
              // Empty State with Gradient Icon
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GradientIcon(Icons.description_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text("No Document Found",
                        style: txt.titleMedium?.copyWith(
                            color: cs.onBackground.withOpacity(0.6))),
                  ],
                ),
              );
            }),
          ),

          // ---------------- ACTION BAR ----------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface, // Matches system theme
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCheckingStatus)
                  Center(child: LinearProgressIndicator(color: cs.primary))
                else if (isPending)
                  // [Buttons State]
                  Row(
                    children: [
                      // REJECT BUTTON (Red)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cError,
                            foregroundColor: Colors.white, // White text
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rMd)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text("Reject",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => _handleReject(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // APPROVE BUTTON (Green)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cSuccess,
                            foregroundColor: Colors.white, // White text
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rMd)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text("Approve",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => _handleApprove(context),
                        ),
                      ),
                    ],
                  )
                else
                  // [Approved Badge State]
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: cs.outline.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.merchantAccount.isDeleted
                              ? Icons.cancel
                              : Icons.check_circle,
                          color: widget.merchantAccount.isDeleted
                              ? AppTheme.cError
                              : AppTheme.cSuccess,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.merchantAccount.isDeleted
                              ? "Application Rejected"
                              : "Merchant Approved",
                          style: txt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleReject(BuildContext context) async {
    final mid = widget.merchantAccount.merchantId;
    if (mid == null) return;

    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: const Text("Reject Application?"),
      content: const Text("This will soft-delete the merchant application."),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Confirm Reject",
                style: TextStyle(color: AppTheme.cError))),
      ],
    ));

    if (confirm == true) {
      final success = await adminC.rejectMerchant(mid);
      if (success) _initLoad();
    }
  }

  void _handleApprove(BuildContext context) async {
    final mid = widget.merchantAccount.merchantId;
    if (mid == null) return;

    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: const Text("Approve Merchant?"),
      content: const Text("Promote User to Merchant and create Wallet?"),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Approve", style: TextStyle(color: AppTheme.cSuccess))),
      ],
    ));

    if (confirm == true) {
      final success = await adminC.approveMerchant(mid);

      if (success) {
        Get.snackbar("Success", "Merchant Approved Successfully",
            backgroundColor: AppTheme.cSuccess,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 10);

        _initLoad();
      }
    }
  }
}
