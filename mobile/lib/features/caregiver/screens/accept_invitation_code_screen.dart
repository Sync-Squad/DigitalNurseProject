import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';

class AcceptInvitationCodeScreen extends StatefulWidget {
  final String? inviteCode;
  final Map<String, dynamic>? invitation;
  final String? notificationId;

  const AcceptInvitationCodeScreen({
    super.key,
    this.inviteCode,
    this.invitation,
    this.notificationId,
  });

  @override
  State<AcceptInvitationCodeScreen> createState() =>
      _AcceptInvitationCodeScreenState();
}

class _AcceptInvitationCodeScreenState
    extends State<AcceptInvitationCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.inviteCode != null && widget.inviteCode!.isNotEmpty) {
      _codeController.text = widget.inviteCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an invitation code'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final caregiverService = CaregiverService();
      await caregiverService.acceptInvitationByCode(code);

      // Mark notification as read if notificationId is provided
      if (widget.notificationId != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notificationProvider.markAsRead(widget.notificationId!);
      }

      // Refresh will be handled by the home screen

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invitation accepted successfully!'),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        // Extract user-friendly error message
        String errorMessage = e.toString();
        // Remove "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        // Remove "Bad request: " prefix if present
        if (errorMessage.startsWith('Bad request: ')) {
          errorMessage = errorMessage.substring(13);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.getErrorColor(context),
            duration: const Duration(seconds: 4),
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
  Widget build(BuildContext context) {
    final patientName =
        widget.invitation?['patientName'] as String? ?? 'Patient';
    final relationship = widget.invitation?['relationship'] as String? ?? '';

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Accept Invitation'),
        prefixes: [FHeaderAction.back(onPress: () => context.pop())],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FIcons.userPlus,
                              color: context.theme.colors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'ve been invited!',
                                style: context.theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$patientName${relationship.isNotEmpty ? ' ($relationship)' : ''} has invited you to be their caregiver.',
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the invitation code that was sent to your email to accept this invitation.',
                          style: context.theme.typography.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Code input
                Text(
                  'Invitation Code',
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  child: TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Enter invitation code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invitation code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: _isLoading ? null : _handleAccept,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Accept Invitation'),
                  ),
                ),
                const SizedBox(height: 16),
                // Help text
                Center(
                  child: Text(
                    'Check your email for the invitation code',
                    style: context.theme.typography.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontStyle: FontStyle.italic,
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
