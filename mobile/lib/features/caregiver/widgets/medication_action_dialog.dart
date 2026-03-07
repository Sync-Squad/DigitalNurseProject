import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';

class MedicationActionDialog extends StatefulWidget {
  final MedicineModel medicine;
  final DateTime scheduledTime;
  final String elderId;

  const MedicationActionDialog({
    super.key,
    required this.medicine,
    required this.scheduledTime,
    required this.elderId,
  });

  @override
  State<MedicationActionDialog> createState() => _MedicationActionDialogState();
}

class _MedicationActionDialogState extends State<MedicationActionDialog> {
  final _notesController = TextEditingController();
  String _selectedAction = 'administered'; // 'administered' or 'skipped'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final medicationProvider = context.read<MedicationProvider>();
      final authProvider = context.read<AuthProvider>();

      // Map action to IntakeStatus
      // Note: This assumes IntakeStatus enum has 'taken' and 'skipped'
      // You may need to adjust based on your actual enum values
      final status = _selectedAction == 'administered' ? 'taken' : 'skipped';

      // TODO: Implement actual API call to mark medication
      // For now, using the existing logIntake method
      await medicationProvider.logIntake(
        medicineId: widget.medicine.id,
        scheduledTime: widget.scheduledTime,
        status: status == 'taken' ? IntakeStatus.taken : IntakeStatus.skipped,
        userId: authProvider.currentUser!.id,
      );

      // TODO: Save notes if provided
      if (_notesController.text.isNotEmpty) {
        // Save notes to backend
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medication marked as $_selectedAction')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medicine.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled: ${_formatTime(widget.scheduledTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            Text(
              'Action:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            RadioListTile<String>(
              title: const Text('Administered'),
              value: 'administered',
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Skipped'),
              value: 'skipped',
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            SizedBox(height: 16.h),
            Text(
              'Notes (optional):',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this medication...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            // TODO: Add prescription photo upload option
            // For now, this is a placeholder
            TextButton.icon(
              onPressed: () {
                // TODO: Implement photo upload
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo upload coming soon')),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload Prescription Photo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
