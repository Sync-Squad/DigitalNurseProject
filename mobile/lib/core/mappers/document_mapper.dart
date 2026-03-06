import '../models/document_model.dart';
import '../utils/timezone_util.dart';

/// Maps backend document response to Flutter DocumentModel
class DocumentMapper {
  /// Convert backend API response to DocumentModel
  static DocumentModel fromApiResponse(Map<String, dynamic> json) {
    // Convert type string to enum
    DocumentType type = DocumentType.other;
    if (json['type'] != null || json['typeCode'] != null) {
      final typeStr = (json['type'] ?? json['typeCode']).toString().toLowerCase();
      switch (typeStr) {
        case 'prescription':
          type = DocumentType.prescription;
          break;
        case 'labreport':
        case 'lab_report':
          type = DocumentType.labReport;
          break;
        case 'xray':
        case 'x-ray':
          type = DocumentType.xray;
          break;
        case 'scan':
          type = DocumentType.scan;
          break;
        case 'discharge':
          type = DocumentType.discharge;
          break;
        case 'insurance':
          type = DocumentType.insurance;
          break;
        case 'other':
        default:
          type = DocumentType.other;
      }
    }

    // Convert visibility string to enum
    DocumentVisibility visibility = DocumentVisibility.private;
    if (json['visibility'] != null || json['visibilityCode'] != null) {
      final visStr = (json['visibility'] ?? json['visibilityCode']).toString().toLowerCase();
      switch (visStr) {
        case 'private':
          visibility = DocumentVisibility.private;
          break;
        case 'sharedwithcaregiver':
        case 'shared_with_caregiver':
          visibility = DocumentVisibility.sharedWithCaregiver;
          break;
        case 'public':
          visibility = DocumentVisibility.public;
          break;
        default:
          visibility = DocumentVisibility.private;
      }
    }

    // Parse upload date
    DateTime uploadDate = DateTime.now();
    if (json['uploadDate'] != null) {
      try {
        uploadDate = DateTime.parse(json['uploadDate'].toString());
      } catch (e) {
        uploadDate = DateTime.now();
      }
    } else if (json['createdAt'] != null) {
      try {
        uploadDate = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        uploadDate = DateTime.now();
      }
    }

    // Get file path - backend may return fileName or filePath
    String filePath = json['filePath']?.toString() ?? 
                     json['fileName']?.toString() ?? 
                     '';
    
    // Get file URL - backend now returns fileUrl
    String? fileUrl = json['fileUrl']?.toString();
    
    // Get file type
    String? fileType = json['fileType']?.toString();

    return DocumentModel(
      id: json['id']?.toString() ?? json['documentId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: type,
      filePath: filePath,
      fileUrl: fileUrl,
      fileType: fileType,
      uploadDate: uploadDate,
      visibility: visibility,
      description: json['description']?.toString(),
      userId: json['userId']?.toString() ?? json['elderUserId']?.toString() ?? '',
    );
  }

  /// Convert DocumentModel to backend API request format
  static Map<String, dynamic> toApiRequest(DocumentModel document) {
    // Convert type enum to string
    String type;
    switch (document.type) {
      case DocumentType.prescription:
        type = 'prescription';
        break;
      case DocumentType.labReport:
        type = 'labReport';
        break;
      case DocumentType.xray:
        type = 'xray';
        break;
      case DocumentType.scan:
        type = 'scan';
        break;
      case DocumentType.discharge:
        type = 'discharge';
        break;
      case DocumentType.insurance:
        type = 'insurance';
        break;
      case DocumentType.other:
        type = 'other';
        break;
    }

    // Convert visibility enum to string
    String visibility;
    switch (document.visibility) {
      case DocumentVisibility.private:
        visibility = 'private';
        break;
      case DocumentVisibility.sharedWithCaregiver:
        visibility = 'sharedWithCaregiver';
        break;
      case DocumentVisibility.public:
        visibility = 'public';
        break;
    }

    return {
      'title': document.title,
      'type': type,
      'visibility': visibility,
      if (document.description != null) 'description': document.description,
      'uploadDate': TimezoneUtil.toPakistanTimeIso8601(document.uploadDate),
      if (document.userId.isNotEmpty) 'elderUserId': document.userId,
    };
  }
}

