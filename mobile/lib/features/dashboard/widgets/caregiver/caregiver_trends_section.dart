// import 'dart:math';

// import 'package:digital_nurse/core/extensions/vital_type_extensions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:forui/forui.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/models/medicine_model.dart';
// import '../../../../core/models/vital_measurement_model.dart';
// import '../../../../core/providers/health_provider.dart';
// import '../../../../core/providers/medication_provider.dart';
// import '../dashboard_theme.dart';

// class CaregiverAdherenceAndVitalsRow extends StatelessWidget {
//   const CaregiverAdherenceAndVitalsRow({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isWide = constraints.maxWidth > 600;
//         final children = const [
//           // _VitalsTrendCard(),
//           // _AdherenceSparklineCard(),
//         ];
//         if (isWide) {
//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: List.generate(children.length, (index) {
//               final child = children[index];
//               final isLast = index == children.length - 1;
//               return Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.only(right: isLast ? 0 : 14.w),
//                   child: child,
//                 ),
//               );
//             }),
//           );
//         }
//         return Column(
//           children: List.generate(children.length, (index) {
//             final child = children[index];
//             final isLast = index == children.length - 1;
//             return Padding(
//               padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
//               child: child,
//             );
//           }),
//         );
//       },
//     );
//   }
// }

// // class _VitalsTrendCard extends StatelessWidget {
// //   const _VitalsTrendCard();

// //   @override
// //   Widget build(BuildContext context) {
// //     final healthProvider = context.watch<HealthProvider>();

// //     final trendData = _TrendData.fromVitals(healthProvider.vitals);

// //     return Container(
// //       padding: CaregiverDashboardTheme.cardPadding(),
// //       decoration: CaregiverDashboardTheme.glassCard(),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Container(
// //                 width: 40,
// //                 height: 40,
// //                 decoration: CaregiverDashboardTheme.iconBadge(
// //                   CaregiverDashboardTheme.accentBlue,
// //                 ),
// //                 child: const Icon(
// //                   Icons.show_chart_rounded,
// //                   color: Colors.white,
// //                 ),
// //               ),
// //               SizedBox(width: 12.w),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       'Vitals trend',
// //                       style: CaregiverDashboardTheme.sectionTitleStyle(
// //                         context,
// //                       ),
// //                     ),
// //                     SizedBox(height: 4.h),
// //                     Text(
// //                       'Visualise the latest vital that has enough history.',
// //                       style: CaregiverDashboardTheme.sectionSubtitleStyle(
// //                         context,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: 20.h),
// //           if (trendData == null)
// //             Container(
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: 16.w,
// //                 vertical: 18.h,
// //               ),
// //               decoration: CaregiverDashboardTheme.tintedCard(
// //                 CaregiverDashboardTheme.accentBlue,
// //               ),
// //               child: Row(
// //                 children: [
// //                   Container(
// //                     width: 36,
// //                     height: 36,
// //                     decoration: CaregiverDashboardTheme.iconBadge(
// //                       CaregiverDashboardTheme.accentBlue,
// //                     ),
// //                     child: const Icon(
// //                       Icons.info_outline_rounded,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                   SizedBox(width: 12.w),
// //                   Expanded(
// //                     child: Text(
// //                       'Not enough data to display trends yet.',
// //                       style: context.theme.typography.sm.copyWith(
// //                         fontWeight: FontWeight.w600,
// //                         color: CaregiverDashboardTheme.deepTeal,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             )
// //           else ...[
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Container(
// //                   padding: EdgeInsets.symmetric(
// //                     horizontal: 12.w,
// //                     vertical: 6.h,
// //                   ),
// //                   decoration: CaregiverDashboardTheme.frostedChip(
// //                     baseColor: Colors.white,
// //                   ),
// //                   child: Text(
// //                     trendData.label,
// //                     style: context.theme.typography.xs.copyWith(
// //                       fontWeight: FontWeight.w600,
// //                       color: CaregiverDashboardTheme.accentBlue,
// //                     ),
// //                   ),
// //                 ),
// //                 Text(
// //                   '${trendData.points.last.value.toStringAsFixed(1)} ${trendData.unit}',
// //                   style: context.theme.typography.sm.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                     color: CaregiverDashboardTheme.deepTeal,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             SizedBox(height: 16.h),
// //             Container(
// //               height: 140.h,
// //               padding: EdgeInsets.all(12.w),
// //               decoration: CaregiverDashboardTheme.tintedCard(
// //                 CaregiverDashboardTheme.accentBlue,
// //               ),
// //               child: SparklineChart(
// //                 values: trendData.points.map((point) => point.value).toList(),
// //                 color: CaregiverDashboardTheme.accentBlue,
// //               ),
// //             ),
// //             SizedBox(height: 14.h),
// //             Text(
// //               'Last updated • ${DateFormat('MMM d, h:mm a').format(trendData.points.last.timestamp)}',
// //               style: context.theme.typography.xs.copyWith(
// //                 color: CaregiverDashboardTheme.deepTeal.withOpacity(0.6),
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _AdherenceSparklineCard extends StatelessWidget {
// //   const _AdherenceSparklineCard();

// //   Future<List<_TrendPoint>> _loadAdherenceHistory(
// //     BuildContext context,
// //     List<MedicineModel> medicines,
// //   ) async {
// //     if (medicines.isEmpty) {
// //       return const [];
// //     }

// //     final medicationProvider = context.read<MedicationProvider>();
// //     final points = <_TrendPoint>[];

// //     for (final medicine in medicines.take(3)) {
// //       try {
// //         final history = await medicationProvider.getIntakeHistory(
// //           medicine.id,
// //           elderUserId: medicine.userId,
// //         );
// //         for (final intake in history) {
// //           final status = intake.status;
// //           final value = status == IntakeStatus.taken
// //               ? 1.0
// //               : status == IntakeStatus.skipped
// //                   ? 0.5
// //                   : 0.0;
// //           points.add(
// //             _TrendPoint(
// //               timestamp: intake.scheduledTime,
// //               value: value,
// //             ),
// //           );
// //         }
// //       } catch (e, stackTrace) {
// //         debugPrint(
// //           'Failed to load intake history for medicine ${medicine.id}: $e\n$stackTrace',
// //         );
// //       }
// //     }

// //     points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
// //     return points.takeLast(14).toList();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final medicationProvider = context.watch<MedicationProvider>();

// //     return FutureBuilder<List<_TrendPoint>>(
// //       future: _loadAdherenceHistory(context, medicationProvider.medicines),
// //       builder: (context, snapshot) {
// //         final points = snapshot.data ?? [];
// //         return Container(
// //           padding: CaregiverDashboardTheme.cardPadding(),
// //           decoration: CaregiverDashboardTheme.glassCard(),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 children: [
// //                   Container(
// //                     width: 40,
// //                     height: 40,
// //                     decoration: CaregiverDashboardTheme.iconBadge(
// //                       CaregiverDashboardTheme.primaryTeal,
// //                     ),
// //                     child: const Icon(
// //                       Icons.auto_graph_rounded,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                   SizedBox(width: 12.w),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           'Medication adherence',
// //                           style: CaregiverDashboardTheme.sectionTitleStyle(
// //                             context,
// //                           ),
// //                         ),
// //                         SizedBox(height: 4.h),
// //                         Text(
// //                           'Last 14 doses across top medicines.',
// //                           style: CaregiverDashboardTheme.sectionSubtitleStyle(
// //                             context,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               SizedBox(height: 20.h),
// //               if (snapshot.connectionState == ConnectionState.waiting)
// //                 Container(
// //                   height: 140.h,
// //                   decoration: CaregiverDashboardTheme.tintedCard(
// //                     CaregiverDashboardTheme.primaryTeal,
// //                   ),
// //                   child: Center(
// //                     child: CircularProgressIndicator(
// //                       valueColor: AlwaysStoppedAnimation<Color>(
// //                         CaregiverDashboardTheme.primaryTeal,
// //                       ),
// //                     ),
// //                   ),
// //                 )
// //               else if (points.length < 2)
// //                 Container(
// //                   padding: EdgeInsets.symmetric(
// //                     horizontal: 16.w,
// //                     vertical: 18.h,
// //                   ),
// //                   decoration: CaregiverDashboardTheme.tintedCard(
// //                     CaregiverDashboardTheme.primaryTeal,
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Container(
// //                         width: 36,
// //                         height: 36,
// //                         decoration: CaregiverDashboardTheme.iconBadge(
// //                           CaregiverDashboardTheme.primaryTeal,
// //                         ),
// //                         child: const Icon(
// //                           Icons.info_outline_rounded,
// //                           color: Colors.white,
// //                         ),
// //                       ),
// //                       SizedBox(width: 12.w),
// //                       Expanded(
// //                         child: Text(
// //                           'Not enough adherence history yet.',
// //                           style: context.theme.typography.sm.copyWith(
// //                             fontWeight: FontWeight.w600,
// //                             color: CaregiverDashboardTheme.deepTeal,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 )
// //               else ...[
// //                 Container(
// //                   height: 140.h,
// //                   padding: EdgeInsets.all(12.w),
// //                   decoration: CaregiverDashboardTheme.tintedCard(
// //                     CaregiverDashboardTheme.primaryTeal,
// //                   ),
// //                   child: SparklineChart(
// //                     values: points.map((point) => point.value * 100).toList(),
// //                     color: CaregiverDashboardTheme.primaryTeal,
// //                   ),
// //                 ),
// //                 SizedBox(height: 14.h),
// //                 Text(
// //                   'Last 14 doses • ${points.last.value == 1.0 ? 'Taken' : points.last.value == 0.5 ? 'Skipped' : 'Missed'}',
// //                   style: context.theme.typography.xs.copyWith(
// //                     color: CaregiverDashboardTheme.deepTeal.withOpacity(0.6),
// //                   ),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }

// class SparklineChart extends StatelessWidget {
//   final List<double> values;
//   final Color color;

//   const SparklineChart({
//     super.key,
//     required this.values,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox.expand(
//       child: CustomPaint(
//         painter: _SparklinePainter(values: values, color: color),
//       ),
//     );
//   }
// }

// class _TrendData {
//   final String label;
//   final String unit;
//   final List<_TrendPoint> points;

//   const _TrendData({
//     required this.label,
//     required this.unit,
//     required this.points,
//   });

//   factory _TrendData.fromType(
//     VitalType type,
//     List<VitalMeasurementModel> vitals,
//   ) {
//     final filtered = vitals
//         .where((vital) => vital.type == type)
//         .map((vital) {
//           final value = _TrendPoint.parseVitalValue(vital);
//           if (value == null) return null;
//           return _TrendPoint(timestamp: vital.timestamp, value: value);
//         })
//         .whereType<_TrendPoint>()
//         .toList()
//       ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

//     return _TrendData(
//       label: type.displayName,
//       unit: type.unit,
//       points: filtered.takeLast(10).toList(),
//     );
//   }

//   static _TrendData? fromVitals(List<VitalMeasurementModel> vitals) {
//     if (vitals.length < 2) {
//       return null;
//     }

//     for (final type in [
//       VitalType.heartRate,
//       VitalType.bloodPressure,
//       VitalType.bloodSugar,
//       VitalType.temperature,
//     ]) {
//       final data = _TrendData.fromType(type, vitals);
//       if (data.points.length >= 2) {
//         return data;
//       }
//     }

//     return null;
//   }
// }

// class _TrendPoint {
//   final DateTime timestamp;
//   final double value;

//   const _TrendPoint({
//     required this.timestamp,
//     required this.value,
//   });

//   static double? parseVitalValue(VitalMeasurementModel vital) {
//     switch (vital.type) {
//       case VitalType.bloodPressure:
//         final parts = vital.value.split('/');
//         if (parts.isEmpty) return null;
//         return double.tryParse(parts.first.trim());
//       case VitalType.bloodSugar:
//       case VitalType.temperature:
//         return double.tryParse(vital.value);
//       case VitalType.heartRate:
//       case VitalType.oxygenSaturation:
//       case VitalType.weight:
//         return double.tryParse(vital.value);
//     }
//   }
// }

// class _SparklinePainter extends CustomPainter {
//   final List<double> values;
//   final Color color;

//   _SparklinePainter({
//     required this.values,
//     required this.color,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (values.length < 2) {
//       return;
//     }

//     final minValue = values.reduce(min);
//     final maxValue = values.reduce(max);
//     final range = max(maxValue - minValue, 1e-6);

//     final path = Path();
//     for (var i = 0; i < values.length; i++) {
//       final x = i == 0
//           ? 0.0
//           : (i / (values.length - 1)) * size.width;
//       final normalized = (values[i] - minValue) / range;
//       final y = size.height - (normalized * size.height);
//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }

//     final fillPath = Path.from(path)
//       ..lineTo(size.width, size.height)
//       ..lineTo(0, size.height)
//       ..close();

//     final fillPaint = Paint()
//       ..shader = LinearGradient(
//         colors: [
//           color.withOpacity(0.25),
//           color.withOpacity(0.05),
//         ],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//       ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

//     canvas.drawPath(fillPath, fillPaint);

//     final linePaint = Paint()
//       ..color = color
//       ..strokeWidth = 2.5
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;

//     canvas.drawPath(path, linePaint);
//   }

//   @override
//   bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
//     return oldDelegate.values != values || oldDelegate.color != color;
//   }
// }

// extension _TakeLast<T> on List<T> {
//   Iterable<T> takeLast(int count) {
//     if (count <= 0) return const Iterable.empty();
//     if (length <= count) return this;
//     return sublist(length - count);
//   }
// }
