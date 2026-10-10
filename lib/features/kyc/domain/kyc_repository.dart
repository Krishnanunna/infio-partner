import 'kyc.dart';

/// Mirrors `/v1/partners/me/kyc` in `docs/API_SPEC.md`.
abstract interface class KycRepository {
  /// `GET /v1/partners/me/kyc`
  Future<KycState> fetchState();

  /// `POST /v1/partners/me/kyc/aadhaar` — multipart, front and back.
  Future<KycState> uploadAadhaar({
    required String frontPath,
    required String backPath,
  });

  /// `POST /v1/partners/me/kyc/video` — the 15-second business clip.
  Future<KycState> uploadVideo(String path);

  /// `POST /v1/partners/me/kyc/submit`
  Future<KycState> submitForReview();

  /// `POST /v1/partners/me/kyc/schedule-call`
  Future<KycState> scheduleCall(DateTime when);
}
