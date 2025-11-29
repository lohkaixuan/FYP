import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';

class EditUserWidget extends StatefulWidget {
  final DirectoryAccount account; // Passed from the list

  const EditUserWidget({super.key, required this.account});

  @override
  State<EditUserWidget> createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends State<EditUserWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  // ===============================================
  // 1. CONTROLLERS
  // ===============================================

  // --- A. User / Owner Personal Data ---
  final TextEditingController nameController =
      TextEditingController(); // Owner Name
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(); // Owner Phone
  final TextEditingController ageController = TextEditingController();
  final TextEditingController icController = TextEditingController();

  // --- B. Merchant Business Data ---
  final TextEditingController merchantNameController =
      TextEditingController(); // Business Name
  final TextEditingController merchantPhoneController =
      TextEditingController(); // Business Phone

  // --- C. Provider Data ---
  final TextEditingController baseUrlController = TextEditingController();
  bool providerEnabled = true; // Default to true

  final AdminController adminCtrl = Get.find<AdminController>();
  bool _isLoadingDetails = true;

  // Helpers to identify Role
  bool get isMerchant => widget.account.role.toLowerCase() == 'merchant';
  bool get isProvider =>
      widget.account.role.toLowerCase() == 'provider' ||
      widget.account.role.toLowerCase() == 'thirdparty';

  @override
  void initState() {
    super.initState();
    _loadFullDetails();
  }

  // ===============================================
  // 2. DATA LOADING
  // ===============================================
  void _loadFullDetails() async {
    // ID Logic:
    // User -> id is userId
    // Merchant/Provider -> id is merchantId/providerId, ownerUserId is userId
    final targetUserId = widget.account.ownerUserId ?? widget.account.id;
    final targetEntityId = widget.account.id;

    // A. Load User Details (Owner)
    final user = await adminCtrl.getUserDetail(targetUserId);

    if (user != null && mounted) {
      nameController.text = user.userName;
      emailController.text = user.email;
      phoneController.text = user.phone;
      ageController.text = user.age?.toString() ?? '';
      icController.text = user.icNumber ?? '';
    }

    // B. Load Merchant Details (If Merchant)
    if (isMerchant && widget.account.merchantId != null) {
      final merchant =
          await adminCtrl.getMerchantDetail(widget.account.merchantId!);
      if (merchant != null && mounted) {
        merchantNameController.text = merchant.merchantName;
        merchantPhoneController.text = merchant.merchantPhoneNumber ?? '';
      }
    }

    // C. Load Provider Details (If Provider)
    if (isProvider) {
      final provider = await adminCtrl.getThirdPartyDetail(targetEntityId);
      if (provider != null && mounted) {
        baseUrlController.text = provider.baseUrl ?? '';
        setState(() {
          providerEnabled = provider.enabled;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ageController.dispose();
    icController.dispose();
    merchantNameController.dispose();
    merchantPhoneController.dispose();
    baseUrlController.dispose();
    super.dispose();
  }

  // ===============================================
  // 3. UPDATE LOGIC
  // ===============================================
  void _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final targetUserId = widget.account.ownerUserId ?? widget.account.id;
    final role = widget.account.role.toLowerCase();

    bool success = true;

    // --- STEP 1: Update User Table (Owner Info) ---
    // Note: The backend may return "No changes detected" (200 OK) if only business/provider details changed.
    final userSuccess = await adminCtrl.updateUserAccountInfo(
      targetUserId: targetUserId,
      role: role,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      age: int.tryParse(ageController.text) ?? 0,
      icNumber: icController.text.trim(),
    );

    if (!userSuccess) success = false;

    // --- STEP 2: Update Merchant Table (Business Info) ---
    // Only runs if Step 1 succeeded (or returned "no changes" success)
    if (isMerchant && widget.account.merchantId != null && success) {
      final merchantSuccess = await adminCtrl.editMerchant(
        widget.account.merchantId!,
        {
          'merchant_name': merchantNameController.text.trim(),
          'merchant_phone_number': merchantPhoneController.text.trim(),
        },
      );
      if (!merchantSuccess) success = false;
    }

    // --- STEP 3: Update Provider Table (Config) ---
    if (isProvider && success) {
      final providerSuccess = await adminCtrl.editThirdParty(
        widget.account.id,
        {
          'base_url': baseUrlController.text.trim(),
          'enabled': providerEnabled,
        },
      );
      if (!providerSuccess) success = false;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Updated Successfully!")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${adminCtrl.lastError.value}")),
      );
    }
  }

  // ===============================================
  // 4. UI BUILD
  // ===============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: cs.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit ${widget.account.role.capitalizeFirst}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: _isLoadingDetails
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ----------------------------------------
                              // SECTION A: BUSINESS DETAILS (Merchant Only)
                              // ----------------------------------------
                              if (isMerchant) ...[
                                const Text(
                                  "Business Details",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                _buildInputGroup(
                                  label: 'Business Name',
                                  hint: 'e.g. Burger King',
                                  controller: merchantNameController,
                                  icon: Icons.store,
                                ),
                                const SizedBox(height: 16),
                                _buildInputGroup(
                                  label: 'Business Phone',
                                  hint: '+1 234 ...',
                                  controller: merchantPhoneController,
                                  inputType: TextInputType.phone,
                                  icon: Icons.phone_in_talk,
                                ),
                                const SizedBox(height: 24),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                              ],

                              // ----------------------------------------
                              // SECTION B: PERSONAL / OWNER DETAILS
                              // ----------------------------------------
                              Text(
                                isMerchant
                                    ? "Owner Details"
                                    : "Personal Details",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),

                              _buildInputGroup(
                                label: 'Full Name',
                                hint: 'Owner Real Name',
                                controller: nameController,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),

                              _buildInputGroup(
                                label: 'Email',
                                hint: 'email@example.com',
                                controller: emailController,
                                inputType: TextInputType.emailAddress,
                                icon: Icons.email,
                              ),
                              const SizedBox(height: 16),

                              _buildInputGroup(
                                label:
                                    isMerchant ? 'Owner Phone' : 'Phone Number',
                                hint: '+1 234 567 890',
                                controller: phoneController,
                                inputType: TextInputType.phone,
                                icon: Icons.phone_android,
                              ),
                              const SizedBox(height: 16),

                              _buildInputGroup(
                                label: 'Age',
                                hint: '18',
                                controller: ageController,
                                inputType: TextInputType.number,
                                icon: Icons.cake,
                              ),
                              const SizedBox(height: 16),

                              _buildInputGroup(
                                label: 'IC Number',
                                hint: '000000-00-0000',
                                controller: icController,
                                icon: Icons.badge,
                                // Provider IC is ReadOnly
                                readOnly: isProvider,
                                helperText: isProvider
                                    ? "Providers cannot change IC Number"
                                    : null,
                              ),

                              // ----------------------------------------
                              // SECTION C: PROVIDER CONFIG (Provider Only)
                              // ----------------------------------------
                              if (isProvider) ...[
                                const SizedBox(height: 24),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                                const Text(
                                  "Provider Configuration",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),

                                _buildInputGroup(
                                  label: 'Base URL',
                                  hint: 'https://api.provider.com',
                                  controller: baseUrlController,
                                  icon: Icons.link,
                                  inputType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),

                                // Custom Switch for Enabled Status
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.power_settings_new,
                                              color: Colors.grey),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Service Status",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                providerEnabled
                                                    ? "Active"
                                                    : "Disabled",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: providerEnabled
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: providerEnabled,
                                        activeThumbColor: Colors.green,
                                        activeTrackColor: Colors.green.shade100,
                                        inactiveThumbColor: Colors.red,
                                        inactiveTrackColor: Colors.red.shade100,
                                        onChanged: (val) {
                                          setState(() {
                                            providerEnabled = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // UPDATE BUTTON
                        Obx(() {
                          final isLoading = adminCtrl.isProcessing.value;
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading ? null : _handleUpdate,
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text("Save Changes",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),
                          );
                        }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Helper Widget for Text Fields
  Widget _buildInputGroup({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          readOnly: readOnly,
          validator: (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperStyle: const TextStyle(color: Colors.white70),
            prefixIcon: icon != null
                ? Icon(icon, color: readOnly ? Colors.grey : Colors.grey[600])
                : null,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            // Grey out if readOnly
            fillColor: readOnly ? Colors.grey[300] : Colors.white,
          ),
          style: TextStyle(
              color: readOnly ? Colors.grey[700] : Colors.black, fontSize: 16),
        ),
      ],
    );
  }
}
