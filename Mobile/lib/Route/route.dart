import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Account/Account.dart';
import 'package:mobile/Account/ChangePin.dart';
import 'package:mobile/Account/updateMerchant.dart';
import 'package:mobile/Account/updateProfile.dart';
import 'package:mobile/Auth/registerMerchant.dart';
import 'package:mobile/Budget/create_budget.dart';
import 'package:mobile/Transfer/SecurityCode.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart';
import 'package:mobile/Auth/register.dart';
import 'package:mobile/Component/BottomNav.dart';
import 'package:mobile/NFC/nfc_pay.dart';
import 'package:mobile/QR/QRpage.dart';
import 'package:mobile/Home/chart_details.dart';
import 'package:mobile/Reload/reload.dart';
import 'package:mobile/Transaction/Transactionpage.dart';
import 'package:mobile/Transaction/transaction_details.dart';
import 'package:mobile/Transfer/transfer.dart';
import 'package:mobile/ThirdParty/providerReport.dart';
import 'package:mobile/ThirdParty/providerDashboard.dart';
import 'package:mobile/ThirdParty/providerAPI.dart';
import 'package:mobile/ThirdParty/providerProfile.dart';
import 'package:mobile/Bank/link_provider.dart';

class AppPages {
  static const INITIAL = '/splash';

  static final routes = <GetPage>[
    // 🔹 Splash & Auth
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/signup', page: () => const Register()),

    
    GetPage(
      name: '/home',
      page: () => const BottomNavApp(),
      children: [
        
        GetPage(
          name: '/debit-credit-details',
          page: () => ChartDetails(
            title: "Debit and Credit Details",
            onTapItem: (item) {
              Get.to(
                () => const Transactions(),
                arguments: {"filter": item['title'].toLowerCase()},
              );
            },
          ),
        ),
        GetPage(
          name: '/spendingDetails',
          page: () => ChartDetails(
            title: "Spending Details",
            onTapItem: (item) {
              Get.to(
                () => const Transactions(),
                arguments: {"filter": item['title'].toLowerCase()},
              );
            },
          ),
        ),
        GetPage(
          name: '/budget-details',
          page: () => ChartDetails(
            title: "Budget Details",
            iconButton: IconButton(
              onPressed: () => Get.to(const CreateBudgetScreen()),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    ),

    
    GetPage(
      name: '/reload',
      page: () => ReloadScreen(),
    ),
    GetPage(
      name: '/pay',
      page: () => const QR(),
    ),
    GetPage(
      name: '/pay/nfc',
      page: () => const NfcPayPage(),
    ),
    GetPage(
      name: '/security-code',
      page: () {
        final tx = Get.arguments as TransferDetails;
        return SecurityCodeScreen(data: tx);
      },
    ),
    GetPage(
      name: '/transfer',
      page: () => TransferScreen(mode: 'transfer'),
    ),
    GetPage(
      name: '/transactionDetails',
      page: () => const TransactionDetails(),
    ),
    GetPage(
      name: '/account',
      page: () => const Account(),
    ),

    
    
    
    GetPage(
      name: '/admin',
      page: () => const BottomNavApp(),
    ),
    GetPage(
      name: '/merchant-apply',
      page: () => const RegisterMerchant(),
    ),
    GetPage(
      name: '/provider',
      page: () => const BottomNavApp(), 
    ),
    GetPage(
      name: '/provider/reports',
      page: () => const ProviderReportPage(),
    ),
    GetPage(
      name: '/provider/api-key',
      page: () => const ApiKeyPage(),
    ),
    GetPage(
      name: '/account/profile',
      page: () => const UserProfilePage(),
    ),
    GetPage(
      name: '/account/update',
      page: () => const UpdateProfilePage(),
    ),
    GetPage(
      name: '/account/merchant-profile',
      page: () => const MerchantProfilePage(),
    ),
    GetPage(
      name: '/account/change-pin',
      page: () => const ChangePinScreen(),
    ),
    GetPage(
      name: '/bank/link',
      page: () => const LinkProviderPage(),
    ),
  ];
}
