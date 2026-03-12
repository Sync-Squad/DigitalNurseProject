import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../widgets/medication_action_dialog.dart';

class MedicationManagementScreen extends StatefulWidget {
  final String elderId;

  const MedicationManagementScreen({super.key, required this.elderId});

  @override
  State<MedicationManagementScreen> createState() =>
      _MedicationManagementScreenState();
}

class _MedicationManagementScreenState
    extends State<MedicationManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final medicationProvider = context.read<MedicationProvider>();
    await medicationProvider.loadMedicines(
      widget.elderId,
      elderUserId: widget.elderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final medicines = medicationProvider.medicines;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Medication Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMedications,
        child: medicines.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_liquid,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No medications found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: ModernSurfaceTheme.screenPadding(),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return _MedicationManagementItem(
                    medicine: medicine,
                    elderId: widget.elderId,
                  );
                },
              ),
      ),
    );
  }
}

class _MedicationManagementItem extends StatelessWidget {
  final MedicineModel medicine;
  final String elderId;

  const _MedicationManagementItem({
    required this.medicine,
    required this.elderId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ModernSurfaceTheme.primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  size: 24,
                  color: ModernSurfaceTheme.primaryTeal,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${medicine.dosage} • ${medicine.reminderTimes.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Today's schedule
          Text(
            'Today\'s Schedule',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          ...medicine.reminderTimes.map(
            (time) => _MedicationTimeItem(
              medicine: medicine,
              time: time,
              elderId: elderId,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationTimeItem extends StatelessWidget {
  final MedicineModel medicine;
  final String time;
  final String elderId;

  const _MedicationTimeItem({
    required this.medicine,
    required this.time,
    required this.elderId,
  });

  @override
  Widget build(BuildContext context) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final scheduledTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
      minute,
    );
    final isPast = scheduledTime.isBefore(DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  isPast ? 'Past due' : 'Upcoming',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MedicationActionDialog(
                  medicine: medicine,
                  scheduledTime: scheduledTime,
                  elderId: elderId,
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Mark'),
          ),
        ],
      ),
    );
  }
}
