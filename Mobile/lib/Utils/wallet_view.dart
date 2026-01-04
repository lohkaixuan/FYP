// ==================================================
// Program Name   : wallet_view.dart
// Purpose        : Wallet view helper widgets
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:mobile/Api/apimodel.dart';

class WalletViewState {
  final String label;
  final double balance;
  final bool isMerchantWallet;
  final DateTime lastUpdated;

  const WalletViewState({
    required this.label,
    required this.balance,
    required this.isMerchantWallet,
    required this.lastUpdated,
  });

  factory WalletViewState.resolve({
    required AppUser? user,
    required bool merchantActive,
  }) {
    final bool useMerchantWallet = merchantActive;
    final double resolvedBalance = useMerchantWallet
        ? (user?.merchantWalletBalance ?? 0.0)
        : (user?.userWalletBalance ?? user?.balance ?? 0.0);
    final String resolvedLabel =
        useMerchantWallet ? 'Merchant Wallet' : 'User Wallet';
    return WalletViewState(
      label: resolvedLabel,
      balance: resolvedBalance,
      isMerchantWallet: useMerchantWallet,
      lastUpdated: user?.lastLogin ?? DateTime.now(),
    );
  }
}
