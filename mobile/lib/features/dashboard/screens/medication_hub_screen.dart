import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_menu_tile.dart';
import 'package:digital_nurse/core/providers/medication_provider.dart';
import 'package:digital_nurse/core/theme/modern_surface_theme.dart';
import 'package:digital_nurse/core/theme/app_theme.dart';
import 'package:digital_nurse/core/widgets/modern_scaffold.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_hero_header.dart';

class MedicationHubScreen extends StatelessWidget {
  const MedicationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final medicinesCount = medicationProvider.medicines.length;
    final textTheme = Theme.of(context).textTheme;

    return ModernScaffold(
      appBar: AppBar(
        title: Text('Medication Center'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            HubHeroHeader(
              title: 'Medication Center'.tr(),
              description:
                  'Manage your prescriptions, track upcoming doses, and stay on top of your health plan.'
                      .tr(),
              imagePath: 'assets/images/medicine.png',
              accentColor: ModernSurfaceTheme.primaryTeal,
              child: Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: ModernSurfaceTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '$medicinesCount',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'medicines track'.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            
            // Grid of Action Tiles
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.35,
              children: [
                HubMenuTile(
                  label: 'Create Medication',
                  icon: Icons.add_business_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/medicine/add'),
                ),
                HubMenuTile(
                  label: 'Medicine History',
                  icon: Icons.history_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/medicine/log'),
                ),
                HubMenuTile(
                  label: 'Log Medication',
                  icon: Icons.add_circle_outline_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/medications'),
                ),
                HubMenuTile(
                  label: 'Daily Review',
                  icon: Icons.assignment_turned_in_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/medication/review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

