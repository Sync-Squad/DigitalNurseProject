import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/utils/timezone_util.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String? _lastContextKey;
  DocumentType? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Defer data loading until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final documentProvider = context.read<DocumentProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return;
    }

    final isCaregiver = user.role == UserRole.caregiver;
    String? targetUserId = user.id;
    String? elderUserId;

    if (isCaregiver) {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();
      targetUserId = careContext.selectedElderId;
      elderUserId = targetUserId;
      if (targetUserId == null) {
        return;
      }
    }

    await documentProvider.loadDocuments(
      targetUserId,
      elderUserId: elderUserId,
    );
  }

  void _ensureContextSync({
    required bool isCaregiver,
    required String? selectedElderId,
    required String? userId,
  }) {
    final key = isCaregiver
        ? 'caregiver-${selectedElderId ?? 'none'}'
        : 'patient-${userId ?? 'unknown'}';

    if (_lastContextKey == key) {
      return;
    }

    _lastContextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isCaregiver = currentUser?.role == UserRole.caregiver;
    final careContext = isCaregiver
        ? context.watch<CareContextProvider>()
        : null;
    final selectedElderId = careContext?.selectedElderId;
    final hasAssignments =
        !isCaregiver || (careContext?.careRecipients.isNotEmpty ?? false);
    final isCareContextLoading = careContext?.isLoading ?? false;
    final careContextError = careContext?.error;

    _ensureContextSync(
      isCaregiver: isCaregiver,
      selectedElderId: selectedElderId,
      userId: currentUser?.id,
    );

    final documentProvider = context.watch<DocumentProvider>();
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final documents = documentProvider.documents;
    final isLoading = documentProvider.isLoading;
    final error = documentProvider.error;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'documents.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!isCaregiver)
            IconButton(
              icon: Icon(Icons.cloud_upload_outlined, color: onPrimary),
              onPressed: () => context.push('/documents/upload'),
            ),
        ],
      ),
      body: Padding(
        padding: ModernSurfaceTheme.screenPadding().copyWith(
          top: 32.h,
          right: 28.w,
        ),
        child: _buildBody(
          context,
          isCaregiver: isCaregiver,
          hasAssignments: hasAssignments,
          hasSelectedRecipient: selectedElderId != null,
          isCareContextLoading: isCareContextLoading,
          careContextError: careContextError,
          isLoading: isLoading,
          error: error,
          documents: documents,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isCaregiver,
    required bool hasAssignments,
    required bool hasSelectedRecipient,
    required bool isCareContextLoading,
    required String? careContextError,
    required bool isLoading,
    required String? error,
    required List<DocumentModel> documents,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    if (isCaregiver) {
      if (isCareContextLoading && !hasAssignments) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!hasAssignments) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.users,
          title: 'documents.caregiverNotice.noPatientsAssigned'.tr(),
          message: 'documents.caregiverNotice.noPatientsAssignedDesc'.tr(),
        );
      }

      if (careContextError != null && !hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.info,
          title: 'documents.caregiverNotice.unableToLoadPatients'.tr(),
          message: careContextError,
          onRetry: _loadData,
        );
      }

      if (!hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.userSearch,
          title: 'documents.caregiverNotice.selectPatientContinue'.tr(),
          message: 'documents.caregiverNotice.selectPatientContinueDesc'.tr(),
        );
      }
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredDocuments = _selectedCategory == null
        ? documents
        : documents.where((d) => d.type == _selectedCategory).toList();

    return Column(
      children: [
        _DocumentsHero(
          documentCount: documents.length,
          isCaregiver: isCaregiver,
        ),
        if (error != null) ...[
          SizedBox(height: 12.h),
          _ErrorBanner(message: error, onRetry: _loadData),
        ],
        SizedBox(height: 12.h),
        // Compact Category Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryTab(
                label: 'All',
                isSelected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...DocumentType.values.map(
                (type) => Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: _CategoryTab(
                    label: 'documents.types.${type.name}'.tr(),
                    isSelected: _selectedCategory == type,
                    onTap: () => setState(() => _selectedCategory = type),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: filteredDocuments.isEmpty
              ? _buildEmptyState(context, isCaregiver: isCaregiver)
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ScreenUtil().screenWidth > 600 ? 3 : 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    final accent = AppTheme.getDocumentColor(
                      context,
                      document.type.name.toLowerCase(),
                    );
                    return Container(
                      decoration: ModernSurfaceTheme.glassCard(
                        context,
                        accent: accent,
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: InkWell(
                        onTap: () => context.push('/documents/${document.id}'),
                        borderRadius: ModernSurfaceTheme.cardRadius(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 40.h,
                              decoration:
                                  ModernSurfaceTheme.tintedCard(
                                    context,
                                    accent,
                                  ).copyWith(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                              child: Icon(
                                _getDocumentIcon(document.type),
                                size: 24.r,
                                color: accent,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              document.title,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                                fontSize: 13.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'documents.types.${document.type.name}'.tr(),
                              style: textTheme.labelSmall?.copyWith(
                                color: AppTheme.appleGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              DateFormat('MMM d, yyyy').format(
                                TimezoneUtil.toPakistanTime(
                                  document.uploadDate,
                                ),
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: muted,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isCaregiver}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FIcons.fileText, size: 56, color: colorScheme.primary),
          SizedBox(height: 12.h),
          Text(
            'documents.emptyState.noDocumentsUploadedYet'.tr(),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isCaregiver
                ? 'documents.emptyState.patientNotShared'.tr()
                : 'documents.emptyState.uploadPrescriptions'.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (!isCaregiver) ...[
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.push('/documents/upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'documents.actions.uploadDocument'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaregiverNotice(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          SizedBox(height: 16.h),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: onPrimary,
              ),
              child: Text(
                'actions.retry'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getErrorColor(context);
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context, accent: color),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text('actions.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class _DocumentsHero extends StatelessWidget {
  final int documentCount;
  final bool isCaregiver;

  const _DocumentsHero({
    required this.documentCount,
    required this.isCaregiver,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    final h = ModernSurfaceTheme.heroPadding();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth * 0.4;
          return Container(
            width: double.infinity,
            decoration: ModernSurfaceTheme.heroDecoration(context),
            child: Stack(
              children: [
                // ── Right 40%: image pinned to right edge ─────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: halfWidth,
                  child: Image.asset(
                    'assets/images/documentread.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                // ── Left side: text column drives card height ─────────
                Padding(
                  padding: EdgeInsets.only(
                    left: h.left,
                    top: h.top,
                    bottom: h.bottom,
                    right: halfWidth + h.right,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCaregiver
                            ? 'documents.sharedRecords'.tr()
                            : 'documents.yourHealthVault'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: AppTheme.appleGreen,
                            ),
                            child: Text(
                              '$documentCount',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Flexible(
                            child: Text(
                              'documents.documentsCount'.tr(),
                              style: textTheme.headlineSmall?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      if (!isCaregiver) ...[
                        SizedBox(height: 10.h),
                        _HeroChip(
                          icon: Icons.cloud_upload_outlined,
                          label: 'documents.upload'.tr(),
                          onTap: () => context.push('/documents/upload'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeroChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.appleGreen,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(width: 8.w),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      );
    }

    return chip;
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.appleGreen,
                borderRadius: BorderRadius.circular(22),
              )
            : ModernSurfaceTheme.frostedChip(context),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
