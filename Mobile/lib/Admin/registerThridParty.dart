import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/Admin/adminController.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Component/AppTheme.dart'; //
import 'package:mobile/Component/GradientWidgets.dart'; //
import 'package:mobile/Utils/api_dialogs.dart';

class RegisterProviderWidget extends StatefulWidget {
  const RegisterProviderWidget({super.key});

  @override
  State<RegisterProviderWidget> createState() => _RegisterProviderWidgetState();
}

class _RegisterProviderWidgetState extends State<RegisterProviderWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final adminCtrl = Get.find<AdminController>();

    final success = await adminCtrl.registerThirdParty(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text,
      ic: "thridParty",
      age: 0,
    );

    if (success) {
      ApiDialogs.showSuccess(
        'Success',
        'Third Party Provider Registered Successfully!',
        onConfirm: () {
          nameController.clear();
          emailController.clear();
          phoneController.clear();
          passwordController.clear();
          final bottomNav = Get.find<BottomNavController>();
          bottomNav.changeIndex(4);
        },
      );
    } else {
      ApiDialogs.showError(
        adminCtrl.lastError.value,
        fallbackTitle: 'Registration Failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return GlobalScaffold(
      title: 'Register Provider',
      body: Container(
        // FIXED: Removed 'color: cs.primary' to use default theme background
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    _buildInputGroup(
                      context,
                      label: 'Provider Name',
                      hint: 'Enter company name',
                      controller: nameController,
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),
                    _buildInputGroup(
                      context,
                      label: 'Email Address',
                      hint: 'provider@company.com',
                      controller: emailController,
                      inputType: TextInputType.emailAddress,
                      autofill: [AutofillHints.email],
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildInputGroup(
                      context,
                      label: 'Phone Number',
                      hint: '+1 (555) 123-4567',
                      controller: phoneController,
                      inputType: TextInputType.phone,
                      autofill: [AutofillHints.telephoneNumber],
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password',
                            style: txt.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !passwordVisible,
                          textInputAction: TextInputAction.done,
                          style: txt.bodyMedium?.copyWith(color: cs.onSurface),
                          validator: (val) => val != null && val.length < 6
                              ? "Password must be 6+ character"
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            hintStyle: txt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: cs.surface,
                            prefixIcon: Icon(Icons.lock_outline,
                                color: cs.onSurfaceVariant),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                              borderSide: BorderSide(
                                  color: cs.outline.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                              borderSide: BorderSide(color: cs.primary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                              borderSide: BorderSide(color: cs.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                              borderSide: BorderSide(color: cs.error),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => passwordVisible = !passwordVisible),
                              icon: Icon(
                                passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Obx(() {
                final isLoading =
                    Get.find<AdminController>().isProcessing.value;
                return isLoading
                    ? CircularProgressIndicator(color: cs.primary)
                    : BrandGradientButton(
                        height: 48,
                        borderRadius: BorderRadius.circular(AppTheme.rMd),
                        onPressed: _handleRegistration,
                        child: const Text(
                          "Register Provider",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    List<String>? autofill,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: txt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          autofillHints: autofill,
          style: txt.bodyMedium?.copyWith(color: cs.onSurface),
          validator: (value) =>
              (value == null || value.isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: txt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            prefixIcon:
                icon != null ? Icon(icon, color: cs.onSurfaceVariant) : null,
            filled: true,
            fillColor: cs.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              borderSide: BorderSide(color: cs.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              borderSide: BorderSide(color: cs.error),
            ),
          ),
        ),
      ],
    );
  }
}
