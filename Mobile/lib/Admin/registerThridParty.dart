import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';

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
      age: 18,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Third Party Provider Registered Successfully!")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${adminCtrl.lastError.value}")),
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
        color: cs.primary,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // HEADER TEXT REMOVED (Replaced by GlobalAppBar Title)

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
                          validator: (val) => val != null && val.length < 6
                              ? "Password must be 6+ chars"
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Password',
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
          validator: (value) =>
              (value == null || value.isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(
            hintText: hint,
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
