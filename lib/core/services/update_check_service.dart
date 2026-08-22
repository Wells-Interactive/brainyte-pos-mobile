import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateCheckService {
  static const String _minVersionKey = 'min_supported_version';

  /// Check if the app needs to be updated.
  /// Returns true if the current version is below the minimum required version.
  Future<bool> needsUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = await _getMinVersionFromServer();

      if (minVersion == null) {
        return false;
      }

      return _compareVersions(currentVersion, minVersion) < 0;
    } catch (e) {
      return false;
    }
  }

  /// Get the minimum supported version from the backend.
  Future<String?> _getMinVersionFromServer() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_minVersionKey);
    } catch (e) {
      return null;
    }
  }

  /// Compare two version strings (e.g., "1.0.0" vs "1.0.1").
  /// Returns -1 if a < b, 0 if a == b, 1 if a > b.
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < maxLength; i++) {
      final aPart = i < aParts.length ? aParts[i] : 0;
      final bPart = i < bParts.length ? bParts[i] : 0;

      if (aPart < bPart) return -1;
      if (aPart > bPart) return 1;
    }

    return 0;
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();
}
