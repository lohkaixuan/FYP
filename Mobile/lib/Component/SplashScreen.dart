import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Controller/tokenController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Component/AppTheme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Delay a bit for token load; hard cap at 5s to avoid hanging on splash.
    Future.delayed(const Duration(milliseconds: 400), _decideRoute);
    Future.delayed(const Duration(seconds: 5), _fallbackIfNeeded);
  }

  Future<void> _decideRoute() async {
    if (_navigated) return;
    final tokenCtrl = Get.find<TokenController>();
    final auth = Get.find<AuthController>();
    final roleC = Get.find<RoleController>();

    // Attempt to validate token by fetching /me
    try {
      await auth.ensureAuthenticated();
    } catch (_) {
      // swallow and fallback to login
    }

    final hasToken = tokenCtrl.token.value.isNotEmpty;
    final loggedIn = auth.isLoggedIn.value;

    if (hasToken && loggedIn) {
      final initial = roleC.nextInitialRoute();
      _navigate(initial);
    } else {
      _navigate('/login'); // Not logged in or token invalid
    }
  }

  void _fallbackIfNeeded() {
    if (_navigated) return;
    _navigate('/login');
  }

  void _navigate(String route) {
    if (_navigated) return;
    _navigated = true;
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/logo2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
