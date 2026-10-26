import 'dart:async';

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

  /// Initialize the crew session from the stored token.
  ///
  /// Startup never waits on the network: the token is exposed immediately and
  /// the profile ids are refreshed in the background with a short timeout.
  static Future<void> initializeCrewSession() async {
    final token = await getCrewToken();
    if (token == null) return;

    CrewSession.setSession(token: token, crewId: 0, operatorId: 0);
    unawaited(_refreshCrewProfile(token));
  }

  static Future<void> _refreshCrewProfile(String token) async {
    try {
      final profile = await ApiService()
          .getCrewMe(token)
          .timeout(const Duration(seconds: 5));
      // Ignore the result if the session changed while the call was in flight.
      if (CrewSession.token != token) return;
      CrewSession.setSession(
        token: token,
        crewId: profile.id,
        operatorId: profile.operatorId,
      );
    } catch (_) {
      // Keep the placeholder ids; the next login will refresh them.
    }
  }
}
