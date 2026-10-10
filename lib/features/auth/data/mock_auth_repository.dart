import '../domain/auth_repository.dart';

/// Accepts any six-digit code except an explicit failure case, so the OTP
/// screen's error state stays reachable during a walkthrough.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  static Duration get _latency => const Duration(milliseconds: 700);

  /// Entering this code demonstrates the invalid-code state.
  static const rejectedCode = '000000';

  int _counter = 0;
  String _phone = '';

  @override
  Future<OtpChallenge> requestOtp({
    required String phone,
    required OtpChannel channel,
  }) async {
    await Future<void>.delayed(_latency);
    _phone = phone;
    return OtpChallenge(
      challengeId: 'chl_${++_counter}',
      phone: phone,
      channel: channel,
      resendAfter: const Duration(seconds: 60),
    );
  }

  @override
  Future<OtpChallenge> resendOtp({
    required String challengeId,
    required OtpChannel channel,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return OtpChallenge(
      challengeId: challengeId,
      phone: _phone,
      channel: channel,
      resendAfter: const Duration(seconds: 60),
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);

    if (code == rejectedCode || code.length != 6) {
      throw const InvalidOtpException();
    }

    return const AuthSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      partnerId: 'ptr_1001',
      isNewPartner: false,
    );
  }

  @override
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    return const AuthSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      partnerId: 'ptr_1001',
      isNewPartner: false,
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
