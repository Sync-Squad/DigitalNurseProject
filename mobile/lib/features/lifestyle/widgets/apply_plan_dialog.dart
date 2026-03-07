import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ApplyPlanDialog extends StatefulWidget {
  final String planId;
  final bool isDietPlan;

  const ApplyPlanDialog({
    super.key,
    required this.planId,
    required this.isDietPlan,
  });

  @override
  State<ApplyPlanDialog> createState() => _ApplyPlanDialogState();
}

class _ApplyPlanDialogState extends State<ApplyPlanDialog> {
  DateTime _startDate = DateTime.now();
  bool _overwriteExisting = false;
  bool _isApplying = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _applyPlan() async {
    setState(() {
      _isApplying = true;
    });

    try {
      final lifestyleProvider = context.read<LifestyleProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      Map<String, dynamic> result;
      if (widget.isDietPlan) {
        result = await lifestyleProvider.applyDietPlan(
          widget.planId,
          _startDate,
          _overwriteExisting,
        );
      } else {
        result = await lifestyleProvider.applyExercisePlan(
          widget.planId,
          _startDate,
          _overwriteExisting,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Plan applied successfully'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply plan: ${e.toString()}'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Apply ${widget.isDietPlan ? 'Diet' : 'Workout'} Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Date',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_startDate),
                      style: textTheme.bodyLarge,
                    ),
                    Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Checkbox(
                  value: _overwriteExisting,
                  onChanged: (value) {
                    setState(() {
                      _overwriteExisting = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Overwrite existing logs for the week',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'If unchecked, days with existing logs will be skipped.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isApplying ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isApplying ? null : _applyPlan,
          child: _isApplying
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply'),
        ),
      ],
    );
  }
}
