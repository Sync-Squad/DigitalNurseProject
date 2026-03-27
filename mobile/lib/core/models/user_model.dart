class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final SubscriptionTier subscriptionTier;
  final String? age;
  final String? medicalConditions;
  final String? emergencyContact;
  final String? phone;
  final String? avatarUrl;
  final bool medicineRemindersEnabled;
  final bool healthAlertsEnabled;
  final bool caregiverUpdatesEnabled;
  final bool biometricEnabled;
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.subscriptionTier,
    this.age,
    this.medicalConditions,
    this.emergencyContact,
    this.phone,
    this.avatarUrl,
    this.medicineRemindersEnabled = true,
    this.healthAlertsEnabled = true,
    this.caregiverUpdatesEnabled = true,
    this.biometricEnabled = false,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    SubscriptionTier? subscriptionTier,
    String? age,
    String? medicalConditions,
    String? emergencyContact,
    String? phone,
    String? avatarUrl,
    bool? medicineRemindersEnabled,
    bool? healthAlertsEnabled,
    bool? caregiverUpdatesEnabled,
    bool? biometricEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      age: age ?? this.age,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      medicineRemindersEnabled:
          medicineRemindersEnabled ?? this.medicineRemindersEnabled,
      healthAlertsEnabled: healthAlertsEnabled ?? this.healthAlertsEnabled,
      caregiverUpdatesEnabled:
          caregiverUpdatesEnabled ?? this.caregiverUpdatesEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString(),
      'subscriptionTier': subscriptionTier.toString(),
      'age': age,
      'medicalConditions': medicalConditions,
      'emergencyContact': emergencyContact,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'medicineRemindersEnabled': medicineRemindersEnabled,
      'healthAlertsEnabled': healthAlertsEnabled,
      'caregiverUpdatesEnabled': caregiverUpdatesEnabled,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.patient,
      ),
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.toString() == json['subscriptionTier'],
        orElse: () => SubscriptionTier.free,
      ),
      age: json['age'],
      medicalConditions: json['medicalConditions'],
      emergencyContact: json['emergencyContact'],
      phone: json['phone'] ?? json['phoneNumber'],
      avatarUrl: json['avatarUrl']?.toString().trim(),
      medicineRemindersEnabled: json['medicineRemindersEnabled'] ?? true,
      healthAlertsEnabled: json['healthAlertsEnabled'] ?? true,
      caregiverUpdatesEnabled: json['caregiverUpdatesEnabled'] ?? true,
      biometricEnabled: json['biometricEnabled'] ?? false,
    );
  }
}

enum UserRole { patient, caregiver }

enum SubscriptionTier { free, premium }
