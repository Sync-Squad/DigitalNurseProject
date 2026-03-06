import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_util.dart';
import 'expandable_section_tile.dart';

class VitalsSection extends StatelessWidget {
  const VitalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, healthProvider, child) {
        final recentVitals = healthProvider.vitals.take(3).toList();

        return ExpandableSectionTile(
          icon: Icons.monitor_heart, // ECG/heartbeat waveform icon
          title: 'dashboard.vitals'.tr(),
          subtitle: 'dashboard.viewDetails'.tr(),
          count: '${recentVitals.length}',
          titleColor: context.theme.colors.primary,
          routeForViewDetails: '/health',
          interactionMode: InteractionMode.standard,
          expandedChild: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recentVitals.isEmpty) ...[
                  Center(
                    child: Text(
                      'dashboard.noRecentVitals'.tr(),
                      style: TextStyle(
                        color: context.theme.colors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'dashboard.recentVitals'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recentVitals.map((vital) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: context.theme.colors.muted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.theme.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: vital.isAbnormal()
                                  ? AppTheme.getErrorColor(context)
                                  : AppTheme.getSuccessColor(context),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vital.type.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(
                                      TimezoneUtil.toPakistanTime(vital.timestamp),
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${vital.value} ${vital.type.unit}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: vital.isAbnormal()
                                        ? AppTheme.getErrorColor(context)
                                        : Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
