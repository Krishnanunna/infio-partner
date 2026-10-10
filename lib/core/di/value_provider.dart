import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A minimal mutable-value provider.
///
/// Riverpod 3 moved `StateProvider` to the legacy export. This is the
/// modern equivalent for the handful of places that hold one plain value:
/// a selected tab, a filter, a billing cycle.
///
/// ```dart
/// final tabProvider = valueProvider(LeadStatus.newLead);
///
/// ref.watch(tabProvider);                    // read
/// ref.read(tabProvider.notifier).set(next);  // write
/// ```
class ValueController<T> extends Notifier<T> {
  ValueController(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;

  void update(T Function(T current) transform) => state = transform(state);
}

NotifierProvider<ValueController<T>, T> valueProvider<T>(T initial) {
  return NotifierProvider<ValueController<T>, T>(
    () => ValueController<T>(initial),
  );
}
