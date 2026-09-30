import 'package:network_info_plus/network_info_plus.dart';

/// WiFi SSID checker — SPEC.md §6.1 (secondary signal).
///
/// Compares the phone's currently connected WiFi network name
/// against the venue's saved `wifi_ssid` (if set).
class WifiChecker {
  static final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the currently connected WiFi SSID.
  /// Returns null if not connected to WiFi or permission denied.
  static Future<String?> getConnectedSsid() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      if (ssid == null) return null;
      // Android sometimes returns SSID wrapped in quotes
      return ssid.replaceAll('"', '').trim();
    } catch (e) {
      // Permission denied or WiFi unavailable
      return null;
    }
  }
}
