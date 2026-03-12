import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/caregiver_service.dart';
import '../../../../core/widgets/professional_avatar.dart';
import '../dashboard_theme.dart';
import 'patient_cards_grid.dart';
import '../../../../features/ai/widgets/ai_insights_dashboard_widget.dart';
import '../../../../features/caregiver/widgets/invitation_notification_card.dart';
// import 'caregiver_action_shortcuts.dart';
// import 'caregiver_overview_card.dart';

class CaregiverDashboardView extends StatefulWidget {
  final CareContextProvider careContext;
  final ValueChanged<String> onRecipientSelected;

  const CaregiverDashboardView({
    super.key,
    required this.careContext,
    required this.onRecipientSelected,
  });

  @override
  State<CaregiverDashboardView> createState() => _CaregiverDashboardViewState();
}

class _CaregiverDashboardViewState extends State<CaregiverDashboardView> {
  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _showAllInvitations = false;
  static const int _maxInitialInvitations = 2;

  @override
  void initState() {
    super.initState();
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    try {
      final caregiverService = CaregiverService();
      final invitations = await caregiverService.getPendingInvitations();
      if (mounted) {
        setState(() {
          _pendingInvitations = invitations;
          // Reset show all if invitations list becomes smaller
          if (_pendingInvitations.length <= _maxInitialInvitations) {
            _showAllInvitations = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading pending invitations: $e');
    }
  }

  Future<void> _refreshAll() async {
    // Refresh both invitations and care recipients
    await Future.wait([
      _loadPendingInvitations(),
      widget.careContext.refreshCareRecipients(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final caregiverName = currentUser?.name ?? 'Caregiver';
    final caregiverId = currentUser?.id ?? caregiverName;
    final patientCount = widget.careContext.careRecipients.length;
    final cardSpacing = 18.h;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 24.h,
          bottom: 40.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            _WelcomeMessage(
              caregiverName: caregiverName,
              caregiverId: caregiverId,
              patientCount: patientCount,
            ),
            SizedBox(height: 24.h),
            // Pending Invitations
            if (_pendingInvitations.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Invitations',
                    style: CaregiverDashboardTheme.sectionTitleStyle(context),
                  ),
                  if (_pendingInvitations.length > _maxInitialInvitations)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllInvitations = !_showAllInvitations;
                        });
                      },
                      child: Text(
                        _showAllInvitations
                            ? 'Show Less'
                            : 'View All (${_pendingInvitations.length})',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              ...(_showAllInvitations
                      ? _pendingInvitations
                      : _pendingInvitations.take(_maxInitialInvitations))
                  .map(
                    (invitation) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: InvitationNotificationCard(
                        invitation: invitation,
                        notificationId: invitation['notificationId'] as String?,
                        onAction: () {
                          // Refresh both invitations and care recipients
                          // This ensures new patients appear after accepting invitations
                          _refreshAll();
                        },
                      ),
                    ),
                  ),
              SizedBox(height: 24.h),
            ],
            PatientCardsGrid(
              careContext: widget.careContext,
              onPatientSelected: widget.onRecipientSelected,
            ),
            SizedBox(height: cardSpacing),
            if (widget.careContext.selectedElderId != null)
              AIInsightsDashboardWidget(
                elderUserId: int.tryParse(
                  widget.careContext.selectedElderId ?? '',
                ),
              ),
            if (widget.careContext.selectedElderId != null)
              SizedBox(height: cardSpacing),
            // const CaregiverOverviewCard(),
            // SizedBox(height: cardSpacing),
            // const CaregiverActionShortcuts(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  final String caregiverName;
  final String caregiverId;
  final int patientCount;

  const _WelcomeMessage({
    required this.caregiverName,
    required this.caregiverId,
    required this.patientCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.glassCard(context, highlighted: true),
      child: Row(
        children: [
          ProfessionalAvatar(
            name: caregiverName,
            userId: caregiverId,
            size: 48.w,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: CaregiverDashboardTheme.sectionSubtitleStyle(context),
                ),
                SizedBox(height: 4.h),
                Text(
                  caregiverName,
                  style: CaregiverDashboardTheme.sectionTitleStyle(context),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$patientCount ${patientCount == 1 ? 'patient' : 'patients'}',
                  style: CaregiverDashboardTheme.sectionSubtitleStyle(
                    context,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
