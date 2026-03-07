import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/models/document_model.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/document_picker_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/utils/timezone_util.dart';
import '../widgets/upload_options_bottom_sheet.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DocumentType _documentType = DocumentType.prescription;
  DocumentVisibility _visibility = DocumentVisibility.private;
  DocumentPickerResult? _selectedFile;
  DateTime _uploadDate = TimezoneUtil.nowInPakistan();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user?.role == UserRole.caregiver) {
        context.read<CareContextProvider>().ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showFilePicker() async {
    UploadOptionsBottomSheet.show(context, (option) async {
      DocumentPickerResult? result;

      switch (option) {
        case UploadOption.camera:
          result = await DocumentPickerService.pickImageFromCamera(context);
          break;
        case UploadOption.gallery:
          result = await DocumentPickerService.pickImageFromGallery(context);
          break;
        case UploadOption.document:
          result = await DocumentPickerService.pickDocument(context);
          break;
      }

      if (result != null && mounted) {
        setState(() {
          _selectedFile = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.fileName} selected'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
      }
    });
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a file or photo'),
          backgroundColor: AppTheme.getWarningColor(context),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) {
      return;
    }

    String? elderUserId;
    if (user.role == UserRole.caregiver) {
      final careContext = context.read<CareContextProvider>();
      elderUserId = careContext.selectedElderId;
      if (elderUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Select a patient before uploading documents.'),
            backgroundColor: AppTheme.getWarningColor(context),
          ),
        );
        return;
      }
    }

    final documentProvider = context.read<DocumentProvider>();

    final success = await documentProvider.uploadDocument(
      filePath: _selectedFile!.filePath,
      title: _titleController.text.trim(),
      type: _documentType,
      visibility: _visibility,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      elderUserId: elderUserId,
      uploadDate: _uploadDate,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document uploaded successfully'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload document'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isCaregiver = user?.role == UserRole.caregiver;
    final careContext = isCaregiver
        ? context.watch<CareContextProvider>()
        : null;
    final hasAssignments =
        !isCaregiver || (careContext?.careRecipients.isNotEmpty ?? false);
    final isCareContextLoading = careContext?.isLoading ?? false;
    final careContextError = careContext?.error;
    final hasSelectedRecipient =
        !isCaregiver || careContext?.selectedElderId != null;

    final documentProvider = context.watch<DocumentProvider>();
    final isUploading = documentProvider.isLoading;

    Widget? caregiverNotice;
    if (isCaregiver) {
      if (isCareContextLoading && !hasAssignments) {
        caregiverNotice = const Center(child: CircularProgressIndicator());
      } else if (!hasAssignments) {
        caregiverNotice = _buildCaregiverNotice(
          context,
          icon: FIcons.users,
          title: 'No patients assigned yet',
          message:
              'You can upload documents once a patient has granted you access to their records.',
        );
      } else if (careContextError != null && !hasSelectedRecipient) {
        caregiverNotice = _buildCaregiverNotice(
          context,
          icon: FIcons.info,
          title: 'Unable to load patients',
          message: careContextError,
          onRetry: () => context.read<CareContextProvider>().ensureLoaded(),
        );
      } else if (!hasSelectedRecipient) {
        caregiverNotice = _buildCaregiverNotice(
          context,
          icon: FIcons.userSearch,
          title: 'Select a patient to continue',
          message:
              'Choose a patient from the dashboard to upload documents on their behalf.',
        );
      }
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.pop();
        }
      },
      child: ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Upload Document',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: caregiverNotice != null
            ? Padding(
                padding: ModernSurfaceTheme.screenPadding(),
                child: caregiverNotice,
              )
            : SingleChildScrollView(
                padding: ModernSurfaceTheme.screenPadding(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FileSelector(
                        selectedFile: _selectedFile,
                        isUploading: isUploading,
                        onClear: () => setState(() => _selectedFile = null),
                        onSelect: _showFilePicker,
                      ),
                      SizedBox(height: 24.h),
                      _CustomTextField(
                        controller: _titleController,
                        label: 'Document Title',
                        hint: 'e.g., Blood Test Results',
                      ),
                      SizedBox(height: 16.h),
                      _GlassFormSection(
                        title: 'Document Type',
                        child: DropdownButton<DocumentType>(
                          value: _documentType,
                          isExpanded: true,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          items: DocumentType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isUploading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _documentType = value;
                                    });
                                  }
                                },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _GlassFormSection(
                        title: 'Date & Time',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getFormattedDateTime(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.appleGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isUploading ? null : _selectDate,
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    label: const Text('Change Date'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                      backgroundColor: AppTheme.appleGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isUploading ? null : _selectTime,
                                    icon: const Icon(
                                      Icons.access_time,
                                      size: 18,
                                    ),
                                    label: const Text('Change Time'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                      backgroundColor: AppTheme.appleGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _CustomTextField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Additional details',
                        maxLines: 3,
                      ),
                      SizedBox(height: 16.h),
                      _GlassFormSection(
                        title: 'Visibility',
                        child: Column(
                          children: DocumentVisibility.values
                              .map(
                                (visibility) =>
                                    RadioListTile<DocumentVisibility>(
                                      title: Text(
                                        _visibilityLabel(visibility),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                      value: visibility,
                                      groupValue: _visibility,
                                      onChanged: isUploading
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _visibility = value;
                                                });
                                              }
                                            },
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                              )
                              .toList(),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: isUploading ? null : _handleUpload,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          backgroundColor: AppTheme.appleGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Upload Document'),
                      ),
                    ],
                  ),
                ),
              ),
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
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: ModernSurfaceTheme.primaryTeal),
          SizedBox(height: 16.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ModernSurfaceTheme.deepTeal,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernSurfaceTheme.deepTeal.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ModernSurfaceTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  String _visibilityLabel(DocumentVisibility visibility) {
    switch (visibility) {
      case DocumentVisibility.private:
        return 'Private (Only me)';
      case DocumentVisibility.sharedWithCaregiver:
        return 'Shared with caregivers';
      case DocumentVisibility.public:
        return 'Public (Admin visible)';
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _uploadDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _uploadDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          _uploadDate.hour,
          _uploadDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_uploadDate),
    );

    if (selectedTime != null) {
      setState(() {
        _uploadDate = DateTime(
          _uploadDate.year,
          _uploadDate.month,
          _uploadDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
    }
  }

  String _getFormattedDateTime() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(_uploadDate)} at ${timeFormat.format(_uploadDate)}';
  }
}

class _FileSelector extends StatelessWidget {
  final DocumentPickerResult? selectedFile;
  final bool isUploading;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _FileSelector({
    required this.selectedFile,
    required this.isUploading,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedFile == null) {
      return Container(
        decoration: ModernSurfaceTheme.glassCard(context),
        child: ElevatedButton.icon(
          onPressed: isUploading ? null : onSelect,
          icon: Icon(FIcons.upload, size: 20),
          label: const Text(
            'Select Document or Photo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
            backgroundColor: Colors.transparent,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      );
    }

    final accent = selectedFile!.isImage
        ? ModernSurfaceTheme.primaryTeal
        : AppTheme.getWarningColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: ModernSurfaceTheme.glassCard(context, accent: accent),
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: ModernSurfaceTheme.iconBadge(context, accent),
                child: Icon(
                  selectedFile!.isImage
                      ? FIcons.image
                      : DocumentPickerService.getFileIcon(
                          selectedFile!.fileExtension,
                        ),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFile!.fileName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DocumentPickerService.formatFileSize(
                        selectedFile!.fileSize,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isUploading ? null : onClear,
                icon: const Icon(FIcons.x, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.getErrorColor(
                    context,
                  ).withOpacity(0.12),
                  foregroundColor: AppTheme.getErrorColor(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            final onSurface = colorScheme.onSurface;
            return OutlinedButton.icon(
              onPressed: isUploading ? null : onSelect,
              icon: const Icon(FIcons.upload),
              label: const Text('Change File'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: onSurface.withOpacity(0.3)),
                foregroundColor: onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GlassFormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassFormSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int? maxLines;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.appleGreen, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }
}
