import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infio_partner/core/theme/app_theme.dart';
import 'package:infio_partner/features/auth/presentation/landing_screen.dart';
import 'package:infio_partner/features/auth/presentation/login_screen.dart';
import 'package:infio_partner/features/consumer/presentation/consumer_signup_screen.dart';
import 'package:infio_partner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:infio_partner/features/growth/presentation/growth_screen.dart';
import 'package:infio_partner/features/kyc/presentation/video_kyc_screen.dart';
import 'package:infio_partner/features/leads/presentation/lead_detail_screen.dart';
import 'package:infio_partner/features/leads/presentation/lead_inbox_screen.dart';
import 'package:infio_partner/features/membership/presentation/membership_plans_screen.dart';
import 'package:infio_partner/features/membership/presentation/payment_screen.dart';
import 'package:infio_partner/features/onboarding/presentation/step1_basic_screen.dart';
import 'package:infio_partner/features/onboarding/presentation/step2_location_screen.dart';
import 'package:infio_partner/features/onboarding/presentation/step3_photos_screen.dart';
import 'package:infio_partner/features/profile/presentation/profile_screen.dart';
import 'package:infio_partner/features/services/presentation/add_service_screen.dart';
import 'package:infio_partner/features/services/presentation/service_manager_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps one screen with the mock repositories behind it.
///
/// Two testing details matter here.
///
/// The viewport is made phone-wide but very tall. These screens are long
/// scrolling lists, and a `ListView` only builds what fits; at the default
/// 800x600 surface everything below the fold is never constructed and the
/// finders miss it.
///
/// Several screens also animate forever — the pulsing presence dot, the map's
/// coverage ring — so `pumpAndSettle` would time out. Advancing the clock by a
/// fixed amount lets the mock futures resolve without waiting for animations
/// to stop.
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 3000);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.build(), home: screen),
    ),
  );
  await tester.pump();
  // Two waves: some providers (availability, membership) are only mounted
  // once the first request resolves and the data branch builds, so their
  // timers would otherwise still be pending at teardown.
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() {
    // The onboarding draft is persisted locally; start every test clean.
    SharedPreferences.setMockInitialValues({});
  });

  group('auth and onboarding', () {
    testWidgets('landing renders the zero-commission pitch', (tester) async {
      await pumpScreen(tester, const LandingScreen());

      // The headline is one RichText with the second line in primary, so it
      // has to be matched as rich text rather than two plain Texts.
      expect(
        find.textContaining('Get Direct Leads.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Zero Commission.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Register as Partner'), findsOneWidget);
    });

    testWidgets('login offers both OTP channels', (tester) async {
      await pumpScreen(tester, const LoginScreen());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
    });

    testWidgets('Get OTP stays disabled until the number is complete',
        (tester) async {
      await pumpScreen(tester, const LoginScreen());

      final button = find.text('Get OTP');
      expect(button, findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '98490');
      await tester.pump();

      // Still short of ten digits, so the CTA remains dimmed.
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: button, matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, lessThan(1.0));

      await tester.enterText(find.byType(TextField).first, '9849023114');
      await tester.pump();

      final enabled = tester.widget<Opacity>(
        find
            .ancestor(of: button, matching: find.byType(Opacity))
            .first,
      );
      expect(enabled.opacity, 1.0);
    });

    testWidgets('step 1 pre-fills the saved draft', (tester) async {
      await pumpScreen(tester, const Step1BasicScreen());

      expect(find.text('Basic Details & Account'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Apex Aircon Works'), findsWidgets);
      expect(find.text('Sole Proprietor'), findsOneWidget);
    });

    testWidgets('step 2 shows the radius and specializations', (tester) async {
      await pumpScreen(tester, const Step2LocationScreen());

      expect(find.text('Business Details & Address'), findsOneWidget);
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('15 km reach'), findsOneWidget);
      expect(find.text('Split AC'), findsOneWidget);
    });

    testWidgets('step 3 starts with an empty portfolio', (tester) async {
      await pumpScreen(tester, const Step3PhotosScreen());

      expect(find.text('Business Photos'), findsOneWidget);
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('0 of 5 uploaded'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('consumer signup is reachable but clearly InFio SEARCH',
        (tester) async {
      await pumpScreen(tester, const ConsumerSignupScreen());

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('SEARCH'), findsOneWidget);
    });
  });

  group('core app', () {
    testWidgets('dashboard greets the partner and shows quota', (tester) async {
      await pumpScreen(tester, const DashboardScreen());

      expect(find.text('Hello, Ramesh'), findsOneWidget);
      expect(find.text('Recent New Leads'), findsOneWidget);
      // 12 of 20 leads used leaves 8.
      expect(find.text('8 Remaining'), findsOneWidget);
      expect(find.text('Quota Used (60%)'), findsOneWidget);
    });

    testWidgets('lead inbox segments by status with counts', (tester) async {
      await pumpScreen(tester, const LeadInboxScreen());

      expect(find.text('Lead Inbox'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Contacted'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text("Today's Inflow: 12 Leads"), findsOneWidget);
    });

    testWidgets('lead detail gates the phone number behind acceptance',
        (tester) async {
      await pumpScreen(tester, const LeadDetailScreen(leadId: 'ld_8924'));

      expect(find.text('Lead Details'), findsOneWidget);
      expect(find.text('John D.'), findsOneWidget);
      expect(find.text('Split AC Repair & Maintenance'), findsOneWidget);
      expect(
        find.text('Customer phone number revealed upon accepting lead'),
        findsOneWidget,
      );
      // The quote CTA is seeded from the server's suggestion.
      expect(find.text('Send Quote (₹1,200)'), findsOneWidget);
    });

    testWidgets('quote quick-adjust changes the CTA amount', (tester) async {
      await pumpScreen(tester, const LeadDetailScreen(leadId: 'ld_8924'));

      await tester.tap(find.text('+ ₹50'));
      await tester.pump();

      expect(find.text('Send Quote (₹1,250)'), findsOneWidget);
    });

    testWidgets('service manager lists the catalogue', (tester) async {
      await pumpScreen(tester, const ServiceManagerScreen());

      expect(find.text('Manage Services'), findsOneWidget);
      // Section labels render uppercase.
      expect(find.text('SERVICE CATALOG (4)'), findsOneWidget);
      expect(find.text('Split AC Deep Cleaning / Jet Wash'), findsOneWidget);
      // The paused entry offers a resume action instead of details.
      expect(find.text('Resume Listing'), findsOneWidget);
    });

    testWidgets('add service computes commission live', (tester) async {
      await pumpScreen(tester, const AddServiceScreen());

      expect(find.text('Add New Service'), findsOneWidget);

      final priceField = find.widgetWithText(TextField, '0.00');
      await tester.enterText(priceField, '500');
      await tester.pump();

      expect(
        find.text('InFio partner commission: 10% (₹50.00)'),
        findsOneWidget,
      );
      expect(find.text('You take home: ₹450.00'), findsOneWidget);
    });

    testWidgets('growth renders metrics and the weekly chart', (tester) async {
      await pumpScreen(tester, const GrowthScreen());

      expect(find.text('Business Growth'), findsOneWidget);
      expect(find.text('Total Leads'), findsOneWidget);
      expect(find.text('Weekly Lead Velocity'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('profile shows identity and menu groups', (tester) async {
      await pumpScreen(tester, const ProfileScreen());

      expect(find.text('Account & Profile'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Apex Aircon Works'), findsOneWidget);
      expect(find.text('142 reviews'), findsOneWidget);
      expect(find.text('Log Out of Partner Account'), findsOneWidget);
    });
  });

  group('monetization', () {
    testWidgets('wizard mode shows step 4 chrome', (tester) async {
      await pumpScreen(
        tester,
        const MembershipPlansScreen(mode: PlanScreenMode.wizardStep4),
      );

      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Choose Your Growth Plan'), findsOneWidget);
      expect(find.text('Growth Pro'), findsWidgets);
    });

    testWidgets('manage mode drops the wizard chrome', (tester) async {
      await pumpScreen(
        tester,
        const MembershipPlansScreen(mode: PlanScreenMode.manage),
      );

      expect(find.text('Step 4 of 4'), findsNothing);
      expect(find.text('Membership & Growth'), findsOneWidget);
      expect(find.text('Accelerate Your Business'), findsOneWidget);
      expect(find.text('Keep Free Plan'), findsOneWidget);
    });

    testWidgets('checkout totals are server-computed', (tester) async {
      await pumpScreen(tester, const PaymentScreen());

      expect(find.text('Upgrade Membership'), findsOneWidget);
      expect(find.text('WELCOMEPRO'), findsOneWidget);
      // 999 - 200 = 799, +18% GST = 942.82.
      expect(find.text('₹942.82'), findsWidgets);
      expect(find.text('Statutory GST (18%)'), findsOneWidget);
      expect(find.text('Instant UPI'), findsOneWidget);
    });

    testWidgets('kyc tracks two independent tasks', (tester) async {
      await pumpScreen(tester, const VideoKycScreen());

      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('0/2 Completed'), findsOneWidget);
      expect(find.text('Aadhaar Card Photo'), findsOneWidget);
      expect(find.text('Business / Shop Video'), findsOneWidget);
      expect(find.text('Schedule Verification Call'), findsOneWidget);
    });
  });
}
