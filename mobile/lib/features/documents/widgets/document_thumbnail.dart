import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:digital_nurse/core/models/document_model.dart';
import 'package:digital_nurse/core/theme/modern_surface_theme.dart';
import 'package:forui/forui.dart';

class DocumentThumbnail extends StatelessWidget {
  final DocumentModel document;
  final double height;
  final double iconSize;

  const DocumentThumbnail({
    super.key,
    required this.document,
    this.height = 40.0,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!document.isImage) {
      return _buildPlaceholder(context);
    }

    return FutureBuilder<String?>(
      future: document.getViewUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context, isLoading: true);
        }
        
        final url = snapshot.data;
        if (url == null) {
          return _buildPlaceholder(context);
        }

        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(context, isLoading: true),
            errorWidget: (context, url, error) => _buildPlaceholder(context),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, {bool isLoading = false}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: ModernSurfaceTheme.tintedCard(
        context,
        ModernSurfaceTheme.accentGreen,
      ).copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ModernSurfaceTheme.accentGreen,
                ),
              )
            : Icon(
                _getDocumentIcon(document.type),
                size: iconSize,
                color: ModernSurfaceTheme.accentGreen,
              ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return FIcons.pill;
      case DocumentType.labReport:
        return FIcons.activity;
      case DocumentType.xray:
      case DocumentType.scan:
        return FIcons.image;
      case DocumentType.discharge:
        return FIcons.fileText;
      case DocumentType.insurance:
        return FIcons.shield;
      case DocumentType.other:
        return FIcons.file;
    }
  }
}
