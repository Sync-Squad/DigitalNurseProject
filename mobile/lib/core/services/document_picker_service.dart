import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'permission_service.dart';

import 'dart:typed_data';

class DocumentPickerResult {
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final bool isImage;
  final File? file;
  final Uint8List? bytes;

  DocumentPickerResult({
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    required this.isImage,
    this.file,
    this.bytes,
  });
}

class DocumentPickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Take a photo with camera
  static Future<DocumentPickerResult?> pickImageFromCamera(
    BuildContext context,
  ) async {
    try {
      // Check and request camera permission
      final hasPermission = await PermissionService.requestCameraPermission(
        context,
      );
      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return null;
      }

      final file = File(image.path);
      final fileSize = await file.length();
      final fileName = image.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();

      return DocumentPickerResult(
        filePath: image.path,
        fileName: fileName,
        fileExtension: fileExtension,
        fileSize: fileSize,
        isImage: true,
        file: file,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Select image from gallery
  static Future<DocumentPickerResult?> pickImageFromGallery(
    BuildContext context,
  ) async {
    try {
      // Check and request photo library permission
      final hasPermission =
          await PermissionService.requestPhotoLibraryPermission(context);
      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return null;
      }

      final file = File(image.path);
      final fileSize = await file.length();
      final fileName = image.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();

      return DocumentPickerResult(
        filePath: image.path,
        fileName: fileName,
        fileExtension: fileExtension,
        fileSize: fileSize,
        isImage: true,
        file: file,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Select document files (PDF, etc.)
  static Future<DocumentPickerResult?> pickDocument(
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final filePath = file.path ?? '';
      final fileName = file.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final fileSize = file.size;
      final isImage = ['jpg', 'jpeg', 'png'].contains(fileExtension);
      final bytes = file.bytes;

      return DocumentPickerResult(
        filePath: filePath,
        fileName: fileName,
        fileExtension: fileExtension,
        fileSize: fileSize,
        isImage: isImage,
        file: filePath.isNotEmpty ? File(filePath) : null,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file icon based on extension
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
