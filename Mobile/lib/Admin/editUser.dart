import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/Admin/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/AppTheme.dart'; //
import 'package:mobile/Component/GradientWidgets.dart'; //

class EditUserWidget extends StatefulWidget {
  final DirectoryAccount account; // Passed from the list

  const EditUserWidget({super.key, required this.account});

  @override
  State<EditUserWidget> createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends State<EditUserWidget> {
  final _formKey = GlobalKey<FormState>();

  // ===============================================
  // 1. CONTROLLERS
  // ===============================================
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController icController = TextEditingController();

  final TextEditingController merchantNameController = TextEditingController();
  final TextEditingController merchantPhoneController = TextEditingController();

  final TextEditingController baseUrlController = TextEditingController();
  bool providerEnabled = true;

  final AdminController adminCtrl = Get.find<AdminController>();
  bool _isLoadingDetails = true;

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
    setState(() => _isLoadingDetails = true);

    final targetUserId = widget.account.ownerUserId ?? widget.account.id;
    final user = await adminCtrl.getUserDetail(targetUserId);

    if (user != null && mounted) {
      nameController.text = user.userName;
      emailController.text = user.email;
      phoneController.text = user.phone;
      ageController.text = user.age?.toString() ?? '';
      icController.text = user.icNumber ?? '';

      if (isMerchant) {
        merchantNameController.text = user.merchantName ?? '';
        merchantPhoneController.text = user.merchantPhoneNumber ?? '';
      }

      if (isProvider) {
        baseUrlController.text = user.providerBaseUrl ?? '';
        if (user.providerEnabled != null) {
          setState(() {
            providerEnabled = user.providerEnabled!;
          });
        }
      }
    }

    if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
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

    final success = await adminCtrl.updateUserAccountInfo(
      targetUserId: targetUserId,
      role: role,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      age: int.tryParse(ageController.text) ?? 0,
      icNumber: icController.text.trim(),
      merchantName: isMerchant ? merchantNameController.text.trim() : null,
      merchantPhone: isMerchant ? merchantPhoneController.text.trim() : null,
      providerBaseUrl: isProvider ? baseUrlController.text.trim() : null,
      providerEnabled: isProvider ? providerEnabled : null,
    );

    if (success && mounted) {
      Get.snackbar("Success", "Account Updated Successfully!",
          backgroundColor: AppTheme.cSuccess, colorText: Colors.white);
      Navigator.pop(context);
    } else if (mounted) {
      Get.snackbar("Failed", adminCtrl.lastError.value,
          backgroundColor: AppTheme.cError, colorText: Colors.white);
    }
  }

  // ===============================================
  // 4. UI BUILD
  // ===============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: GlobalScaffold(
        title: 'Edit ${widget.account.role.capitalizeFirst}',
        body: Container(
          // FIXED: Removed 'color: cs.primary' to use default theme background
          width: double.infinity,
          height: double.infinity,
          child: _isLoadingDetails
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ----------------------------------------
                          // SECTION A: BUSINESS DETAILS (Merchant Only)
                          // ----------------------------------------
                          if (isMerchant) ...[
                            Text(
                              "Business Details",
                              style: txt.titleLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              context,
                              label: 'Business Name',
                              hint: 'e.g. Burger King',
                              controller: merchantNameController,
                              icon: Icons.store,
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              context,
                              label: 'Business Phone',
                              hint: '+1 234 ...',
                              controller: merchantPhoneController,
                              inputType: TextInputType.phone,
                              icon: Icons.phone_in_talk,
                            ),
                            const SizedBox(height: 24),
                            Divider(color: cs.outline.withOpacity(0.5)),
                            const SizedBox(height: 16),
                          ],

                          // ----------------------------------------
                          // SECTION B: PERSONAL / OWNER DETAILS
                          // ----------------------------------------
                          Text(
                            isMerchant ? "Owner Details" : "Personal Details",
                            style: txt.titleLarge?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          _buildInputGroup(
                            context,
                            label: 'Full Name',
                            hint: 'Owner Real Name',
                            controller: nameController,
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),

                          _buildInputGroup(
                            context,
                            label: 'Email',
                            hint: 'email@example.com',
                            controller: emailController,
                            inputType: TextInputType.emailAddress,
                            icon: Icons.email,
                          ),
                          const SizedBox(height: 16),

                          _buildInputGroup(
                            context,
                            label: isMerchant ? 'Owner Phone' : 'Phone Number',
                            hint: '+1 234 567 890',
                            controller: phoneController,
                            inputType: TextInputType.phone,
                            icon: Icons.phone_android,
                          ),
                          const SizedBox(height: 16),

                          _buildInputGroup(
                            context,
                            label: 'Age',
                            hint: '18',
                            controller: ageController,
                            inputType: TextInputType.number,
                            icon: Icons.cake,
                          ),
                          const SizedBox(height: 16),

                          _buildInputGroup(
                            context,
                            label: 'IC Number',
                            hint: '000000-00-0000',
                            controller: icController,
                            icon: Icons.badge,
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
                            Divider(color: cs.outline.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              "Provider Configuration",
                              style: txt.titleLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            _buildInputGroup(
                              context,
                              label: 'Base URL',
                              hint: 'https://api.provider.com',
                              controller: baseUrlController,
                              icon: Icons.link,
                              inputType: TextInputType.url,
                            ),
                            const SizedBox(height: 16),

                            // Switch Card with Theme Styling
                            Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rMd),
                                border: Border.all(
                                    color: cs.outline.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.power_settings_new,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Service Status",
                                              style: txt.titleMedium?.copyWith(
                                                color: cs.onSurface,
                                                fontWeight: FontWeight.w600,
                                              )),
                                          Text(
                                            providerEnabled
                                                ? "Active"
                                                : "Disabled",
                                            style: txt.labelSmall?.copyWith(
                                              color: providerEnabled
                                                  ? AppTheme.cSuccess
                                                  : AppTheme.cError,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: providerEnabled,
                                    activeColor: Colors.white,
                                    activeTrackColor: AppTheme.cSuccess,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: cs.surfaceVariant,
                                    trackOutlineColor:
                                        MaterialStateProperty.all(
                                            Colors.transparent),
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

                          const SizedBox(height: 40),

                          // UPDATE BUTTON
                          Obx(() {
                            final isLoading = adminCtrl.isProcessing.value;
                            return isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: cs.primary))
                                : BrandGradientButton(
                                    height: 50,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.rMd),
                                    onPressed: _handleUpdate,
                                    child: const Text("Save Changes",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Helper Widget for Text Fields
  Widget _buildInputGroup(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    bool readOnly = false,
    String? helperText,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: txt.titleSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
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

            final v = value?.trim() ?? '';

            if (label == 'Email') {
              if (!GetUtils.isEmail(v)) {
                return 'Please enter a valid email address.';
              }
            } else if (label == 'Age') {
              final age = int.tryParse(v);
              if (age == null || age <= 0 || age > 150) {
                return 'Please enter a valid age (1-150).';
              }
            } else if (label.contains('Phone')) {
              final phoneRegExp = RegExp(r'^\+?[0-9]{9,15}$');
              if (!phoneRegExp.hasMatch(v)){
                return 'Please enter a valid phone number.';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            helperText: helperText,
            helperStyle: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            prefixIcon:
                icon != null ? Icon(icon, color: cs.onSurfaceVariant) : null,
            filled: true,
            fillColor:
                readOnly ? cs.surfaceVariant.withOpacity(0.5) : cs.surface,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 2),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: cs.error),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: cs.error),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
          ),
          style: txt.bodyLarge?.copyWith(
            color: readOnly ? cs.onSurface.withOpacity(0.6) : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
