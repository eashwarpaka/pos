import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  static const String secret = "KOVIXA_SECRET_2026";
  static const String clientId = "RESTO101";
  static const String adminPassword = "1234";

  // JS-compatible hash
  static int _hashString(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = (hash << 5) - hash + str.codeUnitAt(i);
      hash = hash.toSigned(32);
    }
    return hash.abs();
  }

  static String _generateCode(String expiryDate) {
    final raw = "$clientId|$expiryDate|$secret";
    var hash = _hashString(raw).toString();

    if (hash.length < 10) hash = hash.padRight(10, "7");
    if (hash.length > 10) hash = hash.substring(0, 10);
    return hash;
  }

  /// verify entered code + expiry
  static Future<bool> verifyLicense(
      String code, String expiryDate) async {

    final expected = _generateCode(expiryDate);
    if (code != expected) return false;

    final exp = DateTime.parse(expiryDate);
    if (DateTime.now().isAfter(exp)) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("license_expiry", expiryDate);
    return true;
  }

  static Future<bool> isExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("license_expiry");
    if (saved == null) return true;

    final exp = DateTime.parse(saved);
    return DateTime.now().isAfter(exp);
  }
}