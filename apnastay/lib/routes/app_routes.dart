import 'package:flutter/material.dart';

import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/login_signup_screen/login_signup_screen.dart';
import '../presentation/pg_listings_screen/pg_listings_screen.dart';
import '../presentation/pg_detail_screen/pg_detail_screen.dart';
import '../presentation/roommate_matching_screen/roommate_matching_screen.dart';
import '../presentation/dabba_service_screen/dabba_service_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/lifestyle_quiz_screen/lifestyle_quiz_screen.dart';
import '../presentation/pg_owner_dashboard_screen/pg_owner_dashboard_screen.dart';
import '../presentation/pg_owner_onboarding_screen/pg_owner_onboarding_screen.dart';
import '../presentation/meal_provider_dashboard_screen/meal_provider_dashboard_screen.dart';
import '../presentation/meal_provider_onboarding_screen/meal_provider_onboarding_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginSignupScreen = '/login-signup-screen';
  static const String homeDashboardScreen = '/home-dashboard-screen';
  static const String pgListingsScreen = '/pg-listings-screen';
  static const String pgDetailScreen = '/pg-detail-screen';
  static const String roommateMatchingScreen = '/roommate-matching-screen';
  static const String dabbaServiceScreen = '/dabba-service-screen';
  static const String profileScreen = '/profile-screen';
  static const String lifestyleQuizScreen = '/lifestyle-quiz-screen';
  static const String pgOwnerDashboardScreen = '/pg-owner-dashboard-screen';
  static const String pgOwnerOnboardingScreen = '/pg-owner-onboarding-screen';
  static const String mealProviderDashboardScreen =
      '/meal-provider-dashboard-screen';
  static const String mealProviderOnboardingScreen =
      '/meal-provider-onboarding-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginSignupScreen(),
    loginSignupScreen: (context) => const LoginSignupScreen(),
    homeDashboardScreen: (context) => const HomeDashboardScreen(),
    pgListingsScreen: (context) => const PgListingsScreen(),
    pgDetailScreen: (context) => const PgDetailScreen(),
    roommateMatchingScreen: (context) => const RoommateMatchingScreen(),
    dabbaServiceScreen: (context) => const DabbaServiceScreen(),
    profileScreen: (context) => const ProfileScreen(),
    lifestyleQuizScreen: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final initialProfile = arguments is Map
          ? Map<String, dynamic>.from(arguments)
          : null;
      return LifestyleQuizScreen(initialProfile: initialProfile);
    },
    pgOwnerDashboardScreen: (context) => const PgOwnerDashboardScreen(),
    pgOwnerOnboardingScreen: (context) => const PgOwnerOnboardingScreen(),
    mealProviderDashboardScreen: (context) =>
        const MealProviderDashboardScreen(),
    mealProviderOnboardingScreen: (context) =>
        const MealProviderOnboardingScreen(),
  };
}
