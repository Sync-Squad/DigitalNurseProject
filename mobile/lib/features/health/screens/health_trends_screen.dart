import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class HealthTrendsScreen extends StatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  VitalType _selectedType = VitalType.bloodPressure;
  int _selectedDays = 7;
  Map<String, dynamic>? _trends;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id;

    final trends = await context.read<HealthProvider>().calculateTrends(
      userId,
      _selectedType,
      days: _selectedDays,
    );

    if (mounted) {
      setState(() {
        _trends = trends;
        _isLoading = false;
      });
    }
  }

  List<_ChartDataPoint> _getChartData() {
    if (_trends == null || _trends!['measurements'] == null) {
      return [];
    }

    final measurements = _trends!['measurements'] as List;
    if (measurements.isEmpty) return [];

    final List<_ChartDataPoint> dataPoints = [];

    for (final measurement in measurements) {
      if (measurement is VitalMeasurementModel) {
        double value;
        if (_selectedType == VitalType.bloodPressure) {
          // Extract systolic value from "120/80" format
          final parts = measurement.value.split('/');
          if (parts.isNotEmpty) {
            value = double.tryParse(parts[0]) ?? 0;
          } else {
            value = 0;
          }
        } else {
          value = double.tryParse(measurement.value) ?? 0;
        }

        if (value > 0) {
          dataPoints.add(
            _ChartDataPoint(date: measurement.timestamp, value: value),
          );
        }
      }
    }

    // Sort by date
    dataPoints.sort((a, b) => a.date.compareTo(b.date));
    return dataPoints;
  }

  Map<String, double> _getBarChartData() {
    final chartData = _getChartData();
    if (chartData.isEmpty) return {};

    final Map<String, List<double>> groupedData = {};

    for (final point in chartData) {
      final key = DateFormat('MM/dd').format(point.date);
      groupedData.putIfAbsent(key, () => []);
      groupedData[key]!.add(point.value);
    }

    // Calculate average for each day
    final Map<String, double> averages = {};
    groupedData.forEach((key, values) {
      averages[key] = values.reduce((a, b) => a + b) / values.length;
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.pop();
        }
      },
      child: ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Health Trends',
            style: textTheme.titleLarge?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrendsHero(selectedType: _selectedType, days: _selectedDays),
              SizedBox(height: 16.h),
              // Vital Type Selector
              _GlassFormSection(
                title: 'Select Vital Type',
                child: DropdownButton<VitalType>(
                  value: _selectedType,
                  isExpanded: true,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  items: VitalType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                      _loadTrends();
                    }
                  },
                ),
              ),
              SizedBox(height: 16.h),

              // Time Period Chips
              _GlassFormSection(
                title: 'Time Period',
                child: Row(
                  children: [7, 14, 30].map((days) {
                    final isSelected = _selectedDays == days;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: days != 30 ? 8.w : 0),
                        child: _TimePeriodChip(
                          label: '$days days',
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedDays = days;
                            });
                            _loadTrends();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24.h),

              // Content
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_trends == null || _trends!['count'] == 0)
                _buildEmptyState(context)
              else
                _buildTrendsContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FIcons.activity, size: 48.r, color: colorScheme.primary),
          SizedBox(height: 16.h),
          Text(
            'No data available for this period',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Try selecting a different time period or vital type',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartData = _getChartData();
    final barChartData = _getBarChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Section Title
        Text(
          'Summary',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),

        // Stats Cards Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: ModernSurfaceTheme.glassCard(context),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_trends!['average'].toStringAsFixed(1)}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.appleGreen,
                      ),
                    ),
                    Text(
                      _selectedType.unit,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                decoration: ModernSurfaceTheme.glassCard(context),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Readings',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_trends!['count']}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.appleGreen,
                      ),
                    ),
                    Text(
                      'total',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // Line Chart Section
        if (chartData.length >= 2) ...[
          Text(
            'Trend Over Time',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              height: 200.h,
              child: _TrendsLineChart(
                dataPoints: chartData,
                unit: _selectedType.unit,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        // Bar Chart Section
        if (barChartData.isNotEmpty) ...[
          Text(
            'Daily Readings',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              height: 200.h,
              child: _TrendsBarChart(
                data: barChartData,
                unit: _selectedType.unit,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],

        // Abnormal Warning
        if (_trends!['hasAbnormal'] == true) ...[
          Container(
            decoration: ModernSurfaceTheme.glassCard(
              context,
              accent: AppTheme.getWarningColor(context),
            ),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: ModernSurfaceTheme.iconBadge(
                    context,
                    AppTheme.getWarningColor(context),
                  ),
                  child: Icon(FIcons.info, color: Colors.white, size: 20.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Some readings are outside normal range. Consider consulting your healthcare provider.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartDataPoint {
  final DateTime date;
  final double value;

  _ChartDataPoint({required this.date, required this.value});
}

class _GlassFormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassFormSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class _TimePeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimePeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.appleGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.appleGreen
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: Colors.white),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendsLineChart extends StatelessWidget {
  final List<_ChartDataPoint> dataPoints;
  final String unit;

  const _TrendsLineChart({required this.dataPoints, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final minY = dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    final adjustedMinY = (minY - padding)
        .clamp(0.0, double.infinity)
        .toDouble();
    final adjustedMaxY = maxY + padding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (adjustedMaxY - adjustedMinY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dataPoints.length) {
                  return const SizedBox.shrink();
                }
                // Show only first, middle, and last labels
                if (index == 0 ||
                    index == dataPoints.length - 1 ||
                    index == dataPoints.length ~/ 2) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(dataPoints[index].date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: (adjustedMaxY - adjustedMinY) / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dataPoints.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.appleGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppTheme.appleGreen,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.appleGreen.withOpacity(0.3),
                  AppTheme.appleGreen.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.appleGreen,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = dataPoints[index].date;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $unit\n${DateFormat('MMM d').format(date)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _TrendsBarChart extends StatelessWidget {
  final Map<String, double> data;
  final String unit;

  const _TrendsBarChart({required this.data, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = data.entries.toList();
    final maxY = data.values.reduce((a, b) => a > b ? a : b);
    final minY = data.values.reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY) * 0.15;
    final adjustedMaxY = maxY + padding;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: adjustedMaxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.appleGreen,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = entries[group.x.toInt()].key;
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} $unit\n$label',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    entries[index].key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: adjustedMaxY / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: adjustedMaxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: AppTheme.appleGreen,
                width: 20.w,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: adjustedMaxY,
                  color: AppTheme.appleGreen.withOpacity(0.1),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TrendsHero extends StatelessWidget {
  final VitalType selectedType;
  final int days;

  const _TrendsHero({required this.selectedType, required this.days});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    final h = ModernSurfaceTheme.heroPadding();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth * 0.45;
          return Container(
            width: double.infinity,
            decoration: ModernSurfaceTheme.heroDecoration(context),
            child: Stack(
              children: [
                // ── Right 50%: image pinned to right edge ─────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: halfWidth * 1.9,
                  child: Image.asset(
                    'assets/images/health.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
                // ── Left side: text column drives card height ─────────
                Padding(
                  padding: EdgeInsets.only(
                    left: h.left,
                    top: h.top,
                    bottom: h.bottom,
                    right: halfWidth + h.right,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Health Insights',
                        style: textTheme.bodyMedium?.copyWith(
                          color: onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${selectedType.displayName} Trends',
                        style: textTheme.headlineSmall?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppTheme.appleGreen,
                        ),
                        child: Text(
                          'Last $days days',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
