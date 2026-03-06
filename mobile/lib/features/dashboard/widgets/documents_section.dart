import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/utils/timezone_util.dart';
import 'expandable_section_tile.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        final documents = documentProvider.documents;
        final recentDocuments = documents.take(3).toList();

        return ExpandableSectionTile(
          icon: Icons.article, // Document icon with horizontal lines
          title: 'dashboard.documents'.tr(),
          subtitle: 'dashboard.viewDetailsTitle'.tr(),
          count: '${documents.length}',
          titleColor: Theme.of(context).colorScheme.primary,
          routeForViewDetails: '/documents',
          interactionMode: InteractionMode.standard,
          expandedChild: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (documents.isEmpty) ...[
                  Center(
                    child: Text(
                      'dashboard.noDocuments'.tr(),
                      style: TextStyle(
                        color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'dashboard.recentDocuments'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ModernSurfaceTheme.deepTeal,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...recentDocuments.map((document) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: ModernSurfaceTheme.glassCard(
                          context,
                          accent: _getDocumentColor(context, document.type),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getDocumentIcon(document.type),
                              color: _getDocumentColor(context, document.type),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: ModernSurfaceTheme.deepTeal,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    document.type.displayName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: ModernSurfaceTheme.deepTeal
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(
                                      TimezoneUtil.toPakistanTime(document.uploadDate),
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: ModernSurfaceTheme.deepTeal
                                              .withValues(alpha: 0.6),
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (documents.length > 3) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'dashboard.moreDocuments'.tr(namedArgs: {
                          'count': '${documents.length - 3}'
                        }),
                        style: TextStyle(
                          color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.prescription:
        return Icons.medication;
      case DocumentType.labReport:
        return Icons.science;
      case DocumentType.xray:
      case DocumentType.scan:
        return Icons.medical_services;
      case DocumentType.discharge:
        return Icons.description;
      case DocumentType.insurance:
        return Icons.account_balance;
      case DocumentType.other:
        return Icons.description;
    }
  }

  Color _getDocumentColor(BuildContext context, DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return AppTheme.getDocumentColor(context, 'prescription');
      case DocumentType.labReport:
        return AppTheme.getDocumentColor(context, 'labreport');
      case DocumentType.xray:
      case DocumentType.scan:
        return AppTheme.getDocumentColor(context, 'xray');
      case DocumentType.discharge:
        return AppTheme.getDocumentColor(context, 'discharge');
      case DocumentType.insurance:
        return AppTheme.getDocumentColor(context, 'insurance');
      case DocumentType.other:
        return AppTheme.getDocumentColor(context, 'other');
    }
  }
}
