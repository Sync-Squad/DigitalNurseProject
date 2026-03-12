import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/models/document_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/document_service.dart';
import '../../../core/services/token_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/utils/timezone_util.dart';
import 'package:dio/dio.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentId;

  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final DocumentService _documentService = DocumentService();
  final TokenService _tokenService = TokenService();
  bool _isDownloading = false;
  bool _isDeleting = false;

  Future<void> _handleDelete(BuildContext context) async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('documents.viewerScreen.deleteTitle'.tr()),
        content: Text('documents.viewerScreen.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user == null) {
          return;
        }

        // Handle caregiver context - get elderUserId if user is a caregiver
        String? elderUserId;
        if (user.role == UserRole.caregiver) {
          final documentProvider = context.read<DocumentProvider>();
          final document = documentProvider.documents.firstWhere(
            (d) => d.id == widget.documentId,
            orElse: () => throw Exception('Document not found'),
          );
          final careContext = context.read<CareContextProvider>();
          await careContext.ensureLoaded();
          elderUserId = careContext.selectedElderId ?? document.userId;
        }

        final success = await context.read<DocumentProvider>().deleteDocument(
          widget.documentId,
          elderUserId: elderUserId,
        );

        if (context.mounted) {
          if (success) {
            context.pop();
          } else {
            final errorMessage =
                context.read<DocumentProvider>().error ??
                'documents.viewerScreen.deleteFail'.tr();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppTheme.getErrorColor(context),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final documentProvider = context.read<DocumentProvider>();
      final document = documentProvider.documents.firstWhere(
        (d) => d.id == widget.documentId,
      );

      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${document.title}_${document.id}.${_getFileExtension(document)}';
      final savePath = '${directory.path}/$fileName';

      // Download the file
      await _documentService.downloadDocument(widget.documentId, savePath);

      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document downloaded to: $fileName'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  String _getFileExtension(DocumentModel document) {
    if (document.fileType != null) {
      final type = document.fileType!.toLowerCase();
      if (type.contains('pdf')) return 'pdf';
      if (type.contains('jpeg') || type.contains('jpg')) return 'jpg';
      if (type.contains('png')) return 'png';
      if (type.contains('gif')) return 'gif';
    }
    return 'pdf'; // Default
  }

  Future<String?> _getFileUrl(DocumentModel document) async {
    if (document.fileUrl != null) {
      final baseUrl = await AppConfig.getBaseUrl();
      if (document.fileUrl!.startsWith('http://') ||
          document.fileUrl!.startsWith('https://')) {
        return document.fileUrl;
      }
      return '$baseUrl${document.fileUrl}';
    }
    // Fallback: construct URL from document ID
    final baseUrl = await AppConfig.getBaseUrl();
    final token = await _tokenService.getAccessToken();
    return '$baseUrl/documents/${document.id}/file${token != null ? '?token=$token' : ''}';
  }

  Widget _buildDocumentPreview(DocumentModel document) {
    return FutureBuilder<String?>(
      future: _getFileUrl(document),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            height: 400,
            decoration: ModernSurfaceTheme.glassCard(
              context,
              accent: AppTheme.getDocumentColor(context, document.type.name),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final fileUrl = snapshot.data!;

        if (document.isImage) {
          return _buildImageViewer(fileUrl);
        } else if (document.isPdf) {
          return _buildPdfViewer(fileUrl, document);
        } else {
          return _buildGenericPreview(document, fileUrl);
        }
      },
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    return Container(
      height: 400,
      decoration: ModernSurfaceTheme.glassCard(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Map<String, String>>(
          future: _getImageUrlWithHeaders(imageUrl),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final url = snapshot.data!['url']!;
            final authHeader = snapshot.data!['headers'];
            final headers = authHeader != null
                ? <String, String>{'Authorization': authHeader}
                : <String, String>{};

            return CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers.isEmpty ? null : headers,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, String>> _getImageUrlWithHeaders(String imageUrl) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final token = await _tokenService.getAccessToken();

    // Construct full URL if needed
    String fullUrl;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      fullUrl = imageUrl;
    } else {
      fullUrl = '$baseUrl$imageUrl';
    }

    return {'url': fullUrl, if (token != null) 'headers': 'Bearer $token'};
  }

  Widget _buildPdfViewer(String pdfUrl, DocumentModel document) {
    return FutureBuilder<String>(
      future: _downloadPdfForViewing(pdfUrl, document),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 600,
            decoration: ModernSurfaceTheme.glassCard(context),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 600,
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                  SizedBox(height: 8.h),
                  Text(
                    'Failed to load PDF: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final localPath = snapshot.data!;
        return Container(
          height: 600,
          decoration: ModernSurfaceTheme.glassCard(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SfPdfViewer.file(
              File(localPath),
              enableDoubleTapZooming: true,
              enableTextSelection: true,
            ),
          ),
        );
      },
    );
  }

  Future<String> _downloadPdfForViewing(
    String pdfUrl,
    DocumentModel document,
  ) async {
    try {
      // Get temporary directory for caching
      final directory = await getTemporaryDirectory();
      final fileName =
          'pdf_${document.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final localPath = '${directory.path}/$fileName';

      // Check if file already exists
      final file = File(localPath);
      if (await file.exists()) {
        return localPath;
      }

      // Download the PDF
      final baseUrl = await AppConfig.getBaseUrl();
      final token = await _tokenService.getAccessToken();

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final response = await dio.get(
        pdfUrl.startsWith('http') ? pdfUrl : '$baseUrl$pdfUrl',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.data);
        return localPath;
      } else {
        throw Exception('Failed to download PDF: ${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  Widget _buildGenericPreview(DocumentModel document, String fileUrl) {
    return Container(
      height: 220,
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: AppTheme.getDocumentColor(context, document.type.name),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.fileText,
            size: 64,
            color: ModernSurfaceTheme.primaryTeal,
          ),
          SizedBox(height: 12.h),
          Text(
            document.fileType ?? 'Document',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernSurfaceTheme.deepTeal.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Preview not available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernSurfaceTheme.deepTeal.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final document = documentProvider.documents.firstWhere(
      (d) => d.id == widget.documentId,
      orElse: () => throw Exception('Document not found'),
    );

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'documents.viewerScreen.details'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _isDeleting ? null : () => _handleDelete(context),
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.getErrorColor(context),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDocumentPreview(document),
            SizedBox(height: 24.h),
            Container(
              decoration: ModernSurfaceTheme.glassCard(context),
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ModernSurfaceTheme.deepTeal,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _InfoRow(label: 'Type', value: document.type.displayName),
                  SizedBox(height: 8.h),
                  _InfoRow(
                    label: 'Upload Date',
                    value: DateFormat(
                      'MMM d, yyyy - h:mm a',
                    ).format(TimezoneUtil.toPakistanTime(document.uploadDate)),
                  ),
                  SizedBox(height: 8.h),
                  _InfoRow(
                    label: 'Visibility',
                    value: _getVisibilityText(document.visibility),
                  ),
                  if (document.description != null) ...[
                    SizedBox(height: 8.h),
                    _InfoRow(
                      label: 'Description',
                      value: document.description!,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _handleDownload,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(FIcons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'documents.viewerScreen.download'.tr()),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: ModernSurfaceTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Share functionality (mock)'),
                    backgroundColor: AppTheme.getSuccessColor(context),
                  ),
                );
              },
              icon: const Icon(FIcons.share),
              label: Text('documents.viewerScreen.share'.tr()),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(
                  color: ModernSurfaceTheme.deepTeal.withOpacity(0.4),
                ),
                foregroundColor: ModernSurfaceTheme.deepTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVisibilityText(DocumentVisibility visibility) {
    switch (visibility) {
      case DocumentVisibility.private:
        return 'documents.uploadScreen.private'.tr();
      case DocumentVisibility.sharedWithCaregiver:
        return 'documents.uploadScreen.sharedWithCaregiver'.tr();
      case DocumentVisibility.public:
        return 'documents.uploadScreen.public'.tr();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernSurfaceTheme.deepTeal.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ModernSurfaceTheme.deepTeal,
            ),
          ),
        ),
      ],
    );
  }
}
