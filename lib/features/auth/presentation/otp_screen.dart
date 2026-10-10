import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/otp_input.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

/// Six-digit verification with a 60-second resend cooldown.
///
/// Mirrors `partner_otp_verification_native_mobile`.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpKey = GlobalKey<OtpInputRowState>();

  Timer? _timer;
  Duration _remaining = const Duration(seconds: 60);
  String _code = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = const Duration(seconds: 60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  bool get _canResend => _remaining == Duration.zero;

  String get _countdown {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resend(OtpChannel channel) async {
    if (!_canResend) return;
    try {
      await ref.read(authControllerProvider.notifier).resend(channel);
      _otpKey.currentState?.clear();
      setState(() => _error = null);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code resent via ${channel.label}')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend. Try again.');
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final session = await ref.read(authControllerProvider.notifier).verify(_code);
      if (!mounted) return;
      context.go(session.isNewPartner ? '/onboarding/step1' : '/dashboard');
    } on InvalidOtpException catch (e) {
      _otpKey.currentState?.clear();
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Verification failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(authControllerProvider).challenge;
    final phone = challenge?.phone ?? '+91 98490 23114';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackLg,
                  AppSpacing.containerMargin,
                  AppSpacing.stackLg,
                ),
                child: Column(
                  children: [
                    _heroIcon(),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Verify Mobile Number', style: AppText.headlineLg),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'We have sent a 6-digit verification code to',
                      style: AppText.bodySm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    _numberPill(context, phone),
                    const SizedBox(height: AppSpacing.stackLg),
                    OtpInputRow(
                      key: _otpKey,
                      hasError: _error != null,
                      onChanged: (v) => setState(() => _code = v),
                      onCompleted: (_) => _verify(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: AppText.label11.copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.stackLg),
                    _resendCluster(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomDock(
        caption: '100% Secure & End-to-End Encrypted Verification',
        child: GradientButton(
          label: 'Verify & Continue',
          icon: Symbols.arrow_forward,
          gradient: AppGradients.ctaDiagonal,
          radius: AppRadius.lg,
          height: 52,
          enabled: _code.length == 6,
          busy: _busy,
          onPressed: _verify,
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
        child: Row(
          children: [
            CircleIconButton(
              icon: Symbols.arrow_back,
              size: 36,
              iconSize: 18,
              tooltip: 'Go back',
              borderColor: AppColors.outlineVariant,
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Partner Verification',
                    style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'INFIO BUSINESS',
                    style: AppText.label10.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            IconTile(
              icon: Symbols.verified_user,
              size: 36,
              iconSize: 19,
              background: AppColors.primary.withValues(alpha: 0.1),
              foreground: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryContainer, Color(0xFF7B1FA2)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.primaryGlow,
          ),
          child: const Icon(
            Symbols.phonelink_lock,
            size: 38,
            color: Colors.white,
          ),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryFixed, width: 2),
            ),
            child: const Icon(
              Symbols.lock,
              size: 14,
              color: AppColors.primary,
              fill: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberPill(BuildContext context, String phone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phone,
            style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/login'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.edit, size: 14, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  'Edit',
                  style: AppText.label11.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resendCluster() {
    return Column(
      children: [
        if (!_canResend)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.schedule,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text('Resend code in ', style: AppText.label11),
              Text(
                _countdown,
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        else
          Text(
            'Did not receive the code?',
            style: AppText.label11,
          ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _resendButton(
              icon: Symbols.sms,
              label: 'Resend via SMS',
              color: AppColors.primary,
              channel: OtpChannel.sms,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('•', style: AppText.label11),
            ),
            _resendButton(
              icon: Symbols.chat,
              label: 'Via WhatsApp',
              color: AppColors.whatsappDark,
              channel: OtpChannel.whatsapp,
            ),
          ],
        ),
      ],
    );
  }

  Widget _resendButton({
    required IconData icon,
    required String label,
    required Color color,
    required OtpChannel channel,
  }) {
    final enabled = _canResend;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => _resend(channel) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.label11.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
