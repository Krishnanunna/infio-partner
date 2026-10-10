import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Six single-digit boxes with the three states the design specifies:
/// filled (2px primary-40 border showing a masked dot), active (2px solid
/// primary with a focus ring and blinking caret), and empty (1px outline).
class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.masked = true,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  /// Renders a dot instead of the digit, as the design does.
  final bool masked;

  final bool hasError;

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers = List.generate(
    widget.length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    widget.length,
    (_) => FocusNode(),
  );

  String get value => _controllers.map((c) => c.text).join();

  /// Clears every box and returns focus to the first — used when the server
  /// rejects a code.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
    setState(() {});
    widget.onChanged?.call('');
  }

  @override
  void initState() {
    super.initState();
    for (final node in _nodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String text) {
    if (text.length > 1) {
      // A paste or autofill: distribute across the boxes.
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
    } else if (text.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }

    setState(() {});
    final joined = value;
    widget.onChanged?.call(joined);
    if (joined.length == widget.length) {
      _nodes[index].unfocus();
      widget.onCompleted?.call(joined);
    }
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      setState(() {});
      widget.onChanged?.call(value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < widget.length; i++) _box(i),
        ],
      ),
    );
  }

  Widget _box(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    final focused = _nodes[index].hasFocus;

    final Color borderColor;
    final double borderWidth;
    if (widget.hasError) {
      borderColor = AppColors.error;
      borderWidth = 2;
    } else if (focused) {
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else if (filled) {
      borderColor = AppColors.primary.withValues(alpha: 0.4);
      borderWidth = 2;
    } else {
      borderColor = AppColors.outlineVariant;
      borderWidth = 1;
    }

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.primaryFixedDim.withValues(alpha: 0.4),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : const [],
          ),
          child: Focus(
            onKeyEvent: (_, event) => _onKey(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _nodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              obscureText: widget.masked,
              obscuringCharacter: '●',
              showCursor: true,
              cursorColor: AppColors.primary,
              cursorWidth: 2,
              cursorHeight: 22,
              style: AppText.headlineLg.copyWith(
                fontSize: 22,
                color: AppColors.primary,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (t) => _onChanged(index, t),
            ),
          ),
        ),
      ),
    );
  }
}
