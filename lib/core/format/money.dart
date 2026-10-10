import 'package:intl/intl.dart';

/// Indian-locale currency formatting.
///
/// The designs render amounts with en_IN digit grouping (lakh/crore style:
/// 1,20,000 rather than 120,000), so every rupee value in the app goes
/// through here.
abstract final class Money {
  static final _whole = NumberFormat.decimalPattern('en_IN')
    ..maximumFractionDigits = 0;

  static final _withPaise = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  /// `1200` -> `₹1,200`
  static String rupees(num amount) => '₹${_whole.format(amount)}';

  /// `1200` -> `1,200` (for fields that render the ₹ symbol separately).
  static String plain(num amount) => _whole.format(amount);

  /// `942.82` -> `₹942.82` — used on the payment order summary.
  static String rupeesPaise(num amount) => '₹${_withPaise.format(amount)}';

  /// `1000, 1500` -> `₹1,000 - ₹1,500`
  static String range(num low, num high) => '${rupees(low)} - ${rupees(high)}';

  /// Parses user input that may carry grouping separators or a ₹ prefix.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}
