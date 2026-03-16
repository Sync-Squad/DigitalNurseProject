import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/models/diet_log_model.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/utils/timezone_util.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddMealScreen({super.key, this.selectedDate});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _openAIService = OpenAIService();

  MealType _mealType = MealType.breakfast;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _analysisError;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    // Initialize date and time from selectedDate or use current date/time
    final now = TimezoneUtil.nowInPakistan();
    _selectedDate = widget.selectedDate ?? now;
    _selectedTime = TimeOfDay.fromDateTime(now);

    // Clear error when user types in description
    _descriptionController.addListener(() {
      if (_analysisError != null && mounted) {
        setState(() {
          _analysisError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _handleAnalyze() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      setState(() {
        _analysisError = 'Please enter a food description first';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final calories = await _openAIService.analyzeFoodCalories(description);

      if (mounted) {
        if (calories != null && calories > 0) {
          setState(() {
            _caloriesController.text = calories.toString();
            _analysisError = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calculated: $calories calories'),
              backgroundColor: AppTheme.getSuccessColor(context),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _analysisError =
                'Unable to calculate calories. Please enter manually.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisError =
              'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    // Validate calories
    final caloriesText = _caloriesController.text.trim();
    if (caloriesText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter calories'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    final calories = int.tryParse(caloriesText);
    if (calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid calorie amount'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser!.id;

      // Combine selected date and time into a single DateTime
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final meal = DietLogModel(
        id: TimezoneUtil.nowInPakistan().millisecondsSinceEpoch.toString(),
        mealType: _mealType,
        description: _descriptionController.text.trim(),
        calories: calories,
        timestamp: timestamp,
        userId: userId,
      );

      final success = await context.read<LifestyleProvider>().addDietLog(meal);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Meal logged successfully'),
              backgroundColor: AppTheme.getSuccessColor(context),
            ),
          );
          context.pop();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Add Meal',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Meal Type Card
                Container(
                  decoration: ModernSurfaceTheme.glassCard(
                    context,
                    accent: ModernSurfaceTheme.primaryTeal,
                  ),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Type',
                        style: ModernSurfaceTheme.sectionTitleStyle(context),
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<MealType>(
                        value: _mealType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorScheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        items: MealType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.displayName,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _mealType = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Date and Time Selection
                Container(
                  decoration: ModernSurfaceTheme.glassCard(
                    context,
                    accent: ModernSurfaceTheme.primaryTeal,
                  ),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Time',
                        style: ModernSurfaceTheme.sectionTitleStyle(context),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy',
                                      ).format(_selectedDate),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Icon(
                                      FIcons.calendar,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _selectedTime = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedTime.format(context),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Icon(
                                      FIcons.clock,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Meal Details Card
                Container(
                  decoration: ModernSurfaceTheme.glassCard(
                    context,
                    accent: ModernSurfaceTheme.accentBlue,
                  ),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Details',
                        style: ModernSurfaceTheme.sectionTitleStyle(context),
                      ),
                      SizedBox(height: 16.h),
                      FTextField(
                        controller: _descriptionController,
                        label: const Text('Description'),
                        hint: 'e.g., "Grilled chicken and rice"',
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),
                      // Analyze Button with Gradient
                      Container(
                        width: double.infinity,
                        decoration: ModernSurfaceTheme.pillButton(
                          context,
                          ModernSurfaceTheme.accentBlue,
                        ),
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _handleAnalyze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isAnalyzing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(FIcons.sparkles, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isAnalyzing
                                    ? 'Analyzing...'
                                    : 'Analyze with AI',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_analysisError != null) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppTheme.getErrorColor(
                              context,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _analysisError!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.getErrorColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      FTextField(
                        controller: _caloriesController,
                        label: const Text('Calories'),
                        hint: 'Manual entry or AI estimate',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Save Button
                Container(
                  width: double.infinity,
                  decoration: ModernSurfaceTheme.pillButton(
                    context,
                    ModernSurfaceTheme.primaryTeal,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Meal Entry',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
