import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petcare/features/auth/login_screen.dart';
import 'package:petcare/features/auth/signup_screen.dart';
import 'package:petcare/features/settings/settings_screen.dart';
import 'package:petcare/features/pets/pet_detail_screen.dart';
import 'package:petcare/features/pets/pets_screen.dart';
import 'package:petcare/features/records/records_screen.dart';
import 'package:petcare/features/records/pet_records_screen.dart';
import 'package:petcare/features/labs/health_tab_screen.dart';
import 'package:petcare/features/labs/pet_health_screen.dart';
import 'package:petcare/features/labs/chart_screen.dart';
import 'package:petcare/features/records/records_chart_screen.dart';
import 'package:petcare/features/records/symptom_timeline_screen.dart';
import 'package:petcare/features/records/water_stats_screen.dart';
import 'package:petcare/features/records/walk_stats_screen.dart';
import 'package:petcare/features/food_calculator/food_calculator_screen.dart';
import 'package:petcare/features/grooming/grooming_screen.dart';
import 'package:petcare/features/vaccination/vaccination_schedule_screen.dart';
import 'package:petcare/features/allergy/allergy_screen.dart';
import 'package:petcare/features/emergency_contacts/emergency_contacts_screen.dart';
import 'package:petcare/features/labs/health_report_screen.dart';
import 'package:petcare/features/labs/weight_guide_screen.dart';
import 'package:petcare/ui/home.dart';
import 'package:petcare/data/services/admob_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// This listenable will notify the router when the auth state changes.
final _authChangeNotifier = GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);

final router = GoRouter(
  initialLocation: '/login',
  // Listen to auth state changes and rebuild the router when they occur.
  refreshListenable: _authChangeNotifier,
  observers: [AdMobRouteObserver()],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PetsScreen(), // 하단 탭 없이 펫 목록만 표시
    ),
    GoRoute(
      path: '/pets/:petId',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: HomeScreen(
          child: PetDetailScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'records',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: HomeScreen(
              child: PetRecordsScreen(
                petId: state.pathParameters['petId']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: 'health',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: HomeScreen(
              child: PetHealthScreen(
                petId: state.pathParameters['petId']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: 'chart',
          builder: (context, state) => ChartScreen(
            petId: state.pathParameters['petId']!,
            petName: state.uri.queryParameters['name'] ?? '펫',
          ),
        ),
        GoRoute(
          path: 'records-chart',
          builder: (context, state) => RecordsChartScreen(
            petId: state.pathParameters['petId']!,
            petName: state.uri.queryParameters['name'] ?? '펫',
          ),
        ),
        GoRoute(
          path: 'symptom-timeline',
          builder: (context, state) => SymptomTimelineScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'water-stats',
          builder: (context, state) => WaterStatsScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'walk-stats',
          builder: (context, state) => WalkStatsScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'food-calculator',
          builder: (context, state) => FoodCalculatorScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'grooming',
          builder: (context, state) => GroomingScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'vaccination',
          builder: (context, state) => VaccinationScheduleScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'allergies',
          builder: (context, state) => AllergyScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'emergency-contacts',
          builder: (context, state) => EmergencyContactsScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'report',
          builder: (context, state) => HealthReportScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
        GoRoute(
          path: 'weight-guide',
          builder: (context, state) => WeightGuideScreen(
            petId: state.pathParameters['petId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/records',
      builder: (context, state) => const HomeScreen(child: RecordsScreen()),
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => const HomeScreen(child: HealthTabScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(child: SettingsScreen()),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggedIn = Supabase.instance.client.auth.currentSession != null;
    final bool onAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    // If the user is not logged in and not on an auth route, redirect to login.
    if (!loggedIn && !onAuthRoute) {
      return '/login';
    }

    // If the user is logged in and on an auth route, redirect to home.
    if (loggedIn && onAuthRoute) {
      return '/';
    }

    // No redirect needed.
    return null;
  },
);

// A simple class to convert a Stream to a Listenable for GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// 화면 전환 감지하여 광고 표시
class AdMobRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 로그인/회원가입 화면은 제외
    if (route.settings.name != '/login' && route.settings.name != '/signup') {
      AdMobService.onScreenTransition();
    }
  }
}
