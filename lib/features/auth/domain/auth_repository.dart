/// How the one-time code is delivered. The login screen defaults to
/// WhatsApp and offers SMS as the alternative.
enum OtpChannel {
  whatsapp('whatsapp', 'WhatsApp'),
  sms('sms', 'SMS');

  const OtpChannel(this.wire, this.label);

  final String wire;
  final String label;

  static OtpChannel fromWire(String v) => OtpChannel.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => OtpChannel.whatsapp,
      );
}

/// Server acknowledgement of an OTP request.
class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.phone,
    required this.channel,
    required this.resendAfter,
    this.codeLength = 6,
  });

  final String challengeId;
  final String phone;
  final OtpChannel channel;

  /// Cooldown before a resend is allowed. The design counts down from 60s.
  final Duration resendAfter;

  final int codeLength;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        challengeId: json['challenge_id'] as String,
        phone: json['phone'] as String,
        channel: OtpChannel.fromWire(json['channel'] as String? ?? 'whatsapp'),
        resendAfter: Duration(seconds: json['resend_after_seconds'] as int? ?? 60),
        codeLength: json['code_length'] as int? ?? 6,
      );

  Map<String, dynamic> toJson() => {
        'challenge_id': challengeId,
        'phone': phone,
        'channel': channel.wire,
        'resend_after_seconds': resendAfter.inSeconds,
        'code_length': codeLength,
      };
}

/// An authenticated session.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.partnerId,
    required this.isNewPartner,
  });

  final String accessToken;
  final String refreshToken;
  final String partnerId;

  /// Routes a first-time partner into onboarding rather than the dashboard.
  final bool isNewPartner;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        partnerId: json['partner_id'] as String,
        isNewPartner: json['is_new_partner'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'partner_id': partnerId,
        'is_new_partner': isNewPartner,
      };
}

/// Raised when the submitted code does not match.
class InvalidOtpException implements Exception {
  const InvalidOtpException([this.message = 'That code is incorrect']);

  final String message;

  @override
  String toString() => message;
}

/// Mirrors `/v1/auth` in `docs/API_SPEC.md`.
abstract interface class AuthRepository {
  /// `POST /v1/auth/otp/request`
  Future<OtpChallenge> requestOtp({
    required String phone,
    required OtpChannel channel,
  });

  /// `POST /v1/auth/otp/resend`
  Future<OtpChallenge> resendOtp({
    required String challengeId,
    required OtpChannel channel,
  });

  /// `POST /v1/auth/otp/verify`
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required String code,
  });

  /// `POST /v1/auth/login/email` — the login screen offers this second path.
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  });

  /// `POST /v1/auth/logout`
  Future<void> logout();
}
