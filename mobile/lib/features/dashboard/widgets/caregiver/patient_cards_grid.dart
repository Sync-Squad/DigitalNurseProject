import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/care_recipient_model.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/providers/lifestyle_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../dashboard_theme.dart';
import 'patient_card.dart';

class PatientCardsGrid extends StatefulWidget {
  final CareContextProvider careContext;
  final ValueChanged<String>? onPatientSelected;

  const PatientCardsGrid({
    super.key,
    required this.careContext,
    this.onPatientSelected,
  });

  @override
  State<PatientCardsGrid> createState() => _PatientCardsGridState();
}

class _PatientCardsGridState extends State<PatientCardsGrid> {
  Map<String, CareRecipientModel> _enrichedRecipients = {};
  bool _isEnriching = false;

  @override
  void initState() {
    super.initState();
    _enrichRecipients();
  }

  @override
  void didUpdateWidget(PatientCardsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.careContext.careRecipients !=
        widget.careContext.careRecipients) {
      _enrichRecipients();
    }
  }

  Future<void> _enrichRecipients() async {
    if (widget.careContext.isLoading || _isEnriching) {
      return;
    }

    setState(() {
      _isEnriching = true;
    });

    try {
      final healthProvider = context.read<HealthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final lifestyleProvider = context.read<LifestyleProvider>();

      final enriched = <String, CareRecipientModel>{};

      for (final recipient in widget.careContext.careRecipients) {
        try {
          final enrichedRecipient = await widget.careContext.enrichRecipient(
            recipient,
            healthProvider: healthProvider,
            medicationProvider: medicationProvider,
            lifestyleProvider: lifestyleProvider,
          );
          enriched[recipient.elderId] = enrichedRecipient;
        } catch (e) {
          // If enrichment fails, use original recipient
          enriched[recipient.elderId] = recipient;
        }
      }

      if (mounted) {
        setState(() {
          _enrichedRecipients = enriched;
          _isEnriching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnriching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.careContext.isLoading &&
        widget.careContext.careRecipients.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.theme.colors.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.careContext.error != null &&
        widget.careContext.careRecipients.isEmpty) {
      final errorColor = AppTheme.getErrorColor(context);
      return FCard(
        style: (cardStyle) => cardStyle.copyWith(
          decoration: cardStyle.decoration.copyWith(
            border: Border.all(color: errorColor),
            color: errorColor.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to load assigned patients',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.careContext.error!, style: context.theme.typography.xs),
          ],
        ),
      );
    }

    if (widget.careContext.careRecipients.isEmpty) {
      final highlightColor = context.theme.colors.primary;
      return FCard(
        style: (cardStyle) => cardStyle.copyWith(
          decoration: cardStyle.decoration.copyWith(
            border: Border.all(color: highlightColor),
            color: highlightColor.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No patients assigned yet',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once a patient invites you as a caregiver, their profile will appear here.',
              style: context.theme.typography.xs,
            ),
          ],
        ),
      );
    }

    final recipients = widget.careContext.careRecipients.map((recipient) {
      return _enrichedRecipients[recipient.elderId] ?? recipient;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Patients',
              style: CaregiverDashboardTheme.sectionTitleStyle(context),
            ),
            if (_isEnriching)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.theme.colors.primary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        ...recipients.map((patient) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: PatientCard(
              patient: patient,
              onTap: () {
                widget.onPatientSelected?.call(patient.elderId);
                context.push('/caregiver/patient/${patient.elderId}');
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
