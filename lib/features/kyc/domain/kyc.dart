/// Review state of the whole KYC submission.
enum KycStatus {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  pendingReview('pending_review', 'Verification Pending'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected');

  const KycStatus(this.wire, this.label);

  final String wire;
  final String label;

  static KycStatus fromWire(String v) => KycStatus.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => KycStatus.notStarted,
      );
}

/// The two artefacts the partner must supply.
enum KycTaskKind {
  aadhaar('aadhaar', 'Aadhaar Card Photo'),
  businessVideo('business_video', 'Business / Shop Video');

  const KycTaskKind(this.wire, this.label);

  final String wire;
  final String label;

  static KycTaskKind fromWire(String v) => KycTaskKind.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => KycTaskKind.aadhaar,
      );
}

/// One verification task and whether it is done.
class KycTask {
  const KycTask({
    required this.kind,
    required this.completed,
    this.submittedAt,
  });

  final KycTaskKind kind;
  final bool completed;
  final DateTime? submittedAt;

  factory KycTask.fromJson(Map<String, dynamic> json) => KycTask(
        kind: KycTaskKind.fromWire(json['kind'] as String),
        completed: json['completed'] as bool? ?? false,
        submittedAt: json['submitted_at'] == null
            ? null
            : DateTime.parse(json['submitted_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.wire,
        'completed': completed,
        'submitted_at': submittedAt?.toIso8601String(),
      };
}

/// Aggregate KYC state, driving the "0/2 Completed" pill and status card.
class KycState {
  const KycState({
    required this.status,
    required this.tasks,
    this.reviewEta = 'Usually reviewed within 2 hours by the InFio team',
    this.scheduledCallAt,
  });

  final KycStatus status;
  final List<KycTask> tasks;
  final String reviewEta;

  /// Set when the partner books the live alternative instead.
  final DateTime? scheduledCallAt;

  int get completedCount => tasks.where((t) => t.completed).length;

  int get totalCount => tasks.length;

  bool get canSubmit => completedCount == totalCount && totalCount > 0;

  bool isDone(KycTaskKind kind) =>
      tasks.any((t) => t.kind == kind && t.completed);

  KycState copyWith({
    KycStatus? status,
    List<KycTask>? tasks,
    DateTime? scheduledCallAt,
  }) {
    return KycState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      reviewEta: reviewEta,
      scheduledCallAt: scheduledCallAt ?? this.scheduledCallAt,
    );
  }

  factory KycState.fromJson(Map<String, dynamic> json) => KycState(
        status: KycStatus.fromWire(json['status'] as String? ?? 'not_started'),
        tasks: ((json['tasks'] as List<dynamic>?) ?? [])
            .map((t) => KycTask.fromJson(t as Map<String, dynamic>))
            .toList(),
        reviewEta: json['review_eta'] as String? ??
            'Usually reviewed within 2 hours by the InFio team',
        scheduledCallAt: json['scheduled_call_at'] == null
            ? null
            : DateTime.parse(json['scheduled_call_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'status': status.wire,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'review_eta': reviewEta,
        'scheduled_call_at': scheduledCallAt?.toIso8601String(),
      };
}
