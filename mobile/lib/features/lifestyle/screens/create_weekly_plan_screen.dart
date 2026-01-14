import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/diet_plan_model.dart';
import '../../../core/models/exercise_plan_model.dart';
import '../../../core/models/diet_log_model.dart';
import '../../../core/models/exercise_log_model.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class CreateWeeklyPlanScreen extends StatefulWidget {
  final bool isDietPlan;
  final String? planId; // If provided, we're editing

  const CreateWeeklyPlanScreen({
    super.key,
    required this.isDietPlan,
    this.planId,
  });

  @override
  State<CreateWeeklyPlanScreen> createState() => _CreateWeeklyPlanScreenState();
}

class _CreateWeeklyPlanScreenState extends State<CreateWeeklyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Map of dayOfWeek (0-6) to list of items
  final Map<int, List<dynamic>> _itemsByDay = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeDays();
    if (widget.planId != null) {
      _loadPlan();
    }
  }

  void _initializeDays() {
    for (int i = 0; i < 7; i++) {
      _itemsByDay[i] = [];
    }
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lifestyleProvider = context.read<LifestyleProvider>();
      dynamic plan;

      if (widget.isDietPlan) {
        await lifestyleProvider.loadDietPlans();
        plan = lifestyleProvider.dietPlans.firstWhere((p) => p.id == widget.planId);
      } else {
        await lifestyleProvider.loadExercisePlans();
        plan = lifestyleProvider.exercisePlans.firstWhere((p) => p.id == widget.planId);
      }

      _planNameController.text = plan.planName;
      _descriptionController.text = plan.description;

      // Group items by day
      _itemsByDay.clear();
      _initializeDays();
      for (final item in plan.items) {
        if (!_itemsByDay.containsKey(item.dayOfWeek)) {
          _itemsByDay[item.dayOfWeek] = [];
        }
        _itemsByDay[item.dayOfWeek]!.add(item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plan: ${e.toString()}'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addItem(int dayOfWeek) {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        dayOfWeek: dayOfWeek,
        isDietPlan: widget.isDietPlan,
        onAdd: (item) {
          setState(() {
            _itemsByDay[dayOfWeek]!.add(item);
          });
        },
      ),
    );
  }

  void _removeItem(int dayOfWeek, int index) {
    setState(() {
      _itemsByDay[dayOfWeek]!.removeAt(index);
    });
  }

  void _editItem(int dayOfWeek, int index) {
    final item = _itemsByDay[dayOfWeek]![index];
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        dayOfWeek: dayOfWeek,
        isDietPlan: widget.isDietPlan,
        existingItem: item,
        onAdd: (updatedItem) {
          setState(() {
            _itemsByDay[dayOfWeek]![index] = updatedItem;
          });
        },
      ),
    );
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_planNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a plan name'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final lifestyleProvider = context.read<LifestyleProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Collect all items
      final allItems = <dynamic>[];
      for (int day = 0; day < 7; day++) {
        for (final item in _itemsByDay[day]!) {
          allItems.add(item);
        }
      }

      if (widget.isDietPlan) {
        final plan = DietPlanModel(
          id: widget.planId ?? '',
          planName: _planNameController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: true,
          userId: userId,
          items: allItems.cast<DietPlanItemModel>(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.planId != null) {
          await lifestyleProvider.updateDietPlan(widget.planId!, plan);
        } else {
          await lifestyleProvider.createDietPlan(plan);
        }
      } else {
        final plan = ExercisePlanModel(
          id: widget.planId ?? '',
          planName: _planNameController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: true,
          userId: userId,
          items: allItems.cast<ExercisePlanItemModel>(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.planId != null) {
          await lifestyleProvider.updateExercisePlan(widget.planId!, plan);
        } else {
          await lifestyleProvider.createExercisePlan(plan);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.planId != null ? 'Plan updated successfully' : 'Plan created successfully'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: ${e.toString()}'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
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
    final onPrimary = colorScheme.onPrimary;

    if (_isLoading) {
      return ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.planId != null ? 'Edit Plan' : 'Create Plan',
            style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onPrimary,
                ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.planId != null
              ? 'Edit ${widget.isDietPlan ? 'Diet' : 'Workout'} Plan'
              : 'Create ${widget.isDietPlan ? 'Diet' : 'Workout'} Plan',
          style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onPrimary,
              ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan name and description
                      Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: ModernSurfaceTheme.glassCard(context),
                        padding: ModernSurfaceTheme.cardPadding(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _planNameController,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Plan Name',
                                labelStyle: const TextStyle(color: Colors.black54),
                                hintText: 'e.g., Weekly Weight Loss Plan',
                                hintStyle: const TextStyle(color: Colors.black38),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a plan name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                labelStyle: const TextStyle(color: Colors.black54),
                                hintText: 'Describe your plan',
                                hintStyle: const TextStyle(color: Colors.black38),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Weekly calendar
                      Text(
                        'Weekly Schedule',
                        style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 16.h),
                      ...List.generate(7, (index) {
                        return _DaySection(
                          dayOfWeek: index,
                          items: _itemsByDay[index]!,
                          isDietPlan: widget.isDietPlan,
                          onAddItem: () => _addItem(index),
                          onRemoveItem: (itemIndex) => _removeItem(index, itemIndex),
                          onEditItem: (itemIndex) => _editItem(index, itemIndex),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Save button
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.appleGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.planId != null ? 'Update Plan' : 'Create Plan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final int dayOfWeek;
  final List<dynamic> items;
  final bool isDietPlan;
  final VoidCallback onAddItem;
  final Function(int) onRemoveItem;
  final Function(int) onEditItem;

  const _DaySection({
    required this.dayOfWeek,
    required this.items,
    required this.isDietPlan,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onEditItem,
  });

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayNames[dayOfWeek],
                style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: onAddItem,
                icon: const Icon(FIcons.plus, size: 16),
                label: Text(isDietPlan ? 'Add Meal' : 'Add Workout'),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No ${isDietPlan ? 'meals' : 'workouts'} scheduled',
                style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _ItemCard(
                item: item,
                isDietPlan: isDietPlan,
                onRemove: () => onRemoveItem(index),
                onEdit: () => onEditItem(index),
              );
            }),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final bool isDietPlan;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _ItemCard({
    required this.item,
    required this.isDietPlan,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDietPlan
                      ? (item as DietPlanItemModel).mealType.displayName
                      : (item as ExercisePlanItemModel).activityType.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.description,
                  style: textTheme.bodySmall,
                ),
                if (isDietPlan)
                  Text(
                    '${item.calories} calories',
                    style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  Text(
                    '${item.durationMinutes} min • ${item.caloriesBurned} cal',
                    style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            color: colorScheme.primary,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onRemove,
            color: Colors.red,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final int dayOfWeek;
  final bool isDietPlan;
  final Function(dynamic) onAdd;
  final dynamic existingItem;

  const _AddItemDialog({
    required this.dayOfWeek,
    required this.isDietPlan,
    required this.onAdd,
    this.existingItem,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();
  final _notesController = TextEditingController();

  MealType _mealType = MealType.breakfast;
  ActivityType _activityType = ActivityType.walking;
  String _intensity = 'moderate';

  @override
  void initState() {
    super.initState();
    // If editing an existing item, populate the fields
    if (widget.existingItem != null) {
      if (widget.isDietPlan) {
        final item = widget.existingItem as DietPlanItemModel;
        _mealType = item.mealType;
        _descriptionController.text = item.description;
        _caloriesController.text = item.calories.toString();
        _notesController.text = item.notes;
      } else {
        final item = widget.existingItem as ExercisePlanItemModel;
        _activityType = item.activityType;
        _descriptionController.text = item.description;
        _durationController.text = item.durationMinutes.toString();
        _caloriesBurnedController.text = item.caloriesBurned.toString();
        _intensity = item.intensity;
        _notesController.text = item.notes;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _caloriesBurnedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a description'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    dynamic item;
    // Preserve the existing ID when editing, or generate a new one when adding
    final String itemId = widget.existingItem != null
        ? (widget.isDietPlan
            ? (widget.existingItem as DietPlanItemModel).id
            : (widget.existingItem as ExercisePlanItemModel).id)
        : DateTime.now().millisecondsSinceEpoch.toString();

    if (widget.isDietPlan) {
      item = DietPlanItemModel(
        id: itemId,
        dayOfWeek: widget.dayOfWeek,
        mealType: _mealType,
        description: _descriptionController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 0,
        notes: _notesController.text.trim(),
      );
    } else {
      item = ExercisePlanItemModel(
        id: itemId,
        dayOfWeek: widget.dayOfWeek,
        activityType: _activityType,
        description: _descriptionController.text.trim(),
        durationMinutes: int.tryParse(_durationController.text) ?? 0,
        caloriesBurned: int.tryParse(_caloriesBurnedController.text) ?? 0,
        intensity: _intensity,
        notes: _notesController.text.trim(),
      );
    }

    widget.onAdd(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('${widget.existingItem != null ? 'Edit' : 'Add'} ${widget.isDietPlan ? 'Meal' : 'Workout'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isDietPlan) ...[
              Text('Meal Type', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<MealType>(
                value: _mealType,
                items: MealType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _mealType = value;
                    });
                  }
                },
              ),
            ] else ...[
              Text('Activity Type', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<ActivityType>(
                value: _activityType,
                items: ActivityType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activityType = value;
                    });
                  }
                },
              ),
            ],
            SizedBox(height: 16.h),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: widget.isDietPlan ? 'Food Description' : 'Exercise Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16.h),
            if (widget.isDietPlan) ...[
              TextField(
                controller: _caloriesController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              TextField(
                controller: _durationController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _caloriesBurnedController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Calories Burned',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              Text('Intensity', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _intensity,
                items: ['low', 'moderate', 'high'].map((intensity) {
                  return DropdownMenuItem(
                    value: intensity,
                    child: Text(intensity.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _intensity = value;
                    });
                  }
                },
              ),
            ],
            SizedBox(height: 16.h),
            TextField(
              controller: _notesController,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: Text(widget.existingItem != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

