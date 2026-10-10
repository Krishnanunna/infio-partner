import '../domain/partner_service.dart';
import '../domain/services_repository.dart';

/// The four catalogue entries from the service-manager design.
class MockServicesRepository implements ServicesRepository {
  MockServicesRepository() : _services = _seed();

  final List<PartnerService> _services;
  bool _catalogVisible = true;
  int _nextId = 5;

  static Duration get _latency => const Duration(milliseconds: 400);

  static List<PartnerService> _seed() => [
        const PartnerService(
          id: 'svc_1',
          name: 'Split AC Deep Cleaning / Jet Wash',
          description:
              'High-pressure chemical jet wash for indoor & outdoor unit.',
          categorySlug: 'ac_repair',
          categoryTag: 'AC Repair',
          price: 499,
          pricingType: PricingType.startingFrom,
          status: ServiceStatus.active,
          duration: '45 mins',
          subType: 'Split AC',
        ),
        const PartnerService(
          id: 'svc_2',
          name: 'Gas Leakage Detection & Refill',
          description:
              'Nitrogen pressure check, coil brazing & full cylinder gas refilling.',
          categorySlug: 'ac_repair',
          categoryTag: 'AC Repair',
          price: 1200,
          pricingType: PricingType.startingFrom,
          status: ServiceStatus.active,
          duration: '1 hr',
          subType: 'Gas Charging',
        ),
        const PartnerService(
          id: 'svc_3',
          name: 'AC Installation & Copper Piping',
          description:
              'Complete wall mounting bracket and high-grade insulated pipe.',
          categorySlug: 'ac_repair',
          categoryTag: 'Installation',
          price: 1500,
          pricingType: PricingType.startingFrom,
          status: ServiceStatus.paused,
          duration: '2+ hrs',
          subType: 'Split AC',
        ),
        const PartnerService(
          id: 'svc_4',
          name: 'PCB Board Circuit Repair',
          description:
              'Inverter and regular motherboard micro-soldering with warranty.',
          categorySlug: 'ac_repair',
          categoryTag: 'Diagnostics',
          price: 850,
          pricingType: PricingType.startingFrom,
          status: ServiceStatus.active,
          turnaround: 'Same Day',
          subType: 'PCB Diagnostics',
        ),
      ];

  @override
  Future<List<PartnerService>> fetchServices({
    String? categorySlug,
    String? query,
  }) async {
    await Future<void>.delayed(_latency);
    var result = _services.toList();

    if (categorySlug != null) {
      result = result.where((s) => s.categorySlug == categorySlug).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q))
          .toList();
    }
    return List.unmodifiable(result);
  }

  @override
  Future<PartnerService> createService(PartnerService service) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final created = PartnerService(
      id: 'svc_${_nextId++}',
      name: service.name,
      description: service.description,
      categorySlug: service.categorySlug,
      categoryTag: service.categoryTag,
      price: service.price,
      pricingType: service.pricingType,
      status: service.status,
      commissionPercent: service.commissionPercent,
      duration: service.duration,
      turnaround: service.turnaround,
      subType: service.subType,
      imagePath: service.imagePath,
    );
    _services.insert(0, created);
    return created;
  }

  @override
  Future<PartnerService> updateService(PartnerService service) async {
    await Future<void>.delayed(_latency);
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index == -1) throw StateError('Service ${service.id} not found');
    _services[index] = service;
    return service;
  }

  @override
  Future<PartnerService> setStatus(String id, ServiceStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) throw StateError('Service $id not found');
    final updated = _services[index].copyWith(status: status);
    _services[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteService(String id) async {
    await Future<void>.delayed(_latency);
    _services.removeWhere((s) => s.id == id);
  }

  @override
  Future<bool> fetchCatalogVisibility() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _catalogVisible;
  }

  @override
  Future<bool> setCatalogVisibility(bool visible) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _catalogVisible = visible;
    return _catalogVisible;
  }
}
