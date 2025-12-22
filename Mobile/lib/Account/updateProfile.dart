import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/api_dialogs.dart';

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
    // é¢„å¡«å…… Email å’Œ Phone
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

      // 1ï¸âƒ£ ç¬¬ä¸€æ­¥ï¼šéªŒè¯å½“å‰å¯†ç  (Verify Current Password)
      try {
        // ðŸ”¥ å…³é”®ä¿®æ”¹ï¼šèŽ·å– login è¿”å›žçš„æ–° Token
        final authResult = await api.login(
          email: auth.user.value?.email,
          password: currentPassword,
        );

        // âœ… é©¬ä¸Šä¿å­˜æ–° Tokenï¼å¦åˆ™æ—§ Token ä¼šå¤±æ•ˆï¼Œå¯¼è‡´åŽé¢çš„è¯·æ±‚æŠ¥ 401
        await auth.tokenC.saveToken(authResult.token);
      } catch (e) {
        ApiDialogs.showError(
          'Current password is incorrect.',
          fallbackTitle: 'Verification Failed',
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2ï¸âƒ£ ç¬¬äºŒæ­¥ï¼šæ›´æ–°åŸºæœ¬ä¿¡æ¯ (Email / Phone)
      // åªæœ‰å½“æœ‰å˜åŒ–æ—¶æ‰è°ƒç”¨
      if (_emailCtrl.text.trim() != auth.user.value?.email ||
          _phoneCtrl.text.trim() != auth.user.value?.phone) {
        await api.updateUser(userId, {
          // âœ… å¿…é¡»ç”¨ user_email / user_phone_number (snake_case)
          // âŒ ç»å¯¹ä¸è¦åœ¨è¿™é‡Œä¼  'password'ï¼ŒåŽç«¯ updateUser æŽ¥å£ä¸æ”¶å¯†ç ï¼
          'user_email': _emailCtrl.text.trim(),
          'user_phone_number': _phoneCtrl.text.trim(),
        });
      }

      // 3ï¸âƒ£ ç¬¬ä¸‰æ­¥ï¼šä¿®æ”¹å¯†ç  (Change Password)
      // åªæœ‰å½“ç”¨æˆ·å¡«äº†æ–°å¯†ç æ—¶ï¼Œæ‰è°ƒç”¨ä¸“é—¨çš„æ”¹å¯†ç æŽ¥å£
      if (newPassword.isNotEmpty) {
        await api.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      // 4ï¸âƒ£ æˆåŠŸæ”¶å°¾
      await auth.refreshMe(); // åˆ·æ–°æœ¬åœ°ç¼“å­˜
      ApiDialogs.showSuccess(
        'Success',
        'Profile updated successfully.',
        onConfirm: () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    } on DioException catch (e) {
      // âœ… ä¿®å¤ Crash çš„å…³é”®ï¼šå®‰å…¨åœ°è§£æžé”™è¯¯ä¿¡æ¯
      String errorMsg = 'Update failed';
      final data = e.response?.data;

      if (data is Map) {
        errorMsg = data['message']?.toString() ?? e.message ?? errorMsg;
      } else if (data is String && data.isNotEmpty) {
        errorMsg = data;
      } else {
        errorMsg = e.message ?? 'Unknown error';
      }

      ApiDialogs.showError(
        errorMsg,
        fallbackTitle: 'Update Failed',
      );
    } catch (e) {
      ApiDialogs.showError(
        'An unexpected error occurred.',
        fallbackTitle: 'Update Failed',
      );
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
