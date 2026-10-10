import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/consumer/presentation/consumer_signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/growth/presentation/growth_screen.dart';
import '../../features/kyc/presentation/video_kyc_screen.dart';
import '../../features/leads/presentation/lead_detail_screen.dart';
import '../../features/leads/presentation/lead_inbox_screen.dart';
import '../../features/membership/presentation/membership_plans_screen.dart';
import '../../features/membership/presentation/payment_screen.dart';
import '../../features/onboarding/presentation/step1_basic_screen.dart';
import '../../features/onboarding/presentation/step2_location_screen.dart';
import '../../features/onboarding/presentation/step3_photos_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/services/presentation/add_service_screen.dart';
import '../../features/services/presentation/service_manager_screen.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'app_shell.dart';

/// Declarative routes.
///
/// Auth and wizard screens sit outside the shell so they render without a
/// bottom bar, matching the exports which explicitly suppress it on linear
/// journeys. The four tabs live inside a [StatefulShellRoute] so each keeps
/// its own navigation stack.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
    GoRoute(
      path: '/consumer-signup',
      builder: (_, _) => const ConsumerSignupScreen(),
    ),

    // Onboarding wizard.
    GoRoute(
      path: '/onboarding/step1',
      builder: (_, _) => const Step1BasicScreen(),
    ),
    GoRoute(
      path: '/onboarding/step2',
      builder: (_, _) => const Step2LocationScreen(),
    ),
    GoRoute(
      path: '/onboarding/step3',
      builder: (_, _) => const Step3PhotosScreen(),
    ),
    GoRoute(
      path: '/onboarding/step4',
      builder: (_, _) =>
          const MembershipPlansScreen(mode: PlanScreenMode.wizardStep4),
    ),

    GoRoute(path: '/kyc', builder: (_, _) => const VideoKycScreen()),
    GoRoute(
      path: '/membership',
      builder: (_, _) => const MembershipPlansScreen(mode: PlanScreenMode.manage),
    ),
    GoRoute(path: '/checkout', builder: (_, _) => const PaymentScreen()),

    // Pushed leaf screens that keep their own back arrow.
    GoRoute(
      path: '/leads/:id',
      builder: (_, state) =>
          LeadDetailScreen(leadId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/services',
      builder: (_, _) => const ServiceManagerScreen(),
    ),
    GoRoute(
      path: '/services/new',
      builder: (_, _) => const AddServiceScreen(),
    ),

    // The four bottom tabs.
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: InfioTab.dashboard.route,
              builder: (_, _) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: InfioTab.leads.route,
              builder: (_, _) => const LeadInboxScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: InfioTab.growth.route,
              builder: (_, _) => const GrowthScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: InfioTab.account.route,
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('No route for ${state.uri}')),
  ),
);
