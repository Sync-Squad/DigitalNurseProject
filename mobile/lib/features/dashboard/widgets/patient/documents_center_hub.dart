import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../dashboard_theme.dart';
import 'package:digital_nurse/features/dashboard/widgets/dashboard_hub_card.dart';

class DocumentsCenterHub extends StatelessWidget {
  const DocumentsCenterHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardHubCard(
      title: 'patient.documents'.tr(),
      icon: Icons.description_rounded,
      accentColor: CaregiverDashboardTheme.primaryTeal,
      actions: [
            HubAction(
              label: 'View Documents',
              icon: Icons.folder_open_rounded,
              onTap: () => context.push('/documents'),
            ),
            HubAction(
              label: 'Add Document',
              icon: Icons.upload_file_rounded,
              onTap: () => context.push('/documents/upload'),
            ),
      ],
    );
  }
}
