import 'package:easy_localization/easy_localization.dart';
import '../config/app_config.dart';

class DocumentModel {
  final String id;
  final String title;
  final DocumentType type;
  final String filePath; // Server-side file path (for backward compatibility)
  final String? fileUrl; // Accessible URL for viewing/downloading
  final String? fileType; // File MIME type or extension
  final String fileName; // Original filename (preserved)
  final String? abspath; // Absolute filesystem path (from backend)
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
    required this.fileName,
    this.abspath,
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
    String? fileName,
    String? abspath,
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
      fileName: fileName ?? this.fileName,
      abspath: abspath ?? this.abspath,
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
      'fileName': fileName,
      'abspath': abspath,
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
      fileName: json['fileName'] ?? '',
      abspath: json['abspath'],
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
    final path = filePath.toLowerCase();
    return type.contains('image') ||
        type == 'jpg' ||
        type == 'jpeg' ||
        type == 'png' ||
        type == 'gif' ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif');
  }

  /// Check if the document is a PDF
  bool get isPdf {
    final type = fileType?.toLowerCase() ?? '';
    final path = filePath.toLowerCase();
    return type.contains('pdf') || 
        type == 'pdf' ||
        path.endsWith('.pdf') ||
        fileName.toLowerCase().endsWith('.pdf');
  }

  /// Get the file extension
  String get extension {
    if (fileType != null) {
      final type = fileType!.toLowerCase();
      if (type.contains('pdf')) return 'pdf';
      if (type.contains('jpeg') || type.contains('jpg')) return 'jpg';
      if (type.contains('png')) return 'png';
      if (type.contains('gif')) return 'gif';
      if (type.contains('text') || type == 'txt') return 'txt';
      if (type.contains('word') || type.contains('doc')) return 'docx';
    }
    
    // Fallback to filePath extension
    final segments = filePath.split('.');
    if (segments.length > 1) {
      return segments.last.toLowerCase();
    }
    
    return 'bin';
  }

  /// Get the user-facing file name
  String getFileName() {
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '_').replaceAll(' ', '_');
    return '$cleanTitle.$extension';
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
        return 'documents.types.prescription'.tr();
      case DocumentType.labReport:
        return 'documents.types.labReport'.tr();
      case DocumentType.xray:
        return 'documents.types.xray'.tr();
      case DocumentType.scan:
        return 'documents.types.scan'.tr();
      case DocumentType.discharge:
        return 'documents.types.discharge'.tr();
      case DocumentType.insurance:
        return 'documents.types.insurance'.tr();
      case DocumentType.other:
        return 'documents.types.other'.tr();
    }
  }
}
