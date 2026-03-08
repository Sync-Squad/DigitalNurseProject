class CaregiverModel {
  final String id;
  final String name;
  final String phone;
  final CaregiverStatus status;
  final String? relationship;
  final String linkedPatientId;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final bool isActive;

  CaregiverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.relationship,
    required this.linkedPatientId,
    required this.invitedAt,
    this.acceptedAt,
    this.isActive = true,
  });

  CaregiverModel copyWith({
    String? id,
    String? name,
    String? phone,
    CaregiverStatus? status,
    String? relationship,
    String? linkedPatientId,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    bool? isActive,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      relationship: relationship ?? this.relationship,
      linkedPatientId: linkedPatientId ?? this.linkedPatientId,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'status': status.toString(),
      'relationship': relationship,
      'linkedPatientId': linkedPatientId,
      'invitedAt': invitedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory CaregiverModel.fromJson(Map<String, dynamic> json) {
    return CaregiverModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      status: CaregiverStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      relationship: json['relationship'],
      linkedPatientId: json['linkedPatientId'],
      invitedAt: DateTime.parse(json['invitedAt']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

enum CaregiverStatus { pending, accepted, declined }
