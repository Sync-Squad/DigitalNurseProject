enum PatientStatus { stable, needsAttention }

class CareRecipientModel {
  final String assignmentId;
  final String elderId;
  final String name;
  final String? phone;
  final String? email;
  final String? relationship;
  final DateTime assignedAt;
  final String? avatarUrl;
  final String? age;
  final DateTime? lastActivityTime;
  final PatientStatus? status;

  CareRecipientModel({
    required this.assignmentId,
    required this.elderId,
    required this.name,
    this.phone,
    this.email,
    this.relationship,
    required this.assignedAt,
    this.avatarUrl,
    this.age,
    this.lastActivityTime,
    this.status,
  });

  CareRecipientModel copyWith({
    String? assignmentId,
    String? elderId,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    DateTime? assignedAt,
    String? avatarUrl,
    String? age,
    DateTime? lastActivityTime,
    PatientStatus? status,
  }) {
    return CareRecipientModel(
      assignmentId: assignmentId ?? this.assignmentId,
      elderId: elderId ?? this.elderId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      assignedAt: assignedAt ?? this.assignedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      status: status ?? this.status,
    );
  }

  factory CareRecipientModel.fromJson(Map<String, dynamic> json) {
    return CareRecipientModel(
      assignmentId:
          json['id']?.toString() ?? json['assignmentId']?.toString() ?? '',
      elderId:
          json['elderId']?.toString() ??
          json['linkedPatientId']?.toString() ??
          '',
      name: json['elderName']?.toString() ?? json['name']?.toString() ?? '',
      phone: json['elderPhone']?.toString() ?? json['phone']?.toString(),
      email: json['elderEmail']?.toString() ?? json['email']?.toString(),
      relationship: json['relationship']?.toString(),
      assignedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'].toString())
          : DateTime.now(),
      avatarUrl: json['avatarUrl']?.toString(),
      age: json['age']?.toString(),
      lastActivityTime: json['lastActivityTime'] != null
          ? DateTime.parse(json['lastActivityTime'].toString())
          : null,
      status: json['status'] != null
          ? (json['status'] == 'needsAttention'
                ? PatientStatus.needsAttention
                : PatientStatus.stable)
          : null,
    );
  }
}
