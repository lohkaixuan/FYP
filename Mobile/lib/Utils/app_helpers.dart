// lib/Utils/app_helpers.dart
class AppHelpers {
  
  static bool hasRole(String raw, String role) {
    final want = role.trim().toLowerCase();
    if (want.isEmpty) return false;
    for (final r in raw.split(RegExp(r'[,\s]+'))) {
      if (r.trim().toLowerCase() == want) return true;
    }
    return false;
  }

  
  static Set<String> parseRoles(String raw) {
    final out = <String>{};
    for (final r in raw.split(RegExp(r'[,\s]+'))) {
      final v = r.trim().toLowerCase();
      if (v == 'thirdparty' || v == 'thirdparty') {
        out.add('provider');
      } else if (v.isNotEmpty) {
        out.add(v);
      }
    }
    return out;
  }

  
  static Set<String> ensureMerchantImpliesUser(Set<String> roles) {
    final out = {...roles};
    if (out.contains('merchant')) out.add('user');
    return out;
  }

  
  static String pickDefaultActive(Set<String> roles) {
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('provider')) return 'provider';
    //if (roles.contains('thirdparty')) return 'provider';
    if (roles.contains('merchant')) return 'merchant';
    return 'user';
  }
}
