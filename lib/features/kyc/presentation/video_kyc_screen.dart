import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/repositories.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/upload_slot.dart';
import '../domain/kyc.dart';

/// Aadhaar document upload plus a 15-second business video.
///
/// Mirrors `partner_video_kyc_native_mobile`.
class VideoKycScreen extends ConsumerStatefulWidget {
  const VideoKycScreen({super.key});

  @override
  ConsumerState<VideoKycScreen> createState() => _VideoKycScreenState();
}

/// The recorder's lifecycle, per the design's implied state machine.
enum RecordPhase { idle, recording, review, submitted }

class _VideoKycScreenState extends ConsumerState<VideoKycScreen> {
  final _picker = ImagePicker();

  static const _clipLimit = Duration(seconds: 15);

  KycState? _state;
  String? _aadhaarFront;
  String? _aadhaarBack;
  String? _videoPath;

  RecordPhase _phase = RecordPhase.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final state = await ref.read(kycRepositoryProvider).fetchState();
    if (mounted) setState(() => _state = state);
  }

  bool get _aadhaarDone => _aadhaarFront != null && _aadhaarBack != null;
  bool get _videoDone => _videoPath != null;
  int get _completed => (_aadhaarDone ? 1 : 0) + (_videoDone ? 1 : 0);
  bool get _canSubmit => _aadhaarDone && _videoDone;

  Future<void> _pickAadhaar({required bool front}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      setState(() {
        if (front) {
          _aadhaarFront = file.path;
        } else {
          _aadhaarBack = file.path;
        }
      });

      if (_aadhaarDone) {
        final updated = await ref.read(kycRepositoryProvider).uploadAadhaar(
              frontPath: _aadhaarFront!,
              backPath: _aadhaarBack!,
            );
        if (mounted) setState(() => _state = updated);
      }
    } catch (_) {
      _notify('Could not open the camera on this device.');
    }
  }

  /// Records the clip. The OS camera UI enforces the 15-second cap; the
  /// in-app timer mirrors it so the viewfinder stays truthful.
  Future<void> _record() async {
    if (_phase == RecordPhase.recording) return;

    setState(() {
      _phase = RecordPhase.recording;
      _elapsed = Duration.zero;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= _clipLimit) t.cancel();
    });

    try {
      final file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: _clipLimit,
        preferredCameraDevice: CameraDevice.front,
      );
      _ticker?.cancel();
      if (!mounted) return;

      if (file == null) {
        setState(() {
          _phase = RecordPhase.idle;
          _elapsed = Duration.zero;
        });
        return;
      }

      setState(() {
        _videoPath = file.path;
        _phase = RecordPhase.review;
      });

      final updated =
          await ref.read(kycRepositoryProvider).uploadVideo(file.path);
      if (mounted) setState(() => _state = updated);
    } catch (_) {
      _ticker?.cancel();
      if (mounted) setState(() => _phase = RecordPhase.idle);
      _notify('Could not open the camera on this device.');
    }
  }

  void _retake() {
    setState(() {
      _videoPath = null;
      _phase = RecordPhase.idle;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);

    try {
      final updated = await ref.read(kycRepositoryProvider).submitForReview();
      if (!mounted) return;
      setState(() {
        _state = updated;
        _phase = RecordPhase.submitted;
        _submitting = false;
      });
      _notify('Submitted for review');
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      _notify('Could not submit. Please try again.');
    }
  }

  Future<void> _scheduleCall() async {
    final when = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (when == null) return;

    final updated = await ref.read(kycRepositoryProvider).scheduleCall(when);
    if (mounted) {
      setState(() => _state = updated);
      _notify('Verification call requested');
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Identity Verification',
        subtitle: 'InFio Business',
        titleStyle: AppText.title15.copyWith(fontWeight: FontWeight.w700),
        statusChip: StatusChip(
          label: '$_completed/2 Completed',
          dense: true,
          showDot: true,
          dotColor: _canSubmit ? AppColors.success : AppColors.tertiaryFixedDim,
          background: AppColors.primary.withValues(alpha: 0.08),
          foreground: AppColors.primary,
          borderColor: AppColors.primaryFixedDim,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.stackMd,
          AppSpacing.stackMd,
          AppSpacing.stackMd,
          AppSpacing.stackLg,
        ),
        children: [
          _trustBanner(),
          const SizedBox(height: AppSpacing.stackMd),
          _statusCard(),
          const SizedBox(height: AppSpacing.stackMd),
          _aadhaarCard(),
          const SizedBox(height: AppSpacing.stackMd),
          _videoCard(),
          const SizedBox(height: AppSpacing.stackMd),
          _scheduleCard(),
        ],
      ),
      bottomNavigationBar: BottomDock(
        caption: _state?.reviewEta,
        child: GradientButton(
          label: 'Submit for Review',
          icon: Symbols.arrow_forward,
          gradient: AppGradients.kyc,
          enabled: _canSubmit,
          busy: _submitting,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _trustBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        gradient: AppGradients.kyc,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: const Icon(
              Symbols.verified_user,
              size: 19,
              color: Colors.white,
              fill: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY VERIFY?',
                  style: AppText.label11.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: AppText.body13.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    children: const [
                      TextSpan(text: 'Verified professionals get '),
                      TextSpan(
                        text: 'up to 3x more leads',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                      TextSpan(text: ' and build trust with customers '
                          'instantly.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final submitted = _state?.status == KycStatus.pendingReview;

    return SolidCard(
      radius: AppRadius.lg,
      borderColor: AppColors.primaryFixedDim,
      child: Row(
        children: [
          IconTile(
            icon: submitted ? Symbols.hourglass_top : Symbols.pending_actions,
            size: 44,
            iconSize: 22,
            background: AppColors.primaryFixed,
            foreground: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submitted ? 'Under Review' : 'Verification Pending',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  submitted
                      ? 'We will notify you once the team completes the check'
                      : 'Complete both steps to unlock leads',
                  style: AppText.label11.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip.warning(
            label: submitted ? 'In Review' : 'Action Needed',
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _aadhaarCard() {
    return SolidCard(
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            number: '1',
            title: 'Aadhaar Card Photo',
            trailing: _aadhaarDone
                ? const StatusChip.success(
                    label: 'Done',
                    icon: Symbols.check_circle,
                    iconFill: 1,
                    dense: true,
                  )
                : StatusChip(
                    label: 'Required',
                    dense: true,
                    background: AppColors.roseSurface,
                    foreground: AppColors.rose,
                    borderColor: AppColors.roseBorder,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload a clear photo of your Aadhaar card (Front & Back).',
            style: AppText.body13,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AadhaarSlot(
                  label: 'Front Side',
                  path: _aadhaarFront,
                  icon: Symbols.photo_camera,
                  onTap: () => _pickAadhaar(front: true),
                ),
              ),
              const SizedBox(width: AppSpacing.gridGutter),
              Expanded(
                child: _AadhaarSlot(
                  label: 'Back Side',
                  path: _aadhaarBack,
                  icon: Symbols.cloud_upload,
                  onTap: () => _pickAadhaar(front: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Symbols.lock,
                size: 14,
                color: AppColors.success,
                fill: 1,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your official ID is encrypted and protected under 256-bit '
                  'security.',
                  style: AppText.label10.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _videoCard() {
    return SolidCard(
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            number: '2',
            title: 'Business / Shop Video',
            trailing: _videoDone
                ? const StatusChip.success(
                    label: 'Recorded',
                    icon: Symbols.check_circle,
                    iconFill: 1,
                    dense: true,
                  )
                : const StatusChip.primary(label: '15s Limit', dense: true),
          ),
          const SizedBox(height: 10),
          Text(
            'Record a 15-second video showing your shop or tools and yourself.',
            style: AppText.body13,
          ),
          const SizedBox(height: 12),
          _viewfinder(),
          const SizedBox(height: 10),
          if (_phase == RecordPhase.review)
            Row(
              children: [
                Expanded(
                  child: OutlineActionButton(
                    label: 'Retake',
                    icon: Symbols.refresh,
                    height: 42,
                    onPressed: _retake,
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.3),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppText.label11.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Tip: ',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'Ensure good lighting and that your face is '
                                'clearly visible.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A design-faithful viewfinder. The device camera opens in its own UI on
  /// tap, so this panel carries the framing guide, timer and record control.
  Widget _viewfinder() {
    final recording = _phase == RecordPhase.recording;
    final done = _phase == RecordPhase.review;

    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: Container(
        height: 176,
        width: double.infinity,
        color: AppColors.slate900,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.viewfinderScrim,
                ),
              ),
            ),
            // Framing guide.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.base),
                  ),
                ),
              ),
            ),
            // Duration badge.
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (recording)
                      const PulsingDot(color: AppColors.error, size: 7)
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      '00:${(recording ? _clipLimit - _elapsed : _clipLimit).inSeconds.toString().padLeft(2, '0')}',
                      style: AppText.label10.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: CircleIconButton(
                icon: Symbols.cameraswitch,
                size: 30,
                iconSize: 16,
                background: Colors.black.withValues(alpha: 0.4),
                foreground: Colors.white,
                tooltip: 'Flip camera',
                onPressed: () {},
              ),
            ),
            // Record control.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: done ? null : _record,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: done ? null : AppGradients.record,
                        color: done ? AppColors.success : null,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        done ? Symbols.check : Symbols.videocam,
                        size: 30,
                        color: Colors.white,
                        fill: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (_phase) {
                      RecordPhase.recording => 'Recording...',
                      RecordPhase.review => 'Clip captured',
                      RecordPhase.submitted => 'Submitted',
                      RecordPhase.idle => 'Tap to Record',
                    },
                    style: AppText.label11.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Text(
                'Selfie or front camera allowed',
                textAlign: TextAlign.center,
                style: AppText.label10.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleCard() {
    final scheduled = _state?.scheduledCallAt;

    return SolidCard(
      radius: AppRadius.lg,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceContainerLowest, AppColors.surfaceContainerLow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const IconTile(
                icon: Symbols.support_agent,
                size: 44,
                iconSize: 22,
                shape: BoxShape.circle,
                background: AppColors.primaryFixed,
                foreground: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prefer a live verification?',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Schedule a quick 2-minute video call with our '
                      'verification team instead.',
                      style: AppText.label11.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlineActionButton(
            label: scheduled == null
                ? 'Schedule Verification Call'
                : 'Call requested',
            icon: Symbols.calendar_today,
            height: 46,
            borderColor: AppColors.primary,
            onPressed: _scheduleCall,
          ),
        ],
      ),
    );
  }

  Widget _stepHeader({
    required String number,
    required String title,
    required Widget trailing,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppGradients.ctaDiagonal,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: AppText.label10.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            trailing,
          ],
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }
}

class _AadhaarSlot extends StatelessWidget {
  const _AadhaarSlot({
    required this.label,
    required this.path,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? path;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return UploadSlot(
        file: File(path!),
        caption: label,
        height: 128,
        onTap: onTap,
      );
    }

    return UploadSlot(
      height: 128,
      emphasised: true,
      emptyIcon: icon,
      emptyLabel: label,
      slotLabel: 'Tap to upload',
      onTap: onTap,
    );
  }
}
