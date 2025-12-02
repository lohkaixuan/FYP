import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/component/button.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart'; // Ensure AppUser is imported
import 'package:url_launcher/url_launcher.dart';

class ViewDocumentWidget extends StatefulWidget {
  final DirectoryAccount merchantAccount;

  // ✅ YOUR SERVER URL
  final String apiBaseUrl = "https://fyp-1-izlh.onrender.com";

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
    _loadDocumentFromUser();
  }

  // ✅ UPDATED FUNCTION: Fetch via User Endpoint
  void _loadDocumentFromUser() async {
    // 1. Get the Owner User ID
    String? ownerId = widget.merchantAccount.ownerUserId;

    if (ownerId != null) {
      // 2. Fetch the User Details (This calls GET /api/users/{id})
      // We rely on the backend update we made to UsersController to return 'merchant_doc_url'
      AppUser? user = await adminC.getUserDetail(ownerId);

      // 3. Check if we found the user and the document URL
      if (user != null &&
          user.merchantDocUrl != null &&
          user.merchantDocUrl!.isNotEmpty) {
        String rawUrl = user.merchantDocUrl!;
        String finalUrl;

        // Logic: Combine Base URL + Relative Path
        if (rawUrl.startsWith('http')) {
          finalUrl = rawUrl;
        } else {
          // Ensure path starts with /
          String cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
          finalUrl = "${widget.apiBaseUrl}$cleanPath";
        }

        setState(() {
          fullDocumentUrl = finalUrl;
          fileNameDisplay = rawUrl.split('/').last;
          hasDocument = true;
          isLoading = false;
        });
        print("✅ Document URL found: $fullDocumentUrl");
      } else {
        print("❌ No merchant_doc_url found in User object.");
        setState(() => isLoading = false);
      }
    } else {
      print("❌ No Owner User ID found on this account.");
      setState(() => isLoading = false);
    }
  }

  Future<void> _launchDocument() async {
    if (fullDocumentUrl == null) return;
    final Uri url = Uri.parse(fullDocumentUrl!);

    // Use externalApplication mode to let the phone handle PDF/Images
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch document viewer");
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // --- CARD ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        isLoading
                            ? "Loading..."
                            : (hasDocument
                                ? "Document Available"
                                : "No Document Found"),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (hasDocument)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(fileNameDisplay ?? "Evidence",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.blue)),
                        ),
                      const SizedBox(height: 24),
                      if (hasDocument)
                        ViewDocumentButton(onPressed: _launchDocument),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- ACTION BUTTONS (Only if Pending) ---
              if (isPending)
                Obx(() => adminC.isProcessing.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : DocumentDecisionRow(
                        onAccept: () async {
                          if (account.merchantId == null) return;
                          bool success =
                              await adminC.approveMerchant(account.merchantId!);
                          if (success) Get.back();
                        },
                        onReject: () async {
                          if (account.merchantId == null) return;
                          Get.defaultDialog(
                              title: "Reject Application",
                              middleText:
                                  "Are you sure you want to reject this merchant application?",
                              textConfirm: "Reject",
                              textCancel: "Cancel",
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red,
                              onConfirm: () async {
                                Get.back(); // Close dialog
                                bool success = await adminC
                                    .rejectMerchant(account.merchantId!);
                                if (success) Get.back(); // Return to list
                              });
                        },
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
