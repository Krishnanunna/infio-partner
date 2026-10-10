import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/growth/data/mock_growth_repository.dart';
import '../../features/growth/domain/growth_repository.dart';
import '../../features/kyc/data/mock_kyc_repository.dart';
import '../../features/kyc/domain/kyc_repository.dart';
import '../../features/leads/data/mock_leads_repository.dart';
import '../../features/leads/domain/leads_repository.dart';
import '../../features/membership/data/mock_membership_repository.dart';
import '../../features/membership/domain/membership_repository.dart';
import '../../features/onboarding/data/local_onboarding_repository.dart';
import '../../features/onboarding/domain/onboarding_draft.dart';
import '../../features/profile/data/mock_partner_repository.dart';
import '../../features/profile/domain/partner_repository.dart';
import '../../features/services/data/mock_services_repository.dart';
import '../../features/services/domain/services_repository.dart';

/// Every repository binding lives here.
///
/// Each provider returns the interface, never the concrete class, so moving
/// to a live backend means changing only the right-hand side of these
/// lines — for example:
///
/// ```dart
/// final leadsRepositoryProvider = Provider<LeadsRepository>(
///   (ref) => HttpLeadsRepository(ref.read(dioProvider)),
/// );
/// ```
///
/// The mock implementations are seeded from the Stitch designs and return
/// futures with realistic latency, so loading states are exercised.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => MockPartnerRepository(),
);

final leadsRepositoryProvider = Provider<LeadsRepository>(
  (ref) => MockLeadsRepository(),
);

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (ref) => MockServicesRepository(),
);

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MockMembershipRepository(),
);

final growthRepositoryProvider = Provider<GrowthRepository>(
  (ref) => MockGrowthRepository(),
);

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => MockKycRepository(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => LocalOnboardingRepository(),
);
