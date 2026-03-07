import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../providers/medicine_form_provider.dart';
import '../widgets/medicine_form_shared/form_step_container.dart';
import '../widgets/medicine_form_steps/step_medicine_name.dart';
import '../widgets/medicine_form_steps/step_medicine_form.dart';
import '../widgets/medicine_form_steps/step_frequency.dart';
import '../widgets/medicine_form_steps/step_schedule_times.dart';
import '../widgets/medicine_form_steps/step_start_date.dart';
import '../widgets/medicine_form_steps/step_dose_strength.dart';
import '../widgets/medicine_form_steps/step_summary.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicineFormProvider(),
      child: Consumer<MedicineFormProvider>(
        builder: (context, formProvider, child) {
          return ModernScaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context, formProvider),
                color: Colors.white,
              ),
              title: const Text(
                'Add Medicine',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: Container(
              padding: ModernSurfaceTheme.screenPadding(),
              child: Column(
                children: [
                  _ProgressHeader(
                    progress: formProvider.progress,
                    currentStep: formProvider.currentStep,
                    totalSteps: formProvider.totalSteps,
                  ),
                  if (formProvider.errorMessage != null) ...[
                    SizedBox(height: 16.h),
                    _ErrorNotice(message: formProvider.errorMessage!),
                  ],
                  SizedBox(height: 16.h),
                  Expanded(child: _buildStepContent(formProvider)),
                  _buildNavigationButtons(context, formProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(MedicineFormProvider formProvider) {
    switch (formProvider.currentStep) {
      case 0:
        return FormStepContainer(
          title: 'Medicine Name',
          description: 'Let\'s start with the basics',
          stepNumber: 0,
          child: const StepMedicineName(),
        );
      case 1:
        return FormStepContainer(
          title: 'Medicine Form',
          description: 'What form is your medicine in?',
          stepNumber: 1,
          child: const StepMedicineForm(),
        );
      case 2:
        return FormStepContainer(
          title: 'Frequency',
          description: 'How often do you take it?',
          stepNumber: 2,
          child: const StepFrequency(),
        );
      case 3:
        return FormStepContainer(
          title: 'Reminder Times',
          description: 'Set your reminder times',
          stepNumber: 3,
          child: const StepScheduleTimes(),
        );
      case 4:
        return FormStepContainer(
          title: 'Start Date',
          description: 'When do you start?',
          stepNumber: 4,
          child: const StepStartDate(),
        );
      case 5:
        return FormStepContainer(
          title: 'Dosage & Strength',
          description: 'Dosage and strength details',
          stepNumber: 5,
          child: const StepDoseStrength(),
        );
      case 6:
        return FormStepContainer(
          title: 'Review',
          description: 'Review before saving',
          stepNumber: 6,
          child: const StepSummary(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    MedicineFormProvider formProvider,
  ) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: Row(
          children: [
            if (!formProvider.isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => formProvider.previousStep(),
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
                  child: const Text('Back'),
                ),
              ),
            if (!formProvider.isFirstStep) SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: (_isSaving && formProvider.isLastStep)
                    ? null
                    : (formProvider.isLastStep
                          ? () => _handleSave(context, formProvider)
                          : () => formProvider.nextStep()),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  backgroundColor: AppTheme.appleGreen,
                  foregroundColor: Colors.white,
                ),
                child: (_isSaving && formProvider.isLastStep)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(formProvider.isLastStep ? 'Save Medicine' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, MedicineFormProvider formProvider) {
    if (formProvider.isFirstStep) {
      context.pop();
    } else {
      formProvider.previousStep();
    }
  }

  Future<void> _handleSave(
    BuildContext context,
    MedicineFormProvider formProvider,
  ) async {
    if (_isSaving) return;

    if (!formProvider.validateCurrentStep()) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    final medicine = formProvider.generateMedicineModel(userId);
    if (medicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await context.read<MedicationProvider>().addMedicine(
        medicine,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Medicine added successfully!'),
              backgroundColor: AppTheme.getSuccessColor(context),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to add medicine'),
              backgroundColor: AppTheme.getErrorColor(context),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int currentStep;
  final int totalSteps;

  const _ProgressHeader({
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: AppTheme.appleGreen,
        highlighted: true,
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ModernSurfaceTheme.deepTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10.h,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.appleGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
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
        ],
      ),
    );
  }
}
