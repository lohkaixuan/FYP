import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BottomNavController.dart'; // Import this to switch tabs

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

    // Logic: Passing "thridParty" as the dummy IC to satisfy backend DTO
    final success = await adminCtrl.registerThirdParty(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text,
      ic: "thridParty",
      age: 0,
    );

    if (success) {
      // 2. Success: Show Green Snackbar (Like Login)
      Get.snackbar(
        'Success',
        'Third Party Provider Registered Successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        duration: const Duration(seconds: 2),
      );

      // 3. Clear the form (Optional, but good UX)
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();

      // 4. Redirect to "Manage 3rd" Page
      // Based on BottomNav.dart, "Manage 3rd" is at Index 4
      final bottomNav = Get.find<BottomNavController>();
      bottomNav.changeIndex(4);
    } else {
      // 5. Failure: Show Red Snackbar (Like Login)
      Get.snackbar(
        'Registration Failed',
        adminCtrl.lastError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'Register Provider',
      body: Container(
        color: cs.primary, // Keeping your primary color background
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
                        label: 'Provider Name',
                        hint: 'Enter company name',
                        controller: nameController,
                        icon: Icons.business),
                    const SizedBox(height: 8),
                    _buildInputGroup(
                        label: 'Email Address',
                        hint: 'provider@company.com',
                        controller: emailController,
                        inputType: TextInputType.emailAddress,
                        autofill: [AutofillHints.email]),
                    const SizedBox(height: 8),
                    _buildInputGroup(
                        label: 'Phone Number',
                        hint: '+1 (555) 123-4567',
                        controller: phoneController,
                        inputType: TextInputType.phone,
                        autofill: [AutofillHints.telephoneNumber]),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !passwordVisible,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.black),
                          validator: (val) => val != null && val.length < 6
                              ? "Password must be 6+ character"
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.blue)),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => passwordVisible = !passwordVisible),
                              icon: Icon(
                                  passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final isLoading =
                    Get.find<AdminController>().isProcessing.value;
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 32, 0, 0),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : RegisterProviderButton(
                          text: "Register Provider",
                          onPressed: _handleRegistration),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup(
      {required String label,
      required String hint,
      required TextEditingController controller,
      TextInputType inputType = TextInputType.text,
      List<String>? autofill,
      IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          autofillHints: autofill,
          style: const TextStyle(color: Colors.black),
          validator: (value) =>
              (value == null || value.isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue)),
          ),
        ),
      ],
    );
  }
}
