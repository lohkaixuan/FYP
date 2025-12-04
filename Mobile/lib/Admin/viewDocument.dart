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
          // 🛑 DEBUG: LOOK AT YOUR CONSOLE LOGS
          print("========================================");
          print("DEBUG: Fetching User from Server...");
          print("User ID: ${owner.userId}");
          print(
              "Role Name from Server: '${owner.roleName}'"); // <--- This will likely be 'null'
          print("========================================");

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
    return GlobalScaffold(
      title: "${widget.merchantAccount.name}'s Document",
      body: Column(
        children: [
          // ---------------- DOCUMENT VIEWER ----------------
          Expanded(
            child: Obx(() {
              if (adminC.isDocLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              if (adminC.docErrorMessage.value.isNotEmpty) {
                return Center(
                    child: Text(adminC.docErrorMessage.value,
                        style: const TextStyle(color: Colors.white)));
              }
              final bytes = adminC.currentDocBytes.value;
              if (bytes != null && bytes.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isPdf(bytes)
                        ? SfPdfViewer.memory(bytes)
                        : Image.memory(bytes, fit: BoxFit.contain),
                  ),
                );
              }
              return const Center(
                  child: Text("No Document Found",
                      style: TextStyle(color: Colors.white)));
            }),
          ),

          // ---------------- ACTION BAR ----------------
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCheckingStatus)
                  const Center(child: LinearProgressIndicator())
                else if (isPending)
                  // [Buttons State]
                  Row(
                    children: [
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
                  // [Approved Badge State]
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
                                ? "Application Rejected"
                                : "Merchant Approved",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
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
      if (success) _initLoad();
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
        // 1. Show Success Message
        Get.snackbar("Success", "Merchant Approved Successfully",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);

        // 2. ✅ CRITICAL: Do NOT go back. Refresh the state to show the badge.
        _initLoad();
      }
    }
  }
}
