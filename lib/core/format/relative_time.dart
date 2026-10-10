/// Relative timestamps in the style the designs use: "4 mins ago", "2h ago",
/// "1d ago", "Just now".
abstract final class RelativeTime {
  static String format(DateTime when, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final delta = reference.difference(when);

    if (delta.inSeconds < 45) return 'Just now';
    if (delta.inMinutes < 60) {
      final m = delta.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';

    final weeks = delta.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w ago';
    return '${delta.inDays ~/ 30}mo ago';
  }

  /// Countdown rendered as `mm:ss`, used on the lead expiry badge.
  static String countdown(Duration remaining) {
    if (remaining.isNegative) return '00:00';
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
