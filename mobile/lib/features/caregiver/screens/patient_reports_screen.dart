import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/alert_history_timeline.dart';

class PatientReportsScreen extends StatefulWidget {
  final String elderId;

  const PatientReportsScreen({super.key, required this.elderId});

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final healthProvider = context.read<HealthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final lifestyleProvider = context.read<LifestyleProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    await Future.wait([
      healthProvider.loadVitals(widget.elderId, elderUserId: widget.elderId),
      medicationProvider.loadMedicines(
        widget.elderId,
        elderUserId: widget.elderId,
      ),
      lifestyleProvider.loadAll(widget.elderId, elderUserId: widget.elderId),
      notificationProvider.loadNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Patient Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportView(elderId: widget.elderId, period: 'weekly'),
          _ReportView(elderId: widget.elderId, period: 'monthly'),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final String elderId;
  final String period;

  const _ReportView({required this.elderId, required this.period});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final healthProvider = context.read<HealthProvider>();
        final medicationProvider = context.read<MedicationProvider>();
        final lifestyleProvider = context.read<LifestyleProvider>();

        await Future.wait([
          healthProvider.loadVitals(elderId, elderUserId: elderId),
          medicationProvider.loadMedicines(elderId, elderUserId: elderId),
          lifestyleProvider.loadAll(elderId, elderUserId: elderId),
        ]);
      },
      child: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report summary
            ReportSummaryCard(elderId: elderId, period: period),
            SizedBox(height: 24.h),
            // Health trends
            _SectionHeader(
              title: 'Health Trends',
              onViewAll: () => context.push('/health/trends'),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: ModernSurfaceTheme.cardPadding(),
              decoration: ModernSurfaceTheme.glassCard(context),
              child: const HealthTrendsPreview(),
            ),
            SizedBox(height: 24.h),
            // Medication adherence
            _SectionHeader(title: 'Medication Adherence'),
            SizedBox(height: 12.h),
            AdherenceChart(elderId: elderId, period: period),
            SizedBox(height: 24.h),
            // Activity & diet summary
            _SectionHeader(title: 'Activity & Diet Summary'),
            SizedBox(height: 12.h),
            Container(
              padding: ModernSurfaceTheme.cardPadding(),
              decoration: ModernSurfaceTheme.glassCard(context),
              child: Consumer<LifestyleProvider>(
                builder: (context, provider, _) {
                  final summary = provider.dailySummary ?? {};
                  return Column(
                    children: [
                      _SummaryRow(
                        label: 'Total Calories',
                        value: '${summary['totalCaloriesIn'] ?? 0}',
                      ),
                      SizedBox(height: 12.h),
                      _SummaryRow(
                        label: 'Exercise Minutes',
                        value: '${summary['totalExerciseMinutes'] ?? 0}',
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
            // Alert history
            _SectionHeader(title: 'Alert History'),
            SizedBox(height: 12.h),
            AlertHistoryTimeline(elderId: elderId, period: period),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: ModernSurfaceTheme.sectionTitleStyle(context)),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class HealthTrendsPreview extends StatelessWidget {
  const HealthTrendsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'View detailed health trends and graphs',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          onPressed: () => context.push('/health/trends'),
          child: const Text('View Health Trends'),
        ),
      ],
    );
  }
}
