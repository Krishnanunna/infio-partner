import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../domain/onboarding_draft.dart';

/// Holds the wizard draft and writes it through on every edit, so
/// "Save Draft & Exit" and the profile resume banner stay accurate.
class OnboardingController extends AsyncNotifier<OnboardingDraft> {
  @override
  Future<OnboardingDraft> build() {
    return ref.watch(onboardingRepositoryProvider).loadDraft();
  }

  OnboardingDraft get _current =>
      state.value ?? const OnboardingDraft();

  /// Applies a local edit immediately and persists in the background.
  void edit(OnboardingDraft Function(OnboardingDraft) transform) {
    final next = transform(_current);
    state = AsyncValue.data(next);
    ref.read(onboardingRepositoryProvider).saveDraft(next);
  }

  /// Marks a step complete on the server and advances.
  Future<void> submitStep(int step) async {
    final updated = await ref
        .read(onboardingRepositoryProvider)
        .submitStep(step, _current);
    state = AsyncValue.data(updated);
  }

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).complete(_current);
    ref.invalidateSelf();
  }

  Future<void> saveDraft() async {
    await ref.read(onboardingRepositoryProvider).saveDraft(_current);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingDraft>(
  OnboardingController.new,
);
