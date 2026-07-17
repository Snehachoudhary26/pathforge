import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/track_select_screen.dart';
import '../screens/generating_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/week_detail_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/job_readiness_screen.dart';
import '../screens/resume_scanner_screen.dart';
import '../screens/resume_rewriter_screen.dart';
import '../screens/interview_screen.dart';
import '../screens/share_progress_screen.dart';
import '../screens/job_market_screen.dart';
import '../screens/ai_mentor_screen.dart';

Page<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

Page<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(
            Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut))),
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (c, s) => _fadePage(const SplashScreen(), s),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (c, s) => _fadePage(const AuthScreen(), s),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (c, s) => _fadePage(const HomeScreen(), s),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (c, s) => _slidePage(const OnboardingScreen(), s),
    ),
    GoRoute(
      path: '/track',
      pageBuilder: (c, s) => _slidePage(const TrackSelectScreen(), s),
    ),
    GoRoute(
      path: '/generating',
      pageBuilder: (c, s) {
        final track = s.uri.queryParameters['track'] ?? 'Data Scientist';
        return _slidePage(GeneratingScreen(track: track), s);
      },
    ),
    GoRoute(
      path: '/roadmap',
      pageBuilder: (c, s) {
        final track = s.uri.queryParameters['track'] ?? 'Data Scientist';
        return _slidePage(RoadmapScreen(track: track), s);
      },
    ),
    GoRoute(
      path: '/week',
      pageBuilder: (c, s) => _slidePage(const WeekDetailScreen(), s),
    ),
    GoRoute(
      path: '/resources',
      pageBuilder: (c, s) => _slidePage(const ResourcesScreen(), s),
    ),
    GoRoute(
      path: '/interview',
      pageBuilder: (c, s) {
        final track = s.uri.queryParameters['track'] ?? 'Software Engineer';
        final week = s.uri.queryParameters['week'] ?? 'Week 1';
        return _slidePage(
            InterviewScreen(track: track, weekTitle: week), s);
      },
    ),
    GoRoute(
      path: '/resume',
      pageBuilder: (c, s) => _slidePage(const ResumeScannerScreen(), s),
    ),
    GoRoute(
      path: '/rewriter',
      pageBuilder: (c, s) => _slidePage(const ResumeRewriterScreen(), s),
    ),
    GoRoute(
      path: '/readiness',
      pageBuilder: (c, s) => _slidePage(const JobReadinessScreen(), s),
    ),
    GoRoute(
      path: '/share',
      pageBuilder: (c, s) => _slidePage(const ShareProgressScreen(), s),
    ),
    GoRoute(
      path: '/market',
      pageBuilder: (c, s) => _slidePage(const JobMarketScreen(), s),
    ),
    GoRoute(
      path: '/mentor',
      pageBuilder: (c, s) => _slidePage(const AiMentorScreen(), s),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (c, s) => _slidePage(const ProfileScreen(), s),
    ),
  ],
);
