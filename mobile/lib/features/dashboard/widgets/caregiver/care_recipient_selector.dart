import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/care_recipient_model.dart';
import '../../../../core/theme/app_theme.dart';

class CareRecipientSelector extends StatelessWidget {
  final bool isLoading;
  final List<CareRecipientModel> recipients;
  final CareRecipientModel? selectedRecipient;
  final String? error;
  final ValueChanged<String> onSelect;

  const CareRecipientSelector({
    super.key,
    required this.isLoading,
    required this.recipients,
    required this.selectedRecipient,
    required this.error,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && recipients.isEmpty) {
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

    if (error != null && recipients.isEmpty) {
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
              'Unable to load assigned elders',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(error!, style: context.theme.typography.xs),
          ],
        ),
      );
    }

    if (recipients.isEmpty) {
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
              'No elders assigned yet',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once an elder invites you as a caregiver, their profile will appear here.',
              style: context.theme.typography.xs,
            ),
          ],
        ),
      );
    }

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Managing care for',
            style: context.theme.typography.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedRecipient?.elderId,
            items: recipients
                .map(
                  (recipient) => DropdownMenuItem<String>(
                    value: recipient.elderId,
                    child: Text(
                      recipient.name,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onSelect(value);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (selectedRecipient?.relationship != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  'Relation: ${selectedRecipient!.relationship!}',
                  style: context.theme.typography.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
