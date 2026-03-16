import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class CalorieTrendsScreen extends StatefulWidget {
  const CalorieTrendsScreen({super.key});

  @override
  State<CalorieTrendsScreen> createState() => _CalorieTrendsScreenState();
}

class _CalorieTrendsScreenState extends State<CalorieTrendsScreen> {
  int _selectedDays = 7;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id;
    final lifestyleProvider = context.read<LifestyleProvider>();

    await lifestyleProvider.fetchTrendsData(userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lifestyleProvider = context.watch<LifestyleProvider>();

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Calorie Trends',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ModernSurfaceTheme.screenPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PeriodSelector(
                    selectedDays: _selectedDays,
                    onChanged: (days) {
                      setState(() {
                        _selectedDays = days;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildSummarySection(context, lifestyleProvider),
                  SizedBox(height: 24.h),
                  _buildChartSection(context, lifestyleProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, LifestyleProvider provider) {
    final dailyData = provider.getDailyCalorieData(_selectedDays);
    
    int totalIn = 0;
    int totalOut = 0;
    for (var data in dailyData.values) {
      totalIn += data['in']!;
      totalOut += data['out']!;
    }
    
    final avgIn = totalIn / _selectedDays;
    final avgOut = totalOut / _selectedDays;
    final avgNet = (totalIn - totalOut) / _selectedDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Averages (Last $_selectedDays Days)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _StatCard(
              label: 'Avg In',
              value: avgIn.round().toString(),
              color: AppTheme.appleGreen,
              unit: 'kcal',
            ),
            SizedBox(width: 12.w),
            _StatCard(
              label: 'Avg Out',
              value: avgOut.round().toString(),
              color: Colors.orange,
              unit: 'kcal',
            ),
            SizedBox(width: 12.w),
            _StatCard(
              label: 'Avg Net',
              value: avgNet.round().toString(),
              color: AppTheme.blueTertiary,
              unit: 'kcal',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, LifestyleProvider provider) {
    final dailyData = provider.getDailyCalorieData(_selectedDays);
    if (dailyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sortedDates = dailyData.keys.toList()..sort();
    
    // Calculate range for Y axis
    double maxY = 0;
    for (var data in dailyData.values) {
      final values = [data['in']!.toDouble(), data['out']!.toDouble(), data['net']!.toDouble()];
      for (var v in values) {
        if (v > maxY) maxY = v;
      }
    }
    
    // Add padding (10%)
    final range = maxY;
    final padding = range > 0 ? range * 0.1 : 500.0;
    final adjustedMinY = 0.0;
    final adjustedMaxY = maxY + padding;
    final horizontalInterval = (range > 0 ? (range / 4).roundToDouble() : 500.0).clamp(100.0, 1000.0);

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Trends',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 300.h,
            child: LineChart(
              LineChartData(
                minY: adjustedMinY,
                maxY: adjustedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _selectedDays > 14 ? 5 : 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedDates.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(sortedDates[index]),
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _createLine(sortedDates, dailyData, 'in', AppTheme.appleGreen),
                  _createLine(sortedDates, dailyData, 'out', Colors.orange),
                  _createLine(sortedDates, dailyData, 'net', AppTheme.blueTertiary),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = sortedDates[spot.x.toInt()];
                        final label = ['In', 'Out', 'Net'][spot.barIndex];
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n$label: ${spot.y.toInt()} kcal',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _ChartLegend(),
        ],
      ),
    );
  }

  LineChartBarData _createLine(List<DateTime> dates, Map<DateTime, Map<String, int>> data, String key, Color color) {
    return LineChartBarData(
      spots: dates.asMap().entries.map((e) {
        double val = data[e.value]![key]!.toDouble();
        if (val < 0) val = 0; // Clamp negative values to 0 for visualization
        return FlSpot(e.key.toDouble(), val);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.05),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: ModernSurfaceTheme.glassCard(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int selectedDays;
  final Function(int) onChanged;

  const _PeriodSelector({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [7, 14, 30].map((days) {
        final isSelected = selectedDays == days;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: ChoiceChip(
            label: Text('$days Days'),
            selected: isSelected,
            onSelected: (_) => onChanged(days),
            selectedColor: AppTheme.appleGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppTheme.appleGreen, label: 'In'),
        SizedBox(width: 16.w),
        _LegendItem(color: Colors.orange, label: 'Out'),
        SizedBox(width: 16.w),
        _LegendItem(color: AppTheme.blueTertiary, label: 'Net'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }
}
