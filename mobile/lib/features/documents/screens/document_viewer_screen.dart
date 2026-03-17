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
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/file_saver_util.dart';

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

      final fileName = document.getFileName();
      
      // Fetch bytes
      final bytes = await _documentService.downloadDocumentBytes(widget.documentId);
      
      // Save file cross-platform
      final savedPath = await FileSaverUtil.saveFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: document.fileType,
      );

      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document downloaded: $fileName'),
              backgroundColor: AppTheme.getSuccessColor(context),
            ),
          );
        } else {
          throw Exception('Could not save file');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _handleShare(DocumentModel document) async {
    final fileUrl = await _getFileUrl(document);
    if (fileUrl == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _DocumentShareDialog(
        document: document,
        fileUrl: fileUrl,
        documentService: _documentService,
      ),
    );
  }

  String _getFileExtension(DocumentModel document) {
    return document.extension;
  }

  Future<String?> _getFileUrl(DocumentModel document) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final token = await _tokenService.getAccessToken();
    
    String? path = document.fileUrl;
    if (path == null || path.isEmpty) {
      // Fallback
      path = 'documents/${document.id}/view';
    }

    // Standardize path (remove leading slash)
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Standardize base URL (ensure trailing slash)
    String normalizedBase = baseUrl;
    if (!normalizedBase.endsWith('/')) {
      normalizedBase += '/';
    }

    String fullUrl = '$normalizedBase$path';
    if (token != null) {
      fullUrl += '${fullUrl.contains('?') ? '&' : '?'}token=$token';
    }
    
    return fullUrl;
  }

  Widget _buildDocumentPreview(DocumentModel document) {
    return FutureBuilder<String?>(
      future: _getFileUrl(document),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildLoadingPlaceholder(context);
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
      height: 300,
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: AppTheme.getDocumentColor(context, document.type.name),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForFileType(document.fileType),
            size: 64,
            color: ModernSurfaceTheme.primaryTeal,
          ),
          SizedBox(height: 12.h),
          Text(
            document.fileType ?? 'application/octet-stream',
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

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      height: 300,
      decoration: ModernSurfaceTheme.glassCard(context),
      child: const Center(
        child: CircularProgressIndicator(),
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
              onPressed: () => _handleShare(document),
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

  IconData _getIconForFileType(String? fileType) {
    if (fileType == null) return FIcons.fileText;
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return FIcons.fileText;
    if (type.contains('image')) return FIcons.image;
    if (type.contains('word')) return FIcons.fileText;
    return FIcons.fileText;
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

class _DocumentShareDialog extends StatefulWidget {
  final DocumentModel document;
  final String fileUrl;
  final DocumentService documentService;

  const _DocumentShareDialog({
    required this.document,
    required this.fileUrl,
    required this.documentService,
  });

  @override
  State<_DocumentShareDialog> createState() => _DocumentShareDialogState();
}

class _DocumentShareDialogState extends State<_DocumentShareDialog> {
  bool _isSharing = false;

  Future<void> _shareOnWhatsApp() async {
    final message = 'Check out this document from Digital Nurse: ${widget.document.title}\n${widget.fileUrl}';
    final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    
    // On web or if direct link fails, share via share_plus
    await Share.share(message, subject: widget.document.title);
  }

  Future<void> _shareFile() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    try {
      final bytes = await widget.documentService.downloadDocumentBytes(widget.document.id);
      final fileName = widget.document.getFileName();
      
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: widget.document.fileType)],
        text: 'Document: ${widget.document.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _getFileExtension(DocumentModel document) {
    return document.extension;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Document'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: _isSharing 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.share_rounded, color: Colors.blue),
            title: const Text('Share as Attachment'),
            subtitle: const Text('Send the actual PDF or Image file'),
            onTap: _isSharing ? null : _shareFile,
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Colors.grey),
            title: const Text('Copy Link'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.fileUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
