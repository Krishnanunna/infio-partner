import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../../../core/di/value_provider.dart';
import '../domain/partner_service.dart';

/// The active category filter pill. Null means "All".
final serviceCategoryFilterProvider = valueProvider<String?>(null);

/// The catalogue search query.
final serviceQueryProvider = valueProvider<String>('');

/// Every service, unfiltered — used to derive the filter pill counts.
final allServicesProvider = FutureProvider<List<PartnerService>>((ref) {
  return ref.watch(servicesRepositoryProvider).fetchServices();
});

/// The filtered list the manager renders.
final filteredServicesProvider =
    FutureProvider<List<PartnerService>>((ref) async {
  final category = ref.watch(serviceCategoryFilterProvider);
  final query = ref.watch(serviceQueryProvider);

  return ref.watch(servicesRepositoryProvider).fetchServices(
        categorySlug: category,
        query: query,
      );
});

final catalogVisibilityProvider =
    AsyncNotifierProvider<CatalogVisibilityController, bool>(
  CatalogVisibilityController.new,
);

class CatalogVisibilityController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(servicesRepositoryProvider).fetchCatalogVisibility();
  }

  Future<void> toggle() async {
    final next = !(state.value ?? true);
    state = AsyncValue.data(next);
    await ref.read(servicesRepositoryProvider).setCatalogVisibility(next);
  }
}

/// Mutations that keep both list providers in sync.
class ServiceActions {
  ServiceActions(this._ref);

  final Ref _ref;

  Future<void> setStatus(String id, ServiceStatus status) async {
    await _ref.read(servicesRepositoryProvider).setStatus(id, status);
    _invalidate();
  }

  Future<PartnerService> create(PartnerService service) async {
    final created =
        await _ref.read(servicesRepositoryProvider).createService(service);
    _invalidate();
    return created;
  }

  Future<void> delete(String id) async {
    await _ref.read(servicesRepositoryProvider).deleteService(id);
    _invalidate();
  }

  void _invalidate() {
    _ref.invalidate(allServicesProvider);
    _ref.invalidate(filteredServicesProvider);
  }
}

final serviceActionsProvider = Provider<ServiceActions>(ServiceActions.new);
