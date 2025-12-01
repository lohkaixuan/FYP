import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/component/button.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ViewDocumentWidget extends StatefulWidget {
  // Require the merchant account data to be passed in
  final DirectoryAccount merchantAccount;
  // You need your base API URL here to construct the full link to the uploaded file
  final String apiBaseUrl =
      "https://10.0.2.2:7077"; // REPLACE WITH YOUR ACTUAL API BASE URL

  const ViewDocumentWidget({super.key, required this.merchantAccount});

  @override
  State<ViewDocumentWidget> createState() => _ViewDocumentWidgetState();
}

class _ViewDocumentWidgetState extends State<ViewDocumentWidget> {
  final AdminController adminC = Get.find<AdminController>();
  String? fullDocumentUrl;
  bool hasDocument = false;

  @override
  void initState() {
    super.initState();
    _loadMerchantDetails();
  }

  // We need to fetch full merchant details because DirectoryAccount doesn't have the doc URL
  void _loadMerchantDetails() async {
    if (widget.merchantAccount.merchantId != null) {
      Merchant? m =
          await adminC.getMerchantDetail(widget.merchantAccount.merchantId!);
      if (m != null &&
          m.merchantDocUrl != null &&
          m.merchantDocUrl!.isNotEmpty) {
        setState(() {
          hasDocument = true;
          // Construct full URL. The backend stores relative paths like "/uploads/..."
          fullDocumentUrl = "${widget.apiBaseUrl}${m.merchantDocUrl}";
        });
      }
    }
  }

  Future<void> _launchDocument() async {
    if (fullDocumentUrl == null) return;
    final Uri url = Uri.parse(fullDocumentUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch document viewer");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final account = widget.merchantAccount;

    // Determine if already approved based on user role in the directory
    // If role is 'merchant', they are already approved. If 'user', they are pending.
    final bool isPending = account.role == 'user';

    return Scaffold(
      backgroundColor: cs.primary,
      appBar: AppBar(
        title: Text(account.name),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ... (Icon and Title styling same as before) ...
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              hasDocument
                                  ? 'Document Available'
                                  : 'No Document Found',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (hasDocument)
                              Text(
                                'Click below to view the uploaded documentation for ${account.name}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),

                            const SizedBox(height: 24),

                            // VIEW DOCUMENT BUTTON
                            if (hasDocument)
                              ViewDocumentButton(
                                onPressed: _launchDocument,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // APPROVE / REJECT BUTTONS
                  // Only show if the application is pending
                  if (isPending)
                    Obx(() => adminC.isProcessing.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : DocumentDecisionRow(
                            onAccept: () async {
                              if (account.merchantId == null) return;

                              // 1. Define 'success' on its own line
                              bool success = await adminC
                                  .approveMerchant(account.merchantId!);

                              // 2. Now 'success' is defined and can be checked
                              if (success) {
                                Get.back(); // Go back on success
                              }
                            },
                            onReject: () async {
                              if (account.merchantId == null) return;

                              // 1. Define 'success' on its own line
                              bool success = await adminC
                                  .rejectMerchant(account.merchantId!);

                              // 2. Now 'success' is defined and can be checked
                              if (success) {
                                Get.back(); // Go back on success
                              }
                            },
                          )),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
