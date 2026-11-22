class SolarProject {
  const SolarProject({
    required this.id,
    required this.name,
    this.customer = '',
    this.location = '',
    this.targetCapacityKw = 0,
    this.status = 'Draft',
    this.engineeringData = const <String, Object?>{},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String customer;
  final String location;
  final double targetCapacityKw;
  final String status;
  /// Versioned workspace payloads for survey, PV, electrical, delivery and reports.
  final Map<String, Object?> engineeringData;
  final DateTime createdAt;
  final DateTime updatedAt;

  SolarProject copyWith({
    String? name,
    String? customer,
    String? location,
    double? targetCapacityKw,
    String? status,
    Map<String, Object?>? engineeringData,
    DateTime? updatedAt,
  }) => SolarProject(
        id: id,
        name: name ?? this.name,
        customer: customer ?? this.customer,
        location: location ?? this.location,
        targetCapacityKw: targetCapacityKw ?? this.targetCapacityKw,
        status: status ?? this.status,
        engineeringData: engineeringData ?? this.engineeringData,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'customer': customer,
        'location': location,
        'targetCapacityKw': targetCapacityKw,
        'status': status,
        'engineeringData': engineeringData,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SolarProject.fromJson(Map<String, Object?> json) => SolarProject(
        id: json['id'] as String,
        name: json['name'] as String,
        customer: json['customer'] as String? ?? '',
        location: json['location'] as String? ?? '',
        targetCapacityKw: (json['targetCapacityKw'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Draft',
        engineeringData: json['engineeringData'] is Map ? Map<String, Object?>.from(json['engineeringData'] as Map) : const <String, Object?>{},
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
