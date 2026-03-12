import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';

class InvitationNotificationCard extends StatelessWidget {
  final Map<String, dynamic> invitation;
  final String? notificationId;
  final VoidCallback? onAction;

  const InvitationNotificationCard({
    super.key,
    required this.invitation,
    this.notificationId,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final patientName = invitation['patientName'] as String? ?? 'Patient';
    final relationship = invitation['relationship'] as String? ?? '';
    final inviteCode = invitation['inviteCode'] as String? ?? '';

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FIcons.userPlus,
                    color: context.theme.colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Caregiver Invitation',
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$patientName${relationship.isNotEmpty ? ' ($relationship)' : ''} has invited you to be their caregiver',
                        style: context.theme.typography.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDecline(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.theme.colors.foreground,
                      side: BorderSide(color: context.theme.colors.border),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    onPress: () => _handleAccept(context, inviteCode),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccept(BuildContext context, String inviteCode) {
    // Navigate to accept invitation code screen
    context
        .push(
          '/caregiver/accept-invitation-code',
          extra: {
            'inviteCode': inviteCode,
            'invitation': invitation,
            'notificationId': notificationId,
          },
        )
        .then((result) {
          // Always refresh the list when returning from accept screen
          // This removes already-processed invitations even if acceptance failed
          if (onAction != null) {
            onAction!();
          }
        });
  }

  Future<void> _handleDecline(BuildContext context) async {
    final caregiverService = CaregiverService();
    final invitationId = invitation['id'] as String?;

    if (invitationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to decline invitation'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    try {
      await caregiverService.declineInvitation(invitationId);

      // Mark notification as read if notificationId is provided
      if (notificationId != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notificationProvider.markAsRead(notificationId!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invitation declined'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
        // Refresh the list
        if (onAction != null) {
          onAction!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }
}
