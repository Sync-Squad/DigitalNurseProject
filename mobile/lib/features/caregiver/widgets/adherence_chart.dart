import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';

class AdherenceChart extends StatelessWidget {
  final String elderId;
  final String period; // 'weekly' or 'monthly'

  const AdherenceChart({
    super.key,
    required this.elderId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final adherence = medicationProvider.adherencePercentage;

    // Generate sample data for the chart
    // In a real implementation, this would come from the backend
    final days = period == 'weekly' ? 7 : 30;
    final chartData = List.generate(days, (index) {
      // Simulate adherence data (in real app, fetch from backend)
      return FlSpot(index.toDouble(), adherence + (index % 3 - 1) * 5);
    });

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Adherence',
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (period == 'weekly') {
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(
                              days[index],
                              style: Theme.of(context).textTheme.labelSmall,
                            );
                          }
                        }
                        return Text(
                          '${value.toInt()}',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: ModernSurfaceTheme.primaryTeal,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ModernSurfaceTheme.primaryTeal.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'Current Adherence: ${adherence.toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
