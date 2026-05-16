import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/track_select_screen.dart';
import '../screens/generating_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/week_detail_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',          builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/auth',      builder: (c, s) => const AuthScreen()),
    GoRoute(path: '/onboarding',builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/track',     builder: (c, s) => const TrackSelectScreen()),
    GoRoute(path: '/generating',builder: (c, s) => const GeneratingScreen()),
    GoRoute(path: '/roadmap',   builder: (c, s) => const RoadmapScreen()),
    GoRoute(path: '/week',      builder: (c, s) => const WeekDetailScreen()),
    GoRoute(path: '/resources', builder: (c, s) => const ResourcesScreen()),
    GoRoute(path: '/profile',   builder: (c, s) => const ProfileScreen()),
  ],
);
