import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/document_model.dart';
import '../../../../core/providers/document_provider.dart';
import '../dashboard_theme.dart';
import 'expandable_patient_card.dart';

class PatientDocumentsCard extends StatelessWidget {
  const PatientDocumentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final documentProvider = context.watch<DocumentProvider>();
    final documents = documentProvider.documents;
    final recentDocuments = documents.take(4).toList();
    final brightness = Theme.of(context).brightness;

    return ExpandablePatientCard(
      icon: Icons.article_outlined,
      title: 'patient.yourDocuments'.tr(),
      subtitle: 'patient.documentsSubtitle'.tr(),
      count: '${documents.length}',
      accentColor: CaregiverDashboardTheme.accentYellow,
      routeForViewDetails: '/documents',
      expandedChild: documents.isEmpty
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.tintedCard(
                context,
                CaregiverDashboardTheme.primaryTeal,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.primaryTeal,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'patient.noDocumentsFound'.tr(),
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CaregiverDashboardTheme.tintedForegroundColor(
                          CaregiverDashboardTheme.primaryTeal,
                          brightness: brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...recentDocuments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final document = entry.value;
                  final isLast = index == recentDocuments.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
                    child: _DocumentRow(
                      document: document,
                      onTap: () => context.push('/documents'),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _DocumentRow({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final accent =
        CaregiverDashboardTheme.accentBlue; // Default accent for documents
    final brightness = Theme.of(context).brightness;
    final onTint = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final onTintMuted = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: Icon(
                  _getDocumentIcon(document.type),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onTint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      document.type.displayName,
                      style: context.theme.typography.xs.copyWith(
                        color: onTintMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text('patient.view'.tr()),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            DateFormat('MMM d, h:mm a').format(document.uploadDate),
            style: context.theme.typography.xs.copyWith(color: onTintMuted),
          ),
        ],
      ),
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
}
