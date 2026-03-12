import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load documents
  Future<void> loadDocuments(String userId, {String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _documentService.getDocuments(
        userId,
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get documents by type
  Future<List<DocumentModel>> getDocumentsByType(
    String userId,
    DocumentType type, {
    String? elderUserId,
  }) async {
    return _documentService.getDocumentsByType(
      userId,
      type,
      elderUserId: elderUserId,
    );
  }

  // Upload document
  Future<bool> uploadDocument({
    required String filePath,
    required String title,
    required DocumentType type,
    required DocumentVisibility visibility,
    String? description,
    String? elderUserId,
    DateTime? uploadDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploaded = await _documentService.uploadDocument(
        filePath: filePath,
        title: title,
        type: type,
        visibility: visibility,
        description: description,
        elderUserId: elderUserId,
        uploadDate: uploadDate,
      );
      _documents.insert(0, uploaded);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update document
  Future<bool> updateDocument(DocumentModel document) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _documentService.updateDocument(document);
      final index = _documents.indexWhere((d) => d.id == document.id);
      if (index != -1) {
        _documents[index] = updated;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete document
  Future<bool> deleteDocument(String documentId, {String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _documentService.deleteDocument(
        documentId,
        elderUserId: elderUserId,
      );
      _documents.removeWhere((d) => d.id == documentId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Share document
  Future<bool> shareDocument(
    String documentId,
    DocumentVisibility visibility, {
    String? elderUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _documentService.shareDocument(
        documentId,
        visibility,
        elderUserId: elderUserId,
      );
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        _documents[index] = updated;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Initialize mock data (deprecated - no longer needed with API integration)
  @Deprecated('Mock data initialization no longer supported')
  Future<void> initializeMockData(String userId) async {
    // Mock data initialization removed - data now comes from API
    await loadDocuments(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
