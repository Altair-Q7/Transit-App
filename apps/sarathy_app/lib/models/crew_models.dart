library;

/// Crew profile returned by GET /crew/me.
class CrewProfile {
  final int id;
  final String name;
  final String phone;
  final String role;
  final int operatorId;

  CrewProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.operatorId,
  });

  factory CrewProfile.fromJson(Map<String, dynamic> json) {
    return CrewProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      operatorId: json['operator_id'] as int,
    );
  }
}
