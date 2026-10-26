import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core.dart';
import '../../models.dart';
import '../api/api_service.dart';

/// Authentication service for managing user sessions.
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Save operator token and role.
  static Future<void> saveOperatorSession(AuthTokens tokens) async {
    await _storage.write(key: AppConstants.storageKeyOperatorToken, value: tokens.accessToken);
    await _storage.write(key: AppConstants.storageKeyUserRole, value: UserRole.operator.value);
  }

  /// Save crew token and role.
  static Future<void> saveCrewSession(AuthTokens tokens) async {
    await _storage.write(key: AppConstants.storageKeyCrewToken, value: tokens.accessToken);
    await _storage.write(key: AppConstants.storageKeyUserRole, value: UserRole.crew.value);
  }

  /// Get operator token.
  static Future<String?> getOperatorToken() async {
    return await _storage.read(key: AppConstants.storageKeyOperatorToken);
  }

  /// Get crew token.
  static Future<String?> getCrewToken() async {
    return await _storage.read(key: AppConstants.storageKeyCrewToken);
  }

  /// Get current user role.
  static Future<UserRole?> getUserRole() async {
    final roleStr = await _storage.read(key: AppConstants.storageKeyUserRole);
    if (roleStr == null) return null;
    return UserRoleExtension.fromString(roleStr);
  }

  /// Check if operator is logged in.
  static Future<bool> isOperatorLoggedIn() async {
    final token = await getOperatorToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if crew is logged in.
  static Future<bool> isCrewLoggedIn() async {
    final token = await getCrewToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear all auth data.
  static Future<void> logout() async {
    await AppConfig.clearAuthData();
    CrewSession.clear();
  }

  /// Initialize crew session from stored token.
  ///
  /// Loads the real crew profile from /crew/me when possible. On any failure
  /// falls back to placeholder ids so the app still starts.
  static Future<void> initializeCrewSession() async {
    final token = await getCrewToken();
    if (token != null) {
      try {
        final profile = await ApiService().getCrewMe(token);
        CrewSession.setSession(
          token: token,
          crewId: profile.id,
          operatorId: profile.operatorId,
        );
      } catch (_) {
        // Keep the previous fallback so the app still starts.
        CrewSession.setSession(token: token, crewId: 0, operatorId: 0);
      }
    }
  }
}
