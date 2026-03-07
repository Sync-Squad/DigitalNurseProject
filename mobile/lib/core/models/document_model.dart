import '../config/app_config.dart';

class DocumentModel {
  final String id;
  final String title;
  final DocumentType type;
  final String filePath; // Server-side file path (for backward compatibility)
  final String? fileUrl; // Accessible URL for viewing/downloading
  final String? fileType; // File MIME type or extension
  final DateTime uploadDate;
  final DocumentVisibility visibility;
  final String? description;
  final String userId;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.filePath,
    this.fileUrl,
    this.fileType,
    required this.uploadDate,
    required this.visibility,
    this.description,
    required this.userId,
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    DocumentType? type,
    String? filePath,
    String? fileUrl,
    String? fileType,
    DateTime? uploadDate,
    DocumentVisibility? visibility,
    String? description,
    String? userId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      uploadDate: uploadDate ?? this.uploadDate,
      visibility: visibility ?? this.visibility,
      description: description ?? this.description,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadDate': uploadDate.toIso8601String(),
      'visibility': visibility.toString(),
      'description': description,
      'userId': userId,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      title: json['title'],
      type: DocumentType.values.firstWhere((e) => e.toString() == json['type']),
      filePath: json['filePath'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      uploadDate: DateTime.parse(json['uploadDate']),
      visibility: DocumentVisibility.values.firstWhere(
        (e) => e.toString() == json['visibility'],
      ),
      description: json['description'],
      userId: json['userId'],
    );
  }
}

enum DocumentType {
  prescription,
  labReport,
  xray,
  scan,
  discharge,
  insurance,
  other,
}

enum DocumentVisibility { private, sharedWithCaregiver, public }

extension DocumentModelExtension on DocumentModel {
  /// Check if the document is an image
  bool get isImage {
    final type = fileType?.toLowerCase() ?? '';
    return type.contains('image') ||
        type == 'jpg' ||
        type == 'jpeg' ||
        type == 'png' ||
        type == 'gif';
  }

  /// Check if the document is a PDF
  bool get isPdf {
    final type = fileType?.toLowerCase() ?? '';
    return type.contains('pdf') || type == 'pdf';
  }

  /// Get the full URL for viewing the document
  Future<String?> getViewUrl() async {
    if (fileUrl != null) {
      // If fileUrl is already a full URL, return it
      if (fileUrl!.startsWith('http://') || fileUrl!.startsWith('https://')) {
        return fileUrl;
      }
      // Otherwise, construct full URL from base URL
      final baseUrl = await AppConfig.getBaseUrl();
      return '$baseUrl$fileUrl';
    }
    // Fallback: construct URL from document ID
    final baseUrl = await AppConfig.getBaseUrl();
    return '$baseUrl/documents/$id/file';
  }
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.prescription:
        return 'Prescription';
      case DocumentType.labReport:
        return 'Lab Report';
      case DocumentType.xray:
        return 'X-Ray';
      case DocumentType.scan:
        return 'Scan';
      case DocumentType.discharge:
        return 'Discharge Summary';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.other:
        return 'Other';
    }
  }
}
