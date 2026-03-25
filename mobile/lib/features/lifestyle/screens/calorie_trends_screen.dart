import 'package:flutter/material.dart';
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
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id;
    final lifestyleProvider = context.read<LifestyleProvider>();

    await lifestyleProvider.fetchTrendsData(userId);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lifestyleProvider = context.watch<LifestyleProvider>();
    final dailyData = lifestyleProvider.getDailyCalorieData(_selectedDays);

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Lifestyle Analytics',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
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
                    onChanged: (days) => setState(() => _selectedDays = days),
                  ),
                  SizedBox(height: 20.h),
                  _buildNetSummaryRing(context, dailyData),
                  SizedBox(height: 24.h),
                  _buildPulseGrid(context, dailyData),
                  SizedBox(height: 24.h),
                  _buildDailyBreakdown(context, dailyData),
                ],
              ),
            ),
    );
  }

  Widget _buildNetSummaryRing(BuildContext context, Map<DateTime, Map<String, int>> dailyData) {
    if (dailyData.isEmpty) return const SizedBox();

    int totalIn = 0;
    int totalOut = 0;
    for (var data in dailyData.values) {
      totalIn += data['in']!;
      totalOut += data['out']!;
    }

    final net = totalIn - totalOut;
    final isDeficit = net <= 0;
    final netAbs = net.abs();
    final accentColor = isDeficit ? AppTheme.appleGreen : ModernSurfaceTheme.accentBlue;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: ModernSurfaceTheme.glassCard(context, accent: accentColor),
      child: Column(
        children: [
          Text(
            'PERIODIC BALANCE',
            style: ModernSurfaceTheme.sectionTitleStyle(context).copyWith(
              color: ModernSurfaceTheme.deepTeal,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140.w,
                width: 140.w,
                child: CircularProgressIndicator(
                  value: 0.7, // Visual representation
                  strokeWidth: 12,
                  backgroundColor: accentColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    netAbs.toString(),
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 13.sp, 
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            isDeficit ? 'TOTAL DEFICIT' : 'TOTAL SURPLUS',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Based on your last $_selectedDays days',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseGrid(BuildContext context, Map<DateTime, Map<String, int>> dailyData) {
    if (dailyData.isEmpty) return const SizedBox();
    
    final sortedDates = dailyData.keys.toList()..sort();
    final isWeekly = sortedDates.length <= 7;
    
    // Find max intensity for normalization
    double maxIntensity = 1;
    for (var data in dailyData.values) {
      final intensity = (data['in']! + data['out']!).toDouble();
      if (intensity > maxIntensity) maxIntensity = intensity;
    }

    final successColor = AppTheme.getSuccessColor(context);
    final warningColor = AppTheme.getWarningColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'DAILY HEALTH PULSE',
            style: ModernSurfaceTheme.sectionTitleStyle(context).copyWith(
              color: ModernSurfaceTheme.deepTeal,
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          height: 100.h,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: ModernSurfaceTheme.cardRadius(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Connecting Line
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Divider(
                  color: Colors.white.withOpacity(0.05),
                  thickness: 1,
                ),
              ),
              ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: isWeekly ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isWeekly ? 10.w : 20.w),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final data = dailyData[date]!;
                  final intensity = (data['in']! + data['out']!).toDouble();
                  final net = data['in']! - data['out']!;
                  final isDeficit = net <= 0;
                  final color = isDeficit ? successColor : ModernSurfaceTheme.accentBlue.withOpacity(0.7);
                  
                  // Scale based on intensity (min 0.5, max 1.0)
                  final scale = 0.5 + (0.5 * (intensity / maxIntensity));
                  final dotSize = 36.w * scale;
                  
                  return Container(
                    width: isWeekly ? (1.sw - 60.w) / 7 : 55.w,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          height: dotSize,
                          width: dotSize,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(
                                 color: color.withOpacity(0.3),
                                 blurRadius: 10,
                                 spreadRadius: 1,
                               ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isDeficit ? Icons.check : Icons.priority_high,
                              size: 12.sp * scale,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreakdown(BuildContext context, Map<DateTime, Map<String, int>> dailyData) {
    if (dailyData.isEmpty) return const SizedBox();
    
    final sortedDates = dailyData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'DAILY BREAKDOWN',
            style: ModernSurfaceTheme.sectionTitleStyle(context).copyWith(
              color: ModernSurfaceTheme.deepTeal,
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        ...sortedDates.map((date) {
          final data = dailyData[date]!;
          final net = data['in']! - data['out']!;
          final isDeficit = net <= 0;
          
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(date),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _SmallStat(label: 'In', value: data['in']!, color: AppTheme.appleGreen),
                        SizedBox(width: 8.w),
                        _SmallStat(label: 'Out', value: data['out']!, color: ModernSurfaceTheme.accentBlue.withOpacity(0.6)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${net > 0 ? '+' : ''}$net',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: isDeficit ? AppTheme.appleGreen : ModernSurfaceTheme.accentBlue.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'NET KCAL',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SmallStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
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
          child: GestureDetector(
            onTap: () => onChanged(days),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.appleGreen : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? AppTheme.appleGreen : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                '$days Days',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.sp,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
