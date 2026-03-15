class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionData; // JSON string for action-specific data

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.actionData,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionData: actionData ?? this.actionData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionData': actionData,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: _resolveType(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      actionData: json['actionData'],
    );
  }

  static NotificationType _resolveType(String? type) {
    switch (type) {
      case 'medicineReminder':
        return NotificationType.medicineReminder;
      case 'healthAlert':
        return NotificationType.healthAlert;
      case 'caregiverInvitation':
        return NotificationType.caregiverInvitation;
      case 'missedDose':
        return NotificationType.missedDose;
      default:
        return NotificationType.general;
    }
  }
}

enum NotificationType {
  medicineReminder,
  healthAlert,
  caregiverInvitation,
  missedDose,
  general,
}
