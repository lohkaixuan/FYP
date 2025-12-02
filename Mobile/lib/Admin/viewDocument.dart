import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // 📦 Add this package!

class ViewDocumentWidget extends StatefulWidget {
  final DirectoryAccount merchantAccount;

  // ✅ Your Render URL
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
  bool isPdf = false;

  @override
  void initState() {
    super.initState();
    _loadDocumentFromUser();
  }

  void _loadDocumentFromUser() async {
    String? ownerId = widget.merchantAccount.ownerUserId;

    if (ownerId != null) {
      // Fetch User Details to get the URL
      AppUser? user = await adminC.getUserDetail(ownerId);

      if (user != null &&
          user.merchantDocUrl != null &&
          user.merchantDocUrl!.isNotEmpty) {
        String rawUrl = user.merchantDocUrl!;
        String finalUrl;

        // Construct Full URL
        if (rawUrl.startsWith('http')) {
          finalUrl = rawUrl;
        } else {
          String cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
          finalUrl = "${widget.apiBaseUrl}$cleanPath";
        }

        setState(() {
          fullDocumentUrl = finalUrl;
          fileNameDisplay = rawUrl.split('/').last;
          hasDocument = true;
          // Simple check: does filename end with .pdf?
          isPdf = fileNameDisplay!.toLowerCase().endsWith('.pdf');
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // Opens in external browser (Fallback)
  Future<void> _launchExternal() async {
    if (fullDocumentUrl == null) return;
    final Uri url = Uri.parse(fullDocumentUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch document");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final account = widget.merchantAccount;
    final bool isPending = account.role == 'user';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text("Review: ${account.name}"),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        actions: [
          // External Open Button (Top Right)
          if (hasDocument)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: "Open in Browser",
              onPressed: _launchExternal,
            )
        ],
      ),
      body: Column(
        children: [
          // --- DOCUMENT VIEWER AREA ---
          Expanded(
            child: Container(
              color: Colors.grey.shade200, // Background for the viewer
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasDocument
                      ? _buildNoDocumentState()
                      : _buildDocumentViewer(),
            ),
          ),

          // --- ADMIN ACTION BUTTONS ---
          if (isPending && !isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ]),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _confirmReject(account.merchantId),
                        child: const Text("Reject Application"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (account.merchantId == null) return;
                          bool success =
                              await adminC.approveMerchant(account.merchantId!);
                          if (success) Get.back();
                        },
                        child: const Text("Approve Merchant"),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  // 📄 The Integrated Viewer (Like Report Page)
  Widget _buildDocumentViewer() {
    if (isPdf) {
      // PDF Viewer (Requires syncfusion_flutter_pdfviewer)
      return SfPdfViewer.network(
        fullDocumentUrl!,
        onDocumentLoadFailed: (args) {
          Get.snackbar("Error", "Failed to load PDF preview");
        },
      );
    } else {
      // Image Viewer
      return InteractiveViewer(
        child: Image.network(
          fullDocumentUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text("Failed to load image"));
          },
        ),
      );
    }
  }

  Widget _buildNoDocumentState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No Document Found",
              style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmReject(String? merchantId) {
    if (merchantId == null) return;
    Get.defaultDialog(
        title: "Reject Application",
        middleText:
            "Are you sure you want to reject this application? This cannot be undone.",
        textConfirm: "Reject",
        textCancel: "Cancel",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () async {
          Get.back();
          bool success = await adminC.rejectMerchant(merchantId);
          if (success) Get.back();
        });
  }
}
