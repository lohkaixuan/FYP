// File: lib/Admin/viewDocument.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
    // 1. Fetch Document
    final mid = widget.merchantAccount.merchantId;
    if (mid != null) {
      adminC.fetchMerchantDocument(mid);
    } else {
      adminC.docErrorMessage.value = "Error: No Merchant ID found.";
    }

    // 2. Check User Role (To decide if we show Approve buttons)
    if (widget.merchantAccount.ownerUserId != null) {
      try {
        AppUser? owner =
            await adminC.getUserDetail(widget.merchantAccount.ownerUserId!);

        if (mounted && owner != null) {
          setState(() {
            // If backend role is 'merchant', application is approved.
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

  // ✅ HELPER: Simple check for PDF Signature (%PDF)
  bool _isPdf(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: "${widget.merchantAccount.name}'s Document",
      body: Column(
        children: [
          // ==========================================
          // 1. DOCUMENT VIEWER
          // ==========================================
          Expanded(
            child: Obx(() {
              // LOADING STATE
              if (adminC.isDocLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text("Downloading Document...",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }

              // ERROR STATE
              if (adminC.docErrorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        Text(adminC.docErrorMessage.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }

              // SUCCESS STATE
              final bytes = adminC.currentDocBytes.value;
              if (bytes != null && bytes.isNotEmpty) {
                final bool isPdfFile = _isPdf(bytes);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isPdfFile
                        // Show PDF
                        ? SfPdfViewer.memory(bytes)
                        // Show Image (if uploaded as JPG/PNG)
                        : InteractiveViewer(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Text("Invalid Format",
                                          style: TextStyle(color: Colors.red))),
                            ),
                          ),
                  ),
                );
              }
              return const Center(
                  child: Text("No Document Found",
                      style: TextStyle(color: Colors.white)));
            }),
          ),

          // ==========================================
          // 2. ACTION BUTTONS
          // ==========================================
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCheckingStatus)
                  const Center(child: LinearProgressIndicator())
                else if (isPending)
                  Row(
                    children: [
                      // REJECT BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade900),
                          icon: const Icon(Icons.close),
                          label: const Text("Reject"),
                          onPressed: () => _handleReject(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // APPROVE BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: const Text("Approve"),
                          onPressed: () => _handleApprove(context),
                        ),
                      ),
                    ],
                  )
                else
                  // APPROVED BADGE
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            widget.merchantAccount.isDeleted
                                ? Icons.cancel
                                : Icons.check_circle,
                            color: widget.merchantAccount.isDeleted
                                ? Colors.redAccent
                                : Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(
                            widget.merchantAccount.isDeleted
                                ? "Rejected"
                                : "Merchant Approved",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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
      title: const Text("Reject Application?"),
      content: const Text("This will soft-delete the merchant application."),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Confirm Reject",
                style: TextStyle(color: Colors.red))),
      ],
    ));

    if (confirm == true) {
      final success = await adminC.rejectMerchant(mid);
      if (success) {
        Get.back(); // Close Page
        // Note: adminController already shows snackbar for rejection
      }
    }
  }

  void _handleApprove(BuildContext context) async {
    final mid = widget.merchantAccount.merchantId;
    if (mid == null) return;

    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text("Approve Merchant?"),
      content: const Text("Promote User to Merchant and create Wallet?"),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () => Get.back(result: true),
            child:
                const Text("Approve", style: TextStyle(color: Colors.green))),
      ],
    ));

    if (confirm == true) {
      final success = await adminC.approveMerchant(mid);

      if (success) {
        Get.back(); // Close Page

        // ✅ ADDED SNACKBAR
        Get.snackbar("Success", "Merchant Approved Successfully",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
      }
    }
  }
}
