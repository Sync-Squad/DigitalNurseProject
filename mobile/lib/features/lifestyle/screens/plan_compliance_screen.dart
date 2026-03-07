import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class PlanComplianceScreen extends StatefulWidget {
  final bool isDietPlan;
  final String planId;
  final String planName;

  const PlanComplianceScreen({
    super.key,
    required this.isDietPlan,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanComplianceScreen> createState() => _PlanComplianceScreenState();
}

class _PlanComplianceScreenState extends State<PlanComplianceScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _complianceData;
  bool _isLoading = false;
  String? _error;
  int _selectedView = 0; // 0 = calendar, 1 = daily breakdown, 2 = detailed

  @override
  void initState() {
    super.initState();
    _loadCompliance();
  }

  Future<void> _loadCompliance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lifestyleProvider = context.read<LifestyleProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (widget.isDietPlan) {
        _complianceData = await lifestyleProvider.getDietPlanCompliance(
          widget.planId,
          _startDate,
          _endDate,
        );
      } else {
        _complianceData = await lifestyleProvider.getExercisePlanCompliance(
          widget.planId,
          _startDate,
          _endDate,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days - 1));
      _loadCompliance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Plan Compliance',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading compliance data',
                    style: textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadCompliance,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _complianceData == null
          ? const Center(child: Text('No compliance data available'))
          : SingleChildScrollView(
              padding: ModernSurfaceTheme.screenPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with plan name and overall compliance
                  Container(
                    decoration: ModernSurfaceTheme.heroDecoration(context),
                    padding: ModernSurfaceTheme.heroPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.planName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Compliance',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${(_complianceData!['overallCompliance'] as num).toStringAsFixed(1)}%',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: Text(
                                  '${(_complianceData!['overallCompliance'] as num).toStringAsFixed(0)}%',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Date range selector
                  Row(
                    children: [
                      Expanded(
                        child: _DateRangeButton(
                          label: '7 Days',
                          isSelected:
                              _endDate.difference(_startDate).inDays == 6,
                          onTap: () => _selectDateRange(7),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _DateRangeButton(
                          label: '30 Days',
                          isSelected:
                              _endDate.difference(_startDate).inDays == 29,
                          onTap: () => _selectDateRange(30),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _DateRangeButton(
                          label: 'Custom',
                          isSelected:
                              _endDate.difference(_startDate).inDays != 6 &&
                              _endDate.difference(_startDate).inDays != 29,
                          onTap: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(
                                start: _startDate,
                                end: _endDate,
                              ),
                            );
                            if (range != null) {
                              setState(() {
                                _startDate = range.start;
                                _endDate = range.end;
                                _loadCompliance();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // View selector
                  Container(
                    decoration: ModernSurfaceTheme.glassCard(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ViewTab(
                            label: 'Calendar',
                            isSelected: _selectedView == 0,
                            onTap: () => setState(() => _selectedView = 0),
                          ),
                        ),
                        Expanded(
                          child: _ViewTab(
                            label: 'Daily',
                            isSelected: _selectedView == 1,
                            onTap: () => setState(() => _selectedView = 1),
                          ),
                        ),
                        Expanded(
                          child: _ViewTab(
                            label: 'Detailed',
                            isSelected: _selectedView == 2,
                            onTap: () => setState(() => _selectedView = 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Content based on selected view
                  if (_selectedView == 0)
                    _CalendarView(
                      complianceData: _complianceData!,
                      startDate: _startDate,
                      endDate: _endDate,
                    )
                  else if (_selectedView == 1)
                    _DailyBreakdownView(
                      complianceData: _complianceData!,
                      isDietPlan: widget.isDietPlan,
                    )
                  else
                    _DetailedComparisonView(
                      complianceData: _complianceData!,
                      isDietPlan: widget.isDietPlan,
                    ),
                ],
              ),
            ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateRangeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ModernSurfaceTheme.primaryTeal
              : ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : ModernSurfaceTheme.primaryTeal,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? ModernSurfaceTheme.primaryTeal
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? ModernSurfaceTheme.primaryTeal
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final Map<String, dynamic> complianceData;
  final DateTime startDate;
  final DateTime endDate;

  const _CalendarView({
    required this.complianceData,
    required this.startDate,
    required this.endDate,
  });

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final dailyBreakdown = complianceData['dailyBreakdown'] as List<dynamic>;
    final textTheme = Theme.of(context).textTheme;

    // Group by month
    final months = <DateTime, List<dynamic>>{};
    for (final day in dailyBreakdown) {
      final date = DateTime.parse(day['date']);
      final monthKey = DateTime(date.year, date.month, 1);
      if (!months.containsKey(monthKey)) {
        months[monthKey] = [];
      }
      months[monthKey]!.add(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: months.entries.map((entry) {
        final month = entry.key;
        final days = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final compliance = day['compliance'] as num;
                final date = DateTime.parse(day['date']);
                return Container(
                  decoration: BoxDecoration(
                    color: _getComplianceColor(
                      compliance.toDouble(),
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getComplianceColor(compliance.toDouble()),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${compliance.toStringAsFixed(0)}%',
                        style: textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),
          ],
        );
      }).toList(),
    );
  }
}

class _DailyBreakdownView extends StatefulWidget {
  final Map<String, dynamic> complianceData;
  final bool isDietPlan;

  const _DailyBreakdownView({
    required this.complianceData,
    required this.isDietPlan,
  });

  @override
  State<_DailyBreakdownView> createState() => _DailyBreakdownViewState();
}

class _DailyBreakdownViewState extends State<_DailyBreakdownView> {
  final Set<String> _expandedDays = {};

  void _toggleDay(String date) {
    setState(() {
      if (_expandedDays.contains(date)) {
        _expandedDays.remove(date);
      } else {
        _expandedDays.add(date);
      }
    });
  }

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final dailyBreakdown =
        widget.complianceData['dailyBreakdown'] as List<dynamic>;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: dailyBreakdown.map((day) {
        final date = DateTime.parse(day['date']);
        final compliance = day['compliance'] as num;
        final isExpanded = _expandedDays.contains(day['date']);
        final details = day['details'] as List<dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: ModernSurfaceTheme.glassCard(context),
          padding: ModernSurfaceTheme.cardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _toggleDay(day['date']),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(date),
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${day['matched']} of ${day['planned']} items completed',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getComplianceColor(
                          compliance.toDouble(),
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${compliance.toStringAsFixed(0)}%',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _getComplianceColor(compliance.toDouble()),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                SizedBox(height: 16.h),
                ...details.map((detail) {
                  final matched = detail['matched'] as bool;
                  final planned = detail['planned'];
                  final actual = detail['actual'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: matched
                          ? Colors.green.withValues(alpha: 0.1)
                          : (planned == null
                                ? Colors.grey.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: matched
                            ? Colors.green
                            : (planned == null ? Colors.grey : Colors.red),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          matched
                              ? Icons.check_circle
                              : (planned == null
                                    ? Icons.add_circle
                                    : Icons.cancel),
                          color: matched
                              ? Colors.green
                              : (planned == null ? Colors.grey : Colors.red),
                          size: 20,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (planned != null)
                                Text(
                                  'Planned: ${planned['description']}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (actual != null)
                                Text(
                                  'Actual: ${actual['description']}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailedComparisonView extends StatelessWidget {
  final Map<String, dynamic> complianceData;
  final bool isDietPlan;

  const _DetailedComparisonView({
    required this.complianceData,
    required this.isDietPlan,
  });

  @override
  Widget build(BuildContext context) {
    final dailyBreakdown = complianceData['dailyBreakdown'] as List<dynamic>;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: dailyBreakdown.map((day) {
        final date = DateTime.parse(day['date']);
        final details = day['details'] as List<dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: ModernSurfaceTheme.glassCard(context),
          padding: ModernSurfaceTheme.cardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(date),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planned',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ModernSurfaceTheme.primaryTeal,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...details.where((d) => d['planned'] != null).map((
                          detail,
                        ) {
                          final planned = detail['planned'];
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  planned['description'],
                                  style: textTheme.bodySmall,
                                ),
                                if (isDietPlan && planned['calories'] != null)
                                  Text(
                                    '${planned['calories']} cal',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else if (!isDietPlan &&
                                    planned['durationMinutes'] != null)
                                  Text(
                                    '${planned['durationMinutes']} min',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actual',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ModernSurfaceTheme.accentBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...details.where((d) => d['actual'] != null).map((
                          detail,
                        ) {
                          final actual = detail['actual'];
                          final matched = detail['matched'] as bool;
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: matched
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: matched
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (matched)
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                    if (matched) SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        actual['description'],
                                        style: textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isDietPlan && actual['calories'] != null)
                                  Text(
                                    '${actual['calories']} cal',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else if (!isDietPlan &&
                                    actual['durationMinutes'] != null)
                                  Text(
                                    '${actual['durationMinutes']} min',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
