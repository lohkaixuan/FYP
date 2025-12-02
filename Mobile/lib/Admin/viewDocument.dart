import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDocumentWidget extends StatefulWidget {
  final DirectoryAccount merchantAccount;
  final String apiBaseUrl = "https://fyp-1-izlh.onrender.com";

  const ViewDocumentWidget({super.key, required this.merchantAccount});

  @override
  State<ViewDocumentWidget> createState() => _ViewDocumentWidgetState();
}

class _ViewDocumentWidgetState extends State<ViewDocumentWidget> {
  final AdminController adminC = Get.find<AdminController>();

  String? fullDocumentUrl;
  bool isLoading = true;
  String? errorMessage;
  bool isPending = false;

  // Role IDs from your AuthController.cs
  final String roleIdUser = "11111111-1111-1111-1111-111111111001";
  final String roleIdMerchant = "11111111-1111-1111-1111-111111111002";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? ownerId = widget.merchantAccount.ownerUserId;
    if (ownerId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "No Owner ID found.";
      });
      return;
    }

    try {
      // 1. Fetch User Details
      AppUser? user = await adminC.getUserDetail(ownerId);

      if (user != null) {
        // 2. Check Role ID directly from Database
        // 1001 = User (Pending), 1002 = Merchant (Approved)
        setState(() {
          if (user.roleId == roleIdUser) {
            isPending = true;
          } else if (user.roleId == roleIdMerchant) {
            isPending = false;
          } else {
            // Fallback: Check role name if ID logic fails
            isPending = user.roleName?.toLowerCase() == 'user';
          }
        });

        // 3. Get Document URL
        if (user.merchantDocUrl != null && user.merchantDocUrl!.isNotEmpty) {
          String rawUrl = user.merchantDocUrl!;
          String cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
          setState(() {
            fullDocumentUrl = "${widget.apiBaseUrl}$cleanPath";
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No document uploaded.";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "User details not found.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  Future<void> _downloadDocument() async {
    if (fullDocumentUrl == null) return;
    final Uri uri = Uri.parse(fullDocumentUrl!);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Error", "Could not open document link");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to launch: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: "Review Application",
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Center(child: _buildCenterContent()),
            ),

            // ✅ APPROVE / REJECT BUTTONS
            if (isPending) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await adminC.rejectMerchant(
                              widget.merchantAccount.merchantId!);
                          Get.back();
                          adminC.fetchDirectory(force: true);
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
                        ),
                        onPressed: () async {
                          await adminC.approveMerchant(
                              widget.merchantAccount.merchantId!);
                          Get.back();
                          adminC.fetchDirectory(force: true);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else if (!isLoading && !isPending && errorMessage == null) ...[
              // Already Approved View
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Already Approved",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    if (isLoading) return const CircularProgressIndicator();
    if (errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(errorMessage!, style: const TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration:
              BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
          child: Icon(Icons.description_rounded,
              size: 80, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 24),
        Text(widget.merchantAccount.name,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          isPending ? "Waiting for Approval" : "Account Active",
          style: TextStyle(color: isPending ? Colors.orange : Colors.green),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: _downloadDocument,
            icon: const Icon(Icons.download_rounded),
            label: const Text("Download Document to View"),
          ),
        ),
      ],
    );
  }
}
