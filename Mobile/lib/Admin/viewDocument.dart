import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/component/button.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDocumentWidget extends StatefulWidget {
  final DirectoryAccount merchantAccount;

  // ⚠️ Ensure this matches your actual server address (use 10.0.2.2 for Android Emulator)
  final String apiBaseUrl = "https://10.0.2.2:7077";

  const ViewDocumentWidget({super.key, required this.merchantAccount});

  @override
  State<ViewDocumentWidget> createState() => _ViewDocumentWidgetState();
}

class _ViewDocumentWidgetState extends State<ViewDocumentWidget> {
  final AdminController adminC = Get.find<AdminController>();
  String? fullDocumentUrl;
  String? fileNameDisplay;
  bool isLoading = true;
  bool hasDocument = false;

  @override
  void initState() {
    super.initState();
    _loadMerchantDetails();
  }

  void _loadMerchantDetails() async {
    if (widget.merchantAccount.merchantId != null) {
      // Fetch full details to get the doc URL
      Merchant? m =
          await adminC.getMerchantDetail(widget.merchantAccount.merchantId!);

      if (m != null &&
          m.merchantDocUrl != null &&
          m.merchantDocUrl!.isNotEmpty) {
        String rawUrl = m.merchantDocUrl!;
        String finalUrl;

        // ✅ LOGIC: If DB has a full link (https://...), use it directly.
        // If it has a relative path (/uploads/...), add the base URL.
        if (rawUrl.startsWith('http')) {
          finalUrl = rawUrl;
        } else {
          // Remove leading slash if present to avoid double slashes
          String cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
          finalUrl = "${widget.apiBaseUrl}$cleanPath";
        }

        setState(() {
          fullDocumentUrl = finalUrl;
          hasDocument = true;
          // ... rest of your code
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _launchDocument() async {
    if (fullDocumentUrl == null) return;
    final Uri url = Uri.parse(fullDocumentUrl!);

    // Use externalApplication mode to let the phone decide how to open PDF/Images
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
          "Error", "Could not launch document viewer for $fullDocumentUrl");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final account = widget.merchantAccount;
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
        child: SingleChildScrollView(
          // Use ScrollView to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // --- DOCUMENT CARD ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.file_present_rounded,
                            size: 64, color: Colors.blueGrey),
                        const SizedBox(height: 16),

                        Text(
                          isLoading
                              ? "Checking..."
                              : (hasDocument
                                  ? "Document Available"
                                  : "No Document Found"),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  hasDocument ? Colors.black87 : Colors.grey),
                        ),

                        const SizedBox(height: 8),

                        if (hasDocument)
                          Text(
                            fileNameDisplay ?? "Evidence.pdf",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline),
                          ),

                        const SizedBox(height: 24),

                        // VIEW BUTTON
                        if (hasDocument)
                          ViewDocumentButton(onPressed: _launchDocument),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- ACTION BUTTONS (Only for Pending) ---
                if (isPending)
                  Obx(() => adminC.isProcessing.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : DocumentDecisionRow(
                          onAccept: () async {
                            if (account.merchantId == null) return;
                            bool success = await adminC
                                .approveMerchant(account.merchantId!);
                            if (success) Get.back();
                          },
                          onReject: () async {
                            if (account.merchantId == null) return;

                            // Confirmation Dialog
                            Get.defaultDialog(
                                title: "Reject Merchant?",
                                middleText:
                                    "This will remove the application. This action cannot be undone.",
                                textConfirm: "Reject",
                                textCancel: "Cancel",
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.red,
                                onConfirm: () async {
                                  Get.back(); // close dialog
                                  bool success = await adminC
                                      .rejectMerchant(account.merchantId!);
                                  if (success) Get.back(); // go back to list
                                });
                          },
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
