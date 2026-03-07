import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/medicine_form_provider.dart';

class StepDoseStrength extends StatefulWidget {
  const StepDoseStrength({super.key});

  @override
  State<StepDoseStrength> createState() => _StepDoseStrengthState();
}

class _StepDoseStrengthState extends State<StepDoseStrength> {
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _strengthController = TextEditingController();
  String _selectedUnit = 'mg';

  static const List<String> _commonUnits = ['mg', 'ml', 'g', 'mcg', 'IU', '%'];

  static const List<String> _commonDoses = ['1', '2', '3', '1/2', '1/4', '5'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineFormProvider>();

    _doseController.text = provider.formData.doseAmount;

    // Parse existing strength to extract numeric part and unit
    final strength = provider.formData.strength;
    if (strength.isNotEmpty) {
      // Try to extract unit from end of string
      String? extractedUnit;
      String numericPart = strength;

      for (final unit in _commonUnits) {
        if (strength.endsWith(unit)) {
          extractedUnit = unit;
          numericPart = strength
              .substring(0, strength.length - unit.length)
              .trim();
          break;
        }
      }

      if (extractedUnit != null) {
        _selectedUnit = extractedUnit;
      }
      _strengthController.text = numericPart;
    }

    _doseController.addListener(() {
      provider.setDoseAmount(_doseController.text);
    });

    _strengthController.addListener(() {
      _updateStrength(provider);
    });
  }

  @override
  void dispose() {
    _doseController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineFormProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s the dose and strength?',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),

            // Dose Amount Section
            _buildDoseSection(context, provider),

            SizedBox(height: 24.h),

            // Strength Section
            _buildStrengthSection(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildDoseSection(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dose Amount',
          style: context.theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),

        // Quick select chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _commonDoses.map((dose) {
            final isSelected = _doseController.text == dose;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _doseController.text = dose;
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.appleGreen
                        : context.theme.colors.muted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.appleGreen
                          : context.theme.colors.border,
                    ),
                  ),
                  child: Text(
                    dose,
                    style: context.theme.typography.sm.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 16.h),

        // Custom dose input
        FTextField(
          controller: _doseController,
          label: const Text('Dose Amount'),
          hint: 'e.g., 1 tablet, 5ml, 2 pills',
        ),
      ],
    );
  }

  Widget _buildStrengthSection(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Strength',
          style: context.theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),

        // Unit chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _commonUnits.map((unit) {
            final isSelected = _selectedUnit == unit;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedUnit = unit;
                  });
                  _updateStrength(provider);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.appleGreen
                        : context.theme.colors.muted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.appleGreen
                          : context.theme.colors.border,
                    ),
                  ),
                  child: Text(
                    unit,
                    style: context.theme.typography.sm.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 16.h),

        // Amount input
        FTextField(
          controller: _strengthController,
          label: const Text('Amount'),
          hint: 'e.g., 500',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void _updateStrength(MedicineFormProvider provider) {
    if (_strengthController.text.trim().isNotEmpty) {
      provider.setStrength('${_strengthController.text.trim()}$_selectedUnit');
    } else {
      provider.setStrength('');
    }
  }
}
