import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/RoleController.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final auth = Get.find<AuthController>();
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();

  final _formKey = GlobalKey<FormState>();

  // Profile Fields
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  // Password Fields
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Visibility Toggles
  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = auth.user.value;
    
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = roleC.userId.value;
      final currentPassword = _currentPassCtrl.text.trim();
      final newPassword = _newPassCtrl.text.trim();

      
      try {
        
        final authResult = await api.login(
          email: auth.user.value?.email,
          password: currentPassword,
        );

        
        await auth.tokenC.saveToken(authResult.token);
      } catch (e) {
        Get.snackbar('Verification Failed', 'Current password is incorrect.',
            backgroundColor: Colors.red, colorText: Colors.white);
        setState(() => _isLoading = false);
        return;
      }

      
      
      if (_emailCtrl.text.trim() != auth.user.value?.email ||
          _phoneCtrl.text.trim() != auth.user.value?.phone) {
        await api.updateUser(userId, {
          
          
          'user_email': _emailCtrl.text.trim(),
          'user_phone_number': _phoneCtrl.text.trim(),
        });
      }

      
      
      if (newPassword.isNotEmpty) {
        await api.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      
      await auth.refreshMe(); 

      FocusScope.of(context).unfocus();

      Get.snackbar(
        'Success',
        'Profile updated successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2), 
        snackPosition: SnackPosition.BOTTOM, 
      );

      
      await Future.delayed(const Duration(milliseconds: 1000));

      Get.closeAllSnackbars();

      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      
      String errorMsg = 'Update failed';
      final data = e.response?.data;

      if (data is Map) {
        errorMsg = data['message']?.toString() ?? e.message ?? errorMsg;
      } else if (data is String && data.isNotEmpty) {
        errorMsg = data;
      } else {
        errorMsg = e.message ?? 'Unknown error';
      }

      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: const GlobalAppBar(title: 'Update Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === SECTION 1: Contact Info ===
              Text(
                'Contact Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    GetUtils.isEmail(v ?? '') ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  final phoneRegExp = RegExp(r'^\+?[0-9]{9,15}$');
                  return (v == null || v.length < 9 || !phoneRegExp.hasMatch(v)) ? 'Invalid phone number' : null;
                },
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // === SECTION 2: Security Verification (REQUIRED) ===
              Text(
                'Security Verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your current password to save changes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _currentPassCtrl,
                obscureText: !_showCurrentPass,
                decoration: InputDecoration(
                  labelText: 'Current Password (Required)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrentPass
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _showCurrentPass = !_showCurrentPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Required to verify identity';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // === SECTION 3: Change Password (OPTIONAL) ===
              ExpansionTile(
                title: const Text('Change Password'),
                subtitle:
                    const Text('Leave empty if you don\'t want to change it'),
                tilePadding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: !_showNewPass,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_showNewPass
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _showNewPass = !_showNewPass),
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 6) {
                        return 'Password must be at least 6 chars';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: !_showConfirmPass,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPass
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _showConfirmPass = !_showConfirmPass),
                      ),
                    ),
                    validator: (v) {
                      if (_newPassCtrl.text.isNotEmpty &&
                          v != _newPassCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // === Submit Button ===
              SizedBox(
                width: double.infinity,
                child: BrandGradientButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & Update'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
