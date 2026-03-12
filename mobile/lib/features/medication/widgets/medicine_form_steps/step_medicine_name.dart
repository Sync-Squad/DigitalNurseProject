import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/medicine_form_provider.dart';

class StepMedicineName extends StatefulWidget {
  const StepMedicineName({super.key});

  @override
  State<StepMedicineName> createState() => _StepMedicineNameState();
}

class _StepMedicineNameState extends State<StepMedicineName> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Common medicine names for autocomplete
  static const List<String> _commonMedicines = [
    'Aspirin',
    'Ibuprofen',
    'Acetaminophen',
    'Paracetamol',
    'Metformin',
    'Lisinopril',
    'Amlodipine',
    'Simvastatin',
    'Omeprazole',
    'Losartan',
    'Gabapentin',
    'Hydrochlorothiazide',
    'Sertraline',
    'Tramadol',
    'Warfarin',
    'Furosemide',
    'Prednisone',
    'Trazodone',
    'Montelukast',
    'Albuterol',
    'Metoprolol',
    'Pantoprazole',
    'Doxycycline',
    'Citalopram',
    'Fluoxetine',
    'Vitamin D3',
    'Multivitamin',
    'Calcium',
    'Iron',
    'Folic Acid',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineFormProvider>();
    _nameController.text = provider.formData.name;
    _nameController.addListener(() {
      provider.setMedicineName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s the name of your medicine?',
                  style: context.theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                FTextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  label: const Text('Medicine Name'),
                  hint: 'Enter the name of your medicine',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Common medicines suggestions
        if (_nameController.text.isNotEmpty) _buildSuggestions(context),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final query = _nameController.text.toLowerCase();
    final suggestions = _commonMedicines
        .where(
          (medicine) =>
              medicine.toLowerCase().contains(query) &&
              medicine.toLowerCase() != query,
        )
        .take(5)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
            color: context.theme.colors.mutedForeground,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: suggestions.map((suggestion) {
            return InkWell(
              onTap: () {
                _nameController.text = suggestion;
                _nameController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.theme.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(suggestion, style: context.theme.typography.sm),
                    SizedBox(width: 8.w),
                    Icon(
                      FIcons.plus,
                      size: 16.r,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
