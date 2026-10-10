import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/infio_logo.dart';
import '../../../shared/widgets/section_card.dart';

/// Consumer-side account creation for InFio SEARCH.
///
/// This screen belongs to the customer app, not the partner one — it is
/// included because it ships in the design folder. Its endpoints live under
/// a separate consumer service and are documented as out of scope in
/// `docs/API_SPEC.md`.
class ConsumerSignupScreen extends StatefulWidget {
  const ConsumerSignupScreen({super.key});

  @override
  State<ConsumerSignupScreen> createState() => _ConsumerSignupScreenState();
}

class _ConsumerSignupScreenState extends State<ConsumerSignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _referral = TextEditingController();

  bool _acceptedTerms = true;
  bool _referralOpen = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().length == 10 &&
      _acceptedTerms;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBlobs(blobs: AmbientBlobs.consumer),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.stackLg),
                            Text(
                              'Create Account',
                              style: AppText.headlineLg.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join InFio to find trusted local services',
                              style: AppText.bodySm,
                            ),
                            const SizedBox(height: AppSpacing.stackLg),
                            _formCard(),
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
            Row(
              children: [
                const InfioLogo(size: 28),
                const SizedBox(width: 8),
                Text(
                  'InFio',
                  style: AppText.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 5),
                Text(
                  'SEARCH',
                  style: AppText.label10.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.78,
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label: 'FULL NAME',
            required: true,
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Rahul Sharma',
                prefixIcon: Icon(Symbols.person, size: 19),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          FieldLabel(
            label: 'MOBILE NUMBER',
            required: true,
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                hintText: '98765 43210',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text('🇮🇳 +91'),
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          FieldLabel(
            label: 'EMAIL ADDRESS',
            hint: '(Optional)',
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Symbols.mail, size: 19),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gridGutter),

          // Collapsible referral section.
          GestureDetector(
            onTap: () => setState(() => _referralOpen = !_referralOpen),
            child: Row(
              children: [
                const Icon(
                  Symbols.redeem,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Have a referral code?',
                  style: AppText.label11.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  _referralOpen ? Symbols.expand_less : Symbols.expand_more,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          if (_referralOpen) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _referral,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'ENTER CODE',
                suffixIcon: TextButton(
                  onPressed: () {},
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),

          // Terms.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) =>
                      setState(() => _acceptedTerms = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.label11.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                    children: const [
                      TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),

          GradientButton(
            label: 'Send OTP',
            icon: Symbols.arrow_forward,
            enabled: _valid,
            onPressed: () => context.push('/otp'),
          ),
          const SizedBox(height: AppSpacing.gridGutter),

          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Icon(
                Symbols.verified_user,
                size: 13,
                color: AppColors.success,
                fill: 1,
              ),
              Text('100% Safe', style: AppText.label10),
              Text('•', style: AppText.label10),
              const Icon(
                Symbols.bolt,
                size: 13,
                color: AppColors.primary,
                fill: 1,
              ),
              Text('Instant Verification', style: AppText.label10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already registered? ', style: AppText.body13),
        GestureDetector(
          onTap: () => context.push('/login'),
          child: Row(
            children: [
              Text(
                'Log In',
                style: AppText.body13.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Symbols.chevron_right,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
