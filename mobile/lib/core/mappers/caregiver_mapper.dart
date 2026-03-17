import '../models/caregiver_model.dart';

/// Maps backend caregiver response to Flutter CaregiverModel
class CaregiverMapper {
  /// Convert backend API response to CaregiverModel
  /// Backend returns ElderAssignment with joined User data
  static CaregiverModel fromApiResponse(Map<String, dynamic> json) {
    // Convert status string to enum
    CaregiverStatus status = CaregiverStatus.pending;
    if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      switch (statusStr) {
        case 'accepted':
          status = CaregiverStatus.accepted;
          break;
        case 'declined':
          status = CaregiverStatus.declined;
          break;
        case 'pending':
        default:
          status = CaregiverStatus.pending;
      }
    }

    // Parse dates
    DateTime invitedAt = DateTime.now();
    if (json['invitedAt'] != null) {
      try {
        invitedAt = DateTime.parse(json['invitedAt'].toString());
      } catch (e) {
        invitedAt = DateTime.now();
      }
    } else if (json['createdAt'] != null) {
      try {
        invitedAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        invitedAt = DateTime.now();
      }
    }

    DateTime? acceptedAt;
    if (json['acceptedAt'] != null) {
      try {
        acceptedAt = DateTime.parse(json['acceptedAt'].toString());
      } catch (e) {
        acceptedAt = null;
      }
    }

    // Extract user info if nested (from join)
    String name = '';
    String phone = '';
    if (json['caregiver'] != null && json['caregiver'] is Map) {
      final caregiver = json['caregiver'] as Map<String, dynamic>;
      name =
          caregiver['full_name']?.toString() ??
          caregiver['name']?.toString() ??
          '';
      phone = caregiver['phone']?.toString() ?? '';
    } else {
      name =
          json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['caregiverName']?.toString() ??
          '';
      phone = json['phone']?.toString() ?? '';
    }

    return CaregiverModel(
      id: json['elderAssignmentId']?.toString() ??
          json['id']?.toString() ??
          json['assignmentId']?.toString() ??
          '',
      name: name,
      phone: phone,
      status: status,
      relationship: json['relationship']?.toString(),
      linkedPatientId: json['linkedPatientId']?.toString() ??
          json['elderUserId']?.toString() ??
          json['patientId']?.toString() ??
          '',
      invitedAt: invitedAt,
      acceptedAt: acceptedAt,
      isActive: json['isActive'] ?? true,
    );
  }

  /// Convert invitation API response to CaregiverModel
  static CaregiverModel invitationFromApiResponse(Map<String, dynamic> json) {
    // Convert status string to enum
    CaregiverStatus status = CaregiverStatus.pending;
    if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      switch (statusStr) {
        case 'accepted':
          status = CaregiverStatus.accepted;
          break;
        case 'declined':
          status = CaregiverStatus.declined;
          break;
        case 'pending':
        default:
          status = CaregiverStatus.pending;
      }
    }

    // Parse dates
    DateTime invitedAt = DateTime.now();
    if (json['invitedAt'] != null) {
      try {
        invitedAt = DateTime.parse(json['invitedAt'].toString());
      } catch (e) {
        invitedAt = DateTime.now();
      }
    } else if (json['createdAt'] != null) {
      try {
        invitedAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        invitedAt = DateTime.now();
      }
    }

    DateTime? acceptedAt;
    if (json['acceptedAt'] != null) {
      try {
        acceptedAt = DateTime.parse(json['acceptedAt'].toString());
      } catch (e) {
        acceptedAt = null;
      }
    }

    // Extract info (the person being invited or the person who sent it depends on context)
    // For the patient's view, we want the invited caregiver's info
    String name = json['name']?.toString() ??
        json['full_name']?.toString() ??
        json['inviteName']?.toString() ??
        '';

    String phone = json['phone']?.toString() ??
        json['invitePhone']?.toString() ??
        '';

    // If still empty and inviter exists, this might be from the caregiver's perspective
    if (name.isEmpty && json['inviter'] != null && json['inviter'] is Map) {
      final inviter = json['inviter'] as Map<String, dynamic>;
      name = inviter['full_name']?.toString() ?? inviter['name']?.toString() ?? '';
      phone = inviter['phone']?.toString() ?? '';
    }

    return CaregiverModel(
      id: json['invitationId']?.toString() ??
          json['id']?.toString() ??
          json['elderAssignmentId']?.toString() ??
          '',
      name: name.isEmpty ? 'Pending Caregiver' : name,
      phone: phone,
      status: status,
      relationship: json['relationship']?.toString() ?? json['relationshipCode']?.toString(),
      linkedPatientId:
          json['elderUserId']?.toString() ??
          json['patientId']?.toString() ??
          '',
      invitedAt: invitedAt,
      acceptedAt: acceptedAt,
      isActive: json['isActive'] ?? true, // For invitations, usually true or irrelevant until accepted
    );
  }

  /// Convert CaregiverModel to invitation API request format
  static Map<String, dynamic> invitationToApiRequest({
    required String email,
    String? phone,
    String? relationship,
    String? name,
  }) {
    return {
      'email': email,
      if (phone != null) 'phone': phone,
      if (relationship != null) 'relationship': relationship,
      if (name != null && name.isNotEmpty) 'name': name,
    };
  }
}
