import '../domain/kyc.dart';
import '../domain/kyc_repository.dart';

/// Tracks the two KYC artefacts in memory, starting from the design's
/// "0/2 Completed" state.
class MockKycRepository implements KycRepository {
  MockKycRepository();

  static Duration get _latency => const Duration(milliseconds: 420);

  KycState _state = const KycState(
    status: KycStatus.notStarted,
    tasks: [
      KycTask(kind: KycTaskKind.aadhaar, completed: false),
      KycTask(kind: KycTaskKind.businessVideo, completed: false),
    ],
  );

  KycState _complete(KycTaskKind kind) {
    final tasks = _state.tasks
        .map((t) => t.kind == kind
            ? KycTask(kind: kind, completed: true, submittedAt: DateTime.now())
            : t)
        .toList();

    return _state.copyWith(
      tasks: tasks,
      status: tasks.every((t) => t.completed)
          ? KycStatus.inProgress
          : KycStatus.inProgress,
    );
  }

  @override
  Future<KycState> fetchState() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _state;
  }

  @override
  Future<KycState> uploadAadhaar({
    required String frontPath,
    required String backPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _state = _complete(KycTaskKind.aadhaar);
    return _state;
  }

  @override
  Future<KycState> uploadVideo(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _state = _complete(KycTaskKind.businessVideo);
    return _state;
  }

  @override
  Future<KycState> submitForReview() async {
    await Future<void>.delayed(const Duration(milliseconds: 950));
    _state = _state.copyWith(status: KycStatus.pendingReview);
    return _state;
  }

  @override
  Future<KycState> scheduleCall(DateTime when) async {
    await Future<void>.delayed(_latency);
    _state = _state.copyWith(scheduledCallAt: when);
    return _state;
  }
}
