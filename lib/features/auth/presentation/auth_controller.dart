import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../domain/auth_repository.dart';

/// Carries the in-flight OTP challenge between the login and verification
/// screens so the OTP screen knows which number and channel to show.
class AuthState {
  const AuthState({this.challenge, this.session});

  final OtpChallenge? challenge;
  final AuthSession? session;

  AuthState copyWith({OtpChallenge? challenge, AuthSession? session}) =>
      AuthState(
        challenge: challenge ?? this.challenge,
        session: session ?? this.session,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<OtpChallenge> requestOtp({
    required String phone,
    required OtpChannel channel,
  }) async {
    final challenge = await _repo.requestOtp(phone: phone, channel: channel);
    state = state.copyWith(challenge: challenge);
    return challenge;
  }

  Future<OtpChallenge> resend(OtpChannel channel) async {
    final current = state.challenge;
    if (current == null) {
      throw StateError('No OTP challenge in flight');
    }
    final refreshed = await _repo.resendOtp(
      challengeId: current.challengeId,
      channel: channel,
    );
    state = state.copyWith(challenge: refreshed);
    return refreshed;
  }

  Future<AuthSession> verify(String code) async {
    final current = state.challenge;
    if (current == null) {
      throw StateError('No OTP challenge in flight');
    }
    final session = await _repo.verifyOtp(
      challengeId: current.challengeId,
      code: code,
    );
    state = state.copyWith(session: session);
    return session;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
