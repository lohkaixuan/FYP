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

  // Determine if this is a pending applicant (User role) or approved (Merchant role)
  // Adjust logic if your directory list returns different role strings
  bool get isPending => widget.merchantAccount.role.toLowerCase() == 'user';

  @override
  void initState() {
    super.initState();
    // Load document immediately when page opens using the Merchant ID
    final mid = widget.merchantAccount.merchantId;
    if (mid != null) {
      adminC.fetchMerchantDocument(mid);
    } else {
      adminC.docErrorMessage.value =
          "Error: No Merchant ID found for this account.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: "Review Application",
      body: Column(
        children: [
          // --- 1. Document Viewer Section ---
          Expanded(
            child: Obx(() {
              // A. Loading State
              if (adminC.isDocLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text("Fetching Document...",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }

              // B. Error State
              if (adminC.docErrorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.white54),
                        const SizedBox(height: 16),
                        Text(
                          adminC.docErrorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // C. Success State (PDF Viewer)
              if (adminC.currentDocBytes.value != null) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SfPdfViewer.memory(
                      adminC.currentDocBytes.value!,
                      enableDoubleTapZooming: true,
                    ),
                  ),
                );
              }

              return const SizedBox(); // Fallback
            }),
          ),

          // --- 2. Action Buttons (Approve / Reject) ---
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Applicant: ${widget.merchantAccount.name}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (isPending) ...[
                  // PENDING STATE: Show Approve/Reject
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red,
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final mid = widget.merchantAccount.merchantId;
                              if (mid == null) return;

                              // Call Reject API
                              await adminC.rejectMerchant(mid);
                              Get.back(); // Close page
                            },
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final mid = widget.merchantAccount.merchantId;
                              if (mid == null) return;

                              // Call Approve API
                              await adminC.approveMerchant(mid);
                              Get.back(); // Close page
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Approve"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // APPROVED STATE: Show Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Account is already Active",
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
