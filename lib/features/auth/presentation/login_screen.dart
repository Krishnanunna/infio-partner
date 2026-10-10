import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/infio_logo.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

/// Existing-partner sign in, mobile-number first.
///
/// Mirrors `infio_business_partner_mobile_login`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  OtpChannel _channel = OtpChannel.whatsapp;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => _phone.text.trim().length == 10;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).requestOtp(
            phone: '+91 ${_phone.text.trim()}',
            channel: _channel,
          );
      if (mounted) context.push('/otp');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the code. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBlobs(blobs: AmbientBlobs.partner),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.stackLg),
                            _brandAnchor(),
                            const SizedBox(height: AppSpacing.stackLg),
                            _loginCard(context),
                            const SizedBox(height: AppSpacing.stackMd),
                            _footer(context),
                            const SizedBox(height: AppSpacing.stackLg),
                          ],
                        ),
                      ),
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

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
        child: Row(
          children: [
            CircleIconButton(
              icon: Symbols.arrow_back,
              tooltip: 'Go back',
              borderColor: AppColors.outlineVariant,
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PARTNER PORTAL',
                    style: AppText.label10.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CircleIconButton(
              icon: Symbols.help_outline,
              tooltip: 'Need help',
              borderColor: AppColors.outlineVariant,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandAnchor() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const InfioLogo(size: 44),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text('Welcome Back', style: AppText.headlineLgMobile),
        const SizedBox(height: 4),
        Text(
          'Sign in with your registered mobile number',
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _loginCard(BuildContext context) {
    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.78,
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label: 'Mobile Number',
            required: true,
            child: _phoneField(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppText.label11.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),

          // Delivery channel, WhatsApp by default.
          Row(
            children: [
              Text(
                'Send OTP via',
                style: AppText.label11.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SegmentedPill<OtpChannel>(
                  height: 38,
                  trackColor: AppColors.surfaceContainer,
                  showBorder: false,
                  value: _channel,
                  onChanged: (v) => setState(() => _channel = v),
                  options: const [
                    SegmentOption(
                      value: OtpChannel.whatsapp,
                      label: 'WhatsApp',
                    ),
                    SegmentOption(value: OtpChannel.sms, label: 'SMS'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),

          GradientButton(
            label: 'Get OTP',
            icon: Symbols.arrow_forward,
            enabled: _valid,
            busy: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.stackMd),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: AppText.label10),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 6),

          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Symbols.mail, size: 18),
            label: const Text('Sign in with Email & Password'),
          ),
        ],
      ),
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _phone.text.isEmpty
              ? AppColors.outlineVariant
              : AppColors.primaryContainer,
          width: _phone.text.isEmpty ? 1 : 2,
        ),
      ),
      child: Row(
        children: [
          // Non-editable country prefix.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.smartphone,
                  size: 17,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '+91',
                  style: AppText.title15.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.outlineVariant),
          Expanded(
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: AppText.title15,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Enter 10-digit number',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      children: [
        // Wrap rather than Row: on narrow handsets these lines would
        // otherwise overflow horizontally.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New to InFio Business? ', style: AppText.body13),
            GestureDetector(
              onTap: () => context.push('/onboarding/step1'),
              child: Text(
                'Register now',
                style: AppText.body13.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            const Icon(
              Symbols.lock,
              size: 13,
              color: AppColors.secondary,
              fill: 1,
            ),
            Text(
              '256-Bit Encrypted Secure Partner Gateway',
              style: AppText.label10.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
