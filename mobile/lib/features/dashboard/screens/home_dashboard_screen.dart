// import 'dart:io'; // COMMENTED OUT: Only used in disabled alarm permission check
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/modern_scaffold.dart';
// import '../../../core/widgets/full_screen_intent_dialog.dart'; // COMMENTED OUT: Dialog disabled
import '../widgets/caregiver/caregiver_dashboard_view.dart';
import '../widgets/patient/patient_dashboard_view.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Defer data loading until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(force: true);
      // COMMENTED OUT: Alarm permission dialog disabled to fix lock screen issues
      // _checkAlarmPermission();
    });
  }

  /// Check and prompt for full-screen intent permission on Android
  // COMMENTED OUT: Alarm permission dialog disabled to fix lock screen issues
  // This dialog was prompting users to enable "Display over other apps" permission
  // Future<void> _checkAlarmPermission() async {
  //   if (!Platform.isAndroid) return;
  //
  //   // Small delay to let the home screen render first
  //   await Future.delayed(const Duration(milliseconds: 500));
  //
  //   if (!mounted) return;
  //
  //   // COMMENTED OUT: Dialog call disabled
  //   // await FullScreenIntentDialog.showIfNeeded(context);
  // }

  String? _lastLoadedContextKey;

  Future<void> _loadData({bool force = false}) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isCaregiver = currentUser?.role == UserRole.caregiver;

    String? targetUserId = currentUser?.id;
    String? elderUserId;

    if (isCaregiver) {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();
      if (!mounted) {
        return;
      }
      targetUserId = careContext.selectedElderId;
      elderUserId = targetUserId;

      if (targetUserId == null) {
        setState(() {
          _lastLoadedContextKey = null;
        });
        return;
      }
    }

    if (targetUserId == null) {
      return;
    }

    final contextKey = elderUserId ?? targetUserId;
    if (!force && contextKey == _lastLoadedContextKey) {
      return;
    }

    _lastLoadedContextKey = contextKey;

    await Future.wait([
      context.read<MedicationProvider>().loadMedicines(
        targetUserId,
        elderUserId: elderUserId,
      ),
      context.read<HealthProvider>().loadVitals(
        targetUserId,
        elderUserId: elderUserId,
      ),
      if (!isCaregiver)
        context.read<CaregiverProvider>().loadCaregivers(targetUserId),
      context.read<NotificationProvider>().loadNotifications(),
      context.read<LifestyleProvider>().loadAll(
        targetUserId,
        elderUserId: elderUserId,
      ),
      context.read<DocumentProvider>().loadDocuments(
        targetUserId,
        elderUserId: elderUserId,
      ),
    ]);
    if (!mounted) {
      return;
    }
  }

  void _showLanguageDialog(BuildContext buildContext) {
    showDialog(
      context: buildContext,
      builder: (BuildContext dialogContext) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            return AlertDialog(
              title: Text('settings.language.title'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: localeProvider.localeOptions.map((option) {
                  final isSelected = localeProvider.locale == option.locale;
                  return ListTile(
                    leading: Icon(
                      FIcons.languages,
                      color: isSelected
                          ? context.theme.colors.primary
                          : context.theme.colors.mutedForeground,
                    ),
                    title: Text(
                      option.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? context.theme.colors.primary
                            : context.theme.colors.foreground,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            FIcons.check,
                            color: context.theme.colors.primary,
                          )
                        : null,
                    onTap: () async {
                      // Update EasyLocalization FIRST to ensure .tr() returns correct translations
                      // before widgets rebuild
                      await buildContext.setLocale(option.locale);
                      // Then persist to LocaleProvider (for app restart)
                      await localeProvider.setLocale(option.locale);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final authProvider = context.watch<AuthProvider>();
    final careContextProvider = context.watch<CareContextProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    final user = authProvider.currentUser;
    final unreadNotifications = notificationProvider.unreadCount;
    final isCaregiver = user?.role == UserRole.caregiver;
    final headerTitle = isCaregiver
        ? 'patient.caregiverDashboard'.tr()
        : 'app.name'.tr(); // Show app name as header for patients

    return ModernScaffold(
      safeAreaTop: false,
      safeAreaBottom: false,
      appBar: AppBar(
        backgroundColor: AppTheme.teal, // #008080 teal-primary
        elevation: 0,
        centerTitle: false,
        title: Text(
          headerTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FIcons.languages),
            color: Colors.white,
            onPressed: () => _showLanguageDialog(context),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(FIcons.bell),
                if (unreadNotifications > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.getErrorColor(context),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Profile button for caregivers (since bottom navigation is hidden)
          if (isCaregiver)
            IconButton(
              icon: const Icon(FIcons.user),
              color: Colors.white,
              onPressed: () => context.push('/profile'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(force: true),
        child: isCaregiver
            ? CaregiverDashboardView(
                careContext: careContextProvider,
                onRecipientSelected: (elderId) {
                  careContextProvider.selectRecipient(elderId);
                  _loadData(force: true);
                },
              )
            : const PatientDashboardView(),
      ),
    );
  }
}
