/// Operator related models.

enum SubscriptionTier {
  starter,
  growth,
  fleet;

  String get value => name;
  static SubscriptionTier fromString(String s) => SubscriptionTier.values.firstWhere(
        (e) => e.value == s,
        orElse: () => SubscriptionTier.starter,
      );
}

class Operator {
  final int id;
  final String name;
  final String email;
  final SubscriptionTier subscriptionTier;
  final bool subscriptionActive;
  final DateTime createdAt;

  Operator({
    required this.id,
    required this.name,
    required this.email,
    required this.subscriptionTier,
    required this.subscriptionActive,
    required this.createdAt,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      subscriptionTier: SubscriptionTier.fromString(
          json['subscription_tier'] as String? ?? 'starter'),
      subscriptionActive: json['subscription_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class OperatorStats {
  final int fleetSize;
  final int activeTrips;
  final int stopSearchesTotal;
  final String availabilityTarget;
  final int p95TargetMs;

  OperatorStats({
    required this.fleetSize,
    required this.activeTrips,
    required this.stopSearchesTotal,
    required this.availabilityTarget,
    required this.p95TargetMs,
  });

  factory OperatorStats.fromJson(Map<String, dynamic> json) {
    final operatorValue = json['operator_value'] as Map<String, dynamic>?;
    final passengerValue = json['passenger_value'] as Map<String, dynamic>?;
    final systemHealth = json['system_health'] as Map<String, dynamic>?;

    return OperatorStats(
      fleetSize: operatorValue?['fleet_size'] as int? ?? 0,
      activeTrips: operatorValue?['active_trips'] as int? ?? 0,
      stopSearchesTotal: passengerValue?['stop_searches_total'] as int? ?? 0,
      availabilityTarget: systemHealth?['availability_target'] as String? ?? '99.5%',
      p95TargetMs: systemHealth?['p95_target_ms'] as int? ?? 500,
    );
  }
}