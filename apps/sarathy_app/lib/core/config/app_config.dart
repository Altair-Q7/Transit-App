import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Application configuration and secure storage access.
class AppConfig {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Get the API base URL from secure storage or use default.
  static Future<String> getApiBaseUrl() async {
    final url = await _storage.read(key: 'api_base_url');
    return url ?? AppConstants.defaultApiBaseUrl;
  }

  /// Set the API base URL in secure storage.
  static Future<void> setApiBaseUrl(String url) async {
    await _storage.write(key: 'api_base_url', value: url);
  }

  /// Get the WebSocket base URL from secure storage or use default.
  static Future<String> getWsBaseUrl() async {
    final url = await _storage.read(key: 'ws_base_url');
    return url ?? AppConstants.defaultWsBaseUrl;
  }

  /// Set the WebSocket base URL in secure storage.
  static Future<void> setWsBaseUrl(String url) async {
    await _storage.write(key: 'ws_base_url', value: url);
  }

  /// Clear all stored auth data (logout).
  static Future<void> clearAuthData() async {
    await _storage.delete(key: AppConstants.storageKeyOperatorToken);
    await _storage.delete(key: AppConstants.storageKeyCrewToken);
    await _storage.delete(key: AppConstants.storageKeyUserRole);
  }

  /// Check if user is logged in as operator.
  static Future<bool> isOperatorLoggedIn() async {
    final token = await _storage.read(key: AppConstants.storageKeyOperatorToken);
    return token != null && token.isNotEmpty;
  }

  /// Check if user is logged in as crew.
  static Future<bool> isCrewLoggedIn() async {
    final token = await _storage.read(key: AppConstants.storageKeyCrewToken);
    return token != null && token.isNotEmpty;
  }

  /// Get the current user role.
  static Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.storageKeyUserRole);
  }
}