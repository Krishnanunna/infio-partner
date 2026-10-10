import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_draft.dart';

/// Persists the wizard draft to device storage so "Save Draft & Exit" and
/// the profile screen's resume banner both work across launches.
///
/// The HTTP implementation will mirror this to the server; the local cache
/// stays as an offline buffer.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository();

  static const _key = 'infio.onboarding.draft';

  @override
  Future<OnboardingDraft> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return _seeded();

    try {
      return OnboardingDraft.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      // A corrupt cache should never block onboarding.
      await prefs.remove(_key);
      return _seeded();
    }
  }

  @override
  Future<void> saveDraft(OnboardingDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  @override
  Future<OnboardingDraft> submitStep(int step, OnboardingDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final updated = draft.copyWith(
      completedSteps: {...draft.completedSteps, step},
      currentStep: step + 1,
    );
    await saveDraft(updated);
    return updated;
  }

  @override
  Future<void> complete(OnboardingDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await saveDraft(
      draft.copyWith(completedSteps: {1, 2, 3, 4}, currentStep: 4),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// A first run starts pre-filled the way the Stitch step-1 mock is, so the
  /// built screen matches the render.
  OnboardingDraft _seeded() => const OnboardingDraft(
        businessName: 'Apex Aircon Works',
        ownerName: 'Ramesh Kumar',
        phone: '98490 23114',
        phoneVerified: true,
        email: 'ramesh.apex@gmail.com',
        cityId: 'hyderabad',
        categorySlug: 'ac_repair',
        specializations: {
          'Split AC',
          'Window AC',
          'Gas Charging',
          'PCB Diagnostics',
        },
        experienceBand: '3-5 Years',
        shopName: 'Apex Aircon Works',
        street: 'Plot 28, Road No. 3, KPHB Phase 1',
        landmark: 'Opposite Metro Pillar 742',
        pincode: '500072',
        latitude: 17.4934,
        longitude: 78.3995,
        locality: 'KPHB Colony, Kukatpally',
        serviceRadiusKm: 15,
      );
}
