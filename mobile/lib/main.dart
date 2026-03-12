import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/routes.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/care_context_provider.dart';
import 'core/providers/caregiver_provider.dart';
import 'core/providers/medication_provider.dart';
import 'core/providers/health_provider.dart';
import 'core/providers/lifestyle_provider.dart';
import 'core/providers/document_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

/// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (options required for web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Set up FCM alarm tap callback
  FCMService().onAlarmTap = (payload) {
    _navigateToAlarmScreen(payload);
  };

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Load saved locale preference
  final prefs = await SharedPreferences.getInstance();
  final savedLocaleCode = prefs.getString('app_locale') ?? 'en';
  final savedLocale = savedLocaleCode == 'ur'
      ? const Locale('ur')
      : const Locale('en');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ur')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: savedLocale,
      child: const DigitalNurseApp(),
    ),
  );
}

/// Navigate to the alarm screen when a medicine reminder notification is tapped
void _navigateToAlarmScreen(String? payload) {
  // Use the goRouter to navigate
  final encodedPayload = payload != null ? Uri.encodeComponent(payload) : '';
  goRouter.go('/medicine-alarm?payload=$encodedPayload');
}

class DigitalNurseApp extends StatelessWidget {
  const DigitalNurseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProxyProvider<AuthProvider, CareContextProvider>(
          create: (_) => CareContextProvider(),
          update: (context, authProvider, careContext) {
            final provider = careContext ?? CareContextProvider();
            provider.updateAuth(authProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CaregiverProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => LifestyleProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..initializeFCM(),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          // Wait for both providers to initialize
          if (!localeProvider.isInitialized || !themeProvider.isInitialized) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          final lightMaterialTheme = _buildMaterialTheme(
            AppTheme.lightTheme,
            isDark: false,
          );
          final darkMaterialTheme = _buildMaterialTheme(
            AppTheme.darkTheme,
            isDark: true,
          );

          return ScaffoldMessenger(
            child: MaterialApp.router(
              title: 'My Digital Nurse',
              debugShowCheckedModeBanner: false,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              // Use EasyLocalization's locale as the single source of truth for UI
              locale: context.locale,
              theme: lightMaterialTheme,
              darkTheme: darkMaterialTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: goRouter,
              builder: (context, child) {
                // Set status bar style based on current theme
                final isDark = themeProvider.isDarkMode;
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor:
                        Colors.transparent, // Make status bar transparent
                    statusBarIconBrightness: isDark
                        ? Brightness
                              .light // Light icons for dark theme
                        : Brightness.dark, // Dark icons for light theme
                    statusBarBrightness: isDark
                        ? Brightness
                              .dark // For iOS
                        : Brightness.light, // For iOS
                  ),
                );

                return ScreenUtilInit(
                  designSize: const Size(
                    375,
                    812,
                  ), // iPhone X/11 Pro design reference
                  minTextAdapt: true,
                  splitScreenMode: true,
                  builder: (context, child) {
                    // Use the appropriate theme based on current mode
                    final currentTheme = themeProvider.isDarkMode
                        ? AppTheme.darkTheme
                        : AppTheme.lightTheme;
                    return FAnimatedTheme(data: currentTheme, child: child!);
                  },
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

ThemeData _buildMaterialTheme(FThemeData fTheme, {required bool isDark}) {
  final base = fTheme.toApproximateMaterialTheme();
  final colorScheme = base.colorScheme;
  final secondaryColor = const Color(0xFF7FD991);
  final tertiaryColor = AppTheme.blueTertiary;

  // Update ColorScheme with tertiary color
  // Note: Primary stays as teal, but buttons use secondary (apple green) via ElevatedButtonTheme
  final updatedColorScheme = colorScheme.copyWith(
    tertiary: tertiaryColor,
    onTertiary: Colors.white,
  );

  final textButtonStyle = TextButton.styleFrom(
    foregroundColor: secondaryColor,
    textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  final dialogTheme = base.dialogTheme.copyWith(
    backgroundColor: base.colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: base.textTheme.titleLarge?.copyWith(
      color: updatedColorScheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: base.textTheme.bodyMedium?.copyWith(
      color: updatedColorScheme.onSurfaceVariant,
    ),
  );

  return base.copyWith(
    colorScheme: updatedColorScheme,
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    dialogTheme: dialogTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF008080), // teal-primary
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
