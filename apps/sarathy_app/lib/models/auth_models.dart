/// Authentication related models.

/// User roles in the Sarathy platform.
enum UserRole {
  passenger,
  crew,
  operator,
}

/// Extension for UserRole to get string values.
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.passenger:
        return 'passenger';
      case UserRole.crew:
        return 'crew';
      case UserRole.operator:
        return 'operator';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'passenger':
        return UserRole.passenger;
      case 'crew':
        return UserRole.crew;
      case 'operator':
        return UserRole.operator;
      default:
        return UserRole.passenger;
    }
  }
}

/// Auth tokens container.
class AuthTokens {
  final String accessToken;
  final String tokenType;
  final UserRole role;

  AuthTokens({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.role,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json, UserRole role) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'role': role.value,
    };
  }
}

/// Operator credentials for login.
class OperatorCredentials {
  final String email;
  final String password;

  OperatorCredentials({required this.email, required this.password});

  Map<String, String> toFormData() {
    return {
      'username': email,
      'password': password,
    };
  }
}

/// Crew credentials for login.
class CrewCredentials {
  final String phone;
  final String password;

  CrewCredentials({required this.phone, required this.password});

  Map<String, String> toFormData() {
    return {
      'username': phone,
      'password': password,
    };
  }
}

/// Operator signup data.
class OperatorSignupData {
  final String name;
  final String email;
  final String password;

  OperatorSignupData({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }
}