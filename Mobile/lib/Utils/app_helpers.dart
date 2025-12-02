// lib/Utils/app_helpers.dart
class AppHelpers {
  /// 字符串里是否包含某角色（大小写/空白/逗号安全）
  static bool hasRole(String raw, String role) {
    final want = role.trim().toLowerCase();
    if (want.isEmpty) return false;
    for (final r in raw.split(RegExp(r'[,\s]+'))) {
      if (r.trim().toLowerCase() == want) return true;
    }
    return false;
  }

  /// 解析后端 role 字符串 ⇒ 去重的小写集合
  static Set<String> parseRoles(String raw) {
    final out = <String>{};
    for (final r in raw.split(RegExp(r'[,\s]+'))) {
      final v = r.trim().toLowerCase();
      if (v == 'third_party' || v == 'thirdparty') {
        out.add('provider');
      } else if (v.isNotEmpty) {
        out.add(v);
      }
    }
    return out;
  }

  /// 业务规则：有 merchant ⇒ 也具备 user
  static Set<String> ensureMerchantImpliesUser(Set<String> roles) {
    final out = {...roles};
    if (out.contains('merchant')) out.add('user');
    return out;
  }

  /// 根据你产品优先级挑一个默认激活角色
  static String pickDefaultActive(Set<String> roles) {
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('provider')) return 'provider';
    //if (roles.contains('third_party')) return 'provider';
    if (roles.contains('merchant')) return 'merchant';
    return 'user';
  }
}
