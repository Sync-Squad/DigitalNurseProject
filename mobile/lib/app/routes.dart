import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/models/user_model.dart';
import '../core/models/medicine_model.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/email_verification_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/onboarding/screens/profile_setup_screen.dart';
import '../features/onboarding/screens/subscription_plans_screen.dart';
import '../features/dashboard/screens/main_navigation_screen.dart';
import '../features/medication/screens/add_medicine_screen.dart';
import '../features/medication/screens/medicine_detail_screen.dart';
import '../features/medication/screens/medicine_alarm_screen.dart';
import '../features/health/screens/add_vital_screen.dart';
import '../features/health/screens/health_trends_screen.dart';
import '../features/health/screens/abnormal_vitals_screen.dart';
import '../features/caregiver/screens/add_caregiver_screen.dart';
import '../features/caregiver/screens/caregiver_list_screen.dart';
import '../features/caregiver/screens/invitation_accept_screen.dart';
import '../features/caregiver/screens/accept_invitation_code_screen.dart';
import '../features/caregiver/screens/patient_detail_screen.dart';
import '../features/caregiver/screens/medication_management_screen.dart';
import '../features/caregiver/screens/patient_reports_screen.dart';
import '../features/caregiver/screens/contact_caregiver_screen.dart';
import '../features/lifestyle/screens/diet_exercise_log_screen.dart';
import '../features/lifestyle/screens/add_meal_screen.dart';
import '../features/lifestyle/screens/add_workout_screen.dart';
import '../features/lifestyle/screens/weekly_plans_screen.dart';
import '../features/lifestyle/screens/create_weekly_plan_screen.dart';
import '../features/lifestyle/screens/plan_compliance_screen.dart';
import '../features/documents/screens/upload_document_screen.dart';
import '../features/documents/screens/document_viewer_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../core/services/notification_test.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/ai/screens/ai_assistant_screen.dart';
import '../features/ai/screens/ai_insights_screen.dart';
import '../features/ai/screens/health_analysis_screen.dart';
import '../features/ai/screens/semantic_search_screen.dart';
import '../features/ai/screens/document_qa_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/verify_reset_code_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/welcome',
  redirect: (context, state) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;
    final authService = AuthService();

    // Public routes that don't require authentication
    final publicRoutes = [
      '/welcome',
      '/login',
      '/register',
      '/email-verification',
      '/invitation-accept',
      '/forgot-password',
      '/verify-reset-code',
      '/reset-password',
    ];

    final isPublicRoute = publicRoutes.any(
      (route) => state.matchedLocation.startsWith(route),
    );

    // If user is logged in and on a public route, redirect to dashboard
    // BUT allow access to /register even when logged in (for registering new accounts)
    if (isLoggedIn && isPublicRoute && state.matchedLocation != '/register') {
      return '/home';
    }

    // If user is not logged in
    if (!isLoggedIn) {
      // Check if user has seen welcome screen
      final hasSeenWelcome = await authService.hasSeenWelcomeScreen();

      // If user has seen welcome screen and trying to access /welcome, redirect to login
      if (hasSeenWelcome && state.matchedLocation == '/welcome') {
        return '/login';
      }

      // If user hasn't seen welcome screen and trying to access a private route, redirect to welcome
      if (!hasSeenWelcome && !isPublicRoute) {
        return '/welcome';
      }

      // If user has seen welcome and trying to access a private route, redirect to login
      if (hasSeenWelcome && !isPublicRoute) {
        return '/login';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/contact-caregiver-email/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.uri.queryParameters['name'];
        return ContactCaregiverScreen(
          assignmentId: id,
          caregiverName: name,
        );
      },
    ),
    // Authentication routes
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final token = state.uri.queryParameters['token'];
        return EmailVerificationScreen(email: email, token: token);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-reset-code',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyResetCodeScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final code = state.uri.queryParameters['code'] ?? '';
        return ResetPasswordScreen(email: email, code: code);
      },
    ),

    // Onboarding routes
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/subscription-plans',
      builder: (context, state) => const SubscriptionPlansScreen(),
    ),

    // Main navigation with bottom bar
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/medications',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 4),
    ),

    // Medicine routes
    GoRoute(
      path: '/medicine/add',
      builder: (context, state) {
        final medicine = state.extra as MedicineModel?;
        return AddMedicineScreen(initialMedicine: medicine);
      },
    ),
    GoRoute(
      path: '/medicine/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final selectedDateStr = state.uri.queryParameters['selectedDate'];
        final reminderTimeStr = state.uri.queryParameters['reminderTime'];
        DateTime? selectedDate;
        if (selectedDateStr != null) {
          try {
            selectedDate = DateTime.parse(selectedDateStr);
          } catch (e) {
            // If parsing fails, use null (will default to today)
          }
        }
        return MedicineDetailScreen(
          medicineId: id,
          selectedDate: selectedDate,
          reminderTime: reminderTimeStr,
        );
      },
    ),

    // Health/Vitals routes
    GoRoute(
      path: '/vitals/add',
      builder: (context, state) => const AddVitalScreen(),
    ),
    GoRoute(
      path: '/health/trends',
      builder: (context, state) => const HealthTrendsScreen(),
    ),
    GoRoute(
      path: '/health/abnormal',
      builder: (context, state) => const AbnormalVitalsScreen(),
    ),

    // Caregiver routes
    GoRoute(
      path: '/caregivers',
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final role = authProvider.currentUser?.role;
        if (role == UserRole.caregiver) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) => const CaregiverListScreen(),
    ),
    GoRoute(
      path: '/caregiver/patient/:elderId',
      builder: (context, state) {
        final elderId = state.pathParameters['elderId']!;
        return PatientDetailScreen(elderId: elderId);
      },
    ),
    GoRoute(
      path: '/caregiver/patient/:elderId/medications',
      builder: (context, state) {
        final elderId = state.pathParameters['elderId']!;
        return MedicationManagementScreen(elderId: elderId);
      },
    ),
    GoRoute(
      path: '/caregiver/patient/:elderId/reports',
      builder: (context, state) {
        final elderId = state.pathParameters['elderId']!;
        return PatientReportsScreen(elderId: elderId);
      },
    ),
    GoRoute(
      path: '/caregiver/add',
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final role = authProvider.currentUser?.role;
        if (role == UserRole.caregiver) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) => const AddCaregiverScreen(),
    ),
    GoRoute(
      path: '/invitation-accept/:caregiverId',
      builder: (context, state) {
        final caregiverId = state.pathParameters['caregiverId']!;
        return InvitationAcceptScreen(caregiverId: caregiverId);
      },
    ),
    GoRoute(
      path: '/caregiver/accept-invitation-code',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AcceptInvitationCodeScreen(
          inviteCode: extra?['inviteCode'] as String?,
          invitation: extra?['invitation'] as Map<String, dynamic>?,
          notificationId: extra?['notificationId'] as String?,
        );
      },
    ),

    // Lifestyle routes
    GoRoute(
      path: '/lifestyle',
      builder: (context, state) => const DietExerciseLogScreen(),
    ),
    GoRoute(
      path: '/lifestyle/meal/add',
      builder: (context, state) {
        final selectedDateStr = state.uri.queryParameters['selectedDate'];
        DateTime? selectedDate;
        if (selectedDateStr != null) {
          try {
            selectedDate = DateTime.parse(selectedDateStr);
          } catch (e) {
            // If parsing fails, use null (will default to today)
          }
        }
        return AddMealScreen(selectedDate: selectedDate);
      },
    ),
    GoRoute(
      path: '/lifestyle/workout/add',
      builder: (context, state) {
        final selectedDateStr = state.uri.queryParameters['selectedDate'];
        DateTime? selectedDate;
        if (selectedDateStr != null) {
          try {
            selectedDate = DateTime.parse(selectedDateStr);
          } catch (e) {
            // If parsing fails, use null (will default to today)
          }
        }
        return AddWorkoutScreen(selectedDate: selectedDate);
      },
    ),
    GoRoute(
      path: '/lifestyle/plans',
      builder: (context, state) => const WeeklyPlansScreen(),
    ),
    GoRoute(
      path: '/lifestyle/plans/diet/create',
      builder: (context, state) =>
          const CreateWeeklyPlanScreen(isDietPlan: true),
    ),
    GoRoute(
      path: '/lifestyle/plans/diet/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateWeeklyPlanScreen(isDietPlan: true, planId: id);
      },
    ),
    GoRoute(
      path: '/lifestyle/plans/exercise/create',
      builder: (context, state) =>
          const CreateWeeklyPlanScreen(isDietPlan: false),
    ),
    GoRoute(
      path: '/lifestyle/plans/exercise/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateWeeklyPlanScreen(isDietPlan: false, planId: id);
      },
    ),
    GoRoute(
      path: '/lifestyle/plans/compliance',
      builder: (context, state) {
        final isDietPlan = state.uri.queryParameters['isDietPlan'] == 'true';
        final planId = state.uri.queryParameters['planId'] ?? '';
        final planName = state.uri.queryParameters['planName'] ?? 'Plan';
        return PlanComplianceScreen(
          isDietPlan: isDietPlan,
          planId: planId,
          planName: Uri.decodeComponent(planName),
        );
      },
    ),

    // Document routes
    GoRoute(
      path: '/documents/upload',
      builder: (context, state) => const UploadDocumentScreen(),
    ),
    GoRoute(
      path: '/documents/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DocumentViewerScreen(documentId: id);
      },
    ),

    // Settings
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Notifications
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Notification Test (for debugging)
    GoRoute(
      path: '/notification-test',
      builder: (context, state) => const NotificationTestWidget(),
    ),

    // Medicine Alarm Screen
    GoRoute(
      path: '/medicine-alarm',
      builder: (context, state) {
        final medicineId = state.uri.queryParameters['medicineId'];
        final medicineName = state.uri.queryParameters['medicineName'];
        final dosage = state.uri.queryParameters['dosage'];
        final payload = state.uri.queryParameters['payload'];
        return MedicineAlarmScreen(
          medicineId: medicineId,
          medicineName: medicineName,
          dosage: dosage,
          payload: payload,
        );
      },
    ),

    // AI Routes
    GoRoute(
      path: '/ai/assistant',
      builder: (context, state) => const AIAssistantScreen(),
    ),
    GoRoute(
      path: '/ai/insights',
      builder: (context, state) => const AIInsightsScreen(),
    ),
    GoRoute(
      path: '/ai/analysis',
      builder: (context, state) => const HealthAnalysisScreen(),
    ),
    GoRoute(
      path: '/ai/search',
      builder: (context, state) => const SemanticSearchScreen(),
    ),
    GoRoute(
      path: '/ai/document-qa',
      builder: (context, state) => const DocumentQAScreen(),
    ),
  ],
);
