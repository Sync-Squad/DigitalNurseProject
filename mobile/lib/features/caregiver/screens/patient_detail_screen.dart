import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/models/care_recipient_model.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/widgets/professional_avatar.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../widgets/vitals_summary_card.dart';
import '../widgets/medication_status_card.dart';
import '../widgets/diet_exercise_summary_card.dart';
import '../widgets/caregiver_notes_section.dart';
import '../widgets/emergency_alerts_section.dart';

class PatientDetailScreen extends StatefulWidget {
  final String elderId;

  const PatientDetailScreen({super.key, required this.elderId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  CareRecipientModel? _patient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final careContext = context.read<CareContextProvider>();
    await careContext.ensureLoaded();

    final patient = careContext.careRecipients.firstWhere(
      (r) => r.elderId == widget.elderId,
      orElse: () => throw Exception('Patient not found'),
    );

    // Enrich patient data
    final healthProvider = context.read<HealthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final lifestyleProvider = context.read<LifestyleProvider>();

    final enriched = await careContext.enrichRecipient(
      patient,
      healthProvider: healthProvider,
      medicationProvider: medicationProvider,
      lifestyleProvider: lifestyleProvider,
    );

    // Load patient-specific data
    await Future.wait([
      healthProvider.loadVitals(widget.elderId, elderUserId: widget.elderId),
      medicationProvider.loadMedicines(
        widget.elderId,
        elderUserId: widget.elderId,
      ),
      lifestyleProvider.loadAll(widget.elderId, elderUserId: widget.elderId),
    ]);

    if (mounted) {
      setState(() {
        _patient = enriched;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: Text('Patient not found')),
      );
    }

    final isStable = _patient!.status == PatientStatus.stable;
    final statusColor = isStable
        ? ModernSurfaceTheme.primaryTeal
        : ModernSurfaceTheme.accentCoral;
    final statusText = isStable ? 'Stable' : 'Needs Attention';

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _patient!.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        child: SingleChildScrollView(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient header
              _PatientHeader(
                patient: _patient!,
                statusColor: statusColor,
                statusText: statusText,
              ),
              SizedBox(height: 24.h),
              // Vitals summary
              VitalsSummaryCard(elderId: widget.elderId),
              SizedBox(height: 16.h),
              // Medication status
              MedicationStatusCard(elderId: widget.elderId),
              SizedBox(height: 16.h),
              // Diet & Exercise summary
              DietExerciseSummaryCard(elderId: widget.elderId),
              SizedBox(height: 16.h),
              // Emergency & Alerts
              EmergencyAlertsSection(
                elderId: widget.elderId,
                patientName: _patient!.name,
              ),
              SizedBox(height: 16.h),
              // Caregiver notes
              CaregiverNotesSection(elderId: widget.elderId),
              SizedBox(height: 16.h),
              // Quick actions
              _QuickActionsSection(
                patient: _patient!,
                onViewReports: () {
                  context.push('/caregiver/patient/${widget.elderId}/reports');
                },
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  final CareRecipientModel patient;
  final Color statusColor;
  final String statusText;

  const _PatientHeader({
    required this.patient,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.heroDecoration(context),
      child: Row(
        children: [
          // Patient photo
          ProfessionalAvatar(
            name: patient.name,
            userId: patient.elderId,
            avatarUrl: patient.avatarUrl,
            size: 80.w,
          ),
          SizedBox(width: 16.w),
          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (patient.age != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${patient.age} years old',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStable
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get isStable => patient.status == PatientStatus.stable;
}

class _QuickActionsSection extends StatelessWidget {
  final CareRecipientModel patient;
  final VoidCallback onViewReports;

  const _QuickActionsSection({
    required this.patient,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: _QuickActionButton(
              icon: Icons.assessment,
              label: 'View Reports',
              color: ModernSurfaceTheme.primaryTeal,
              onTap: onViewReports,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              SizedBox(width: 8.w),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
