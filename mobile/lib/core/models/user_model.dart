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
      phone: json['phone'],
      avatarUrl: json['avatarUrl']?.toString().trim(),
    );
  }
}

enum UserRole { patient, caregiver }

enum SubscriptionTier { free, premium }
