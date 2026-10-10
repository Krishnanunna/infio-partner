import '../domain/lead.dart';
import '../domain/leads_repository.dart';

/// In-memory leads, seeded with the exact values from the Stitch designs so
/// the built screens match the renders.
class MockLeadsRepository implements LeadsRepository {
  MockLeadsRepository() : _leads = _seed();

  final List<Lead> _leads;

  static Duration get _latency => const Duration(milliseconds: 420);

  static List<Lead> _seed() {
    final now = DateTime.now();

    return [
      // The lead-detail record, ref #LD-8924.
      Lead(
        id: 'ld_8924',
        reference: 'LD-8924',
        customerName: 'John D.',
        customerVerified: true,
        customerPhone: '+91 98765 43210',
        serviceName: 'Split AC Repair & Maintenance',
        categorySlug: 'ac_repair',
        description:
            'Split AC not cooling, need gas refill and filter clean today. '
            'Outdoor unit vibrating slightly.',
        locality: 'Kukatpally, Hyderabad',
        fullAddress: 'Kukatpally Housing Board Colony, Phase 2, Hyderabad',
        distanceKm: 2.3,
        driveTime: 'Approx. 15 mins drive',
        budgetMin: 1200,
        budgetMax: 1200,
        budgetIsFixed: true,
        suggestedQuote: 1200,
        preferredSlot: 'Today, Evening (5:00 PM - 7:00 PM)',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.urgent,
        createdAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(minutes: 45)),
        photos: const [
          LeadPhoto(id: 'ph_1', caption: 'Unit 1'),
          LeadPhoto(id: 'ph_2', caption: 'Unit 2'),
        ],
        viewedByOtherPros: 3,
        matchRate: 'High Match Rate',
      ),

      // Inbox card 1 — the countdown variant.
      Lead(
        id: 'ld_8925',
        reference: 'LD-8925',
        customerName: 'Ramesh K.',
        customerVerified: true,
        customerPhone: '+91 90000 11111',
        serviceName: 'AC Repair & Gas Refill',
        categorySlug: 'ac_repair',
        description:
            'My split AC is not cooling properly since yesterday. Need someone '
            'to check the gas levels and clean the filters.',
        locality: 'Madhapur, Hyderabad',
        fullAddress: 'Madhapur, Hyderabad',
        distanceKm: 2.1,
        driveTime: 'Approx. 12 mins drive',
        budgetMin: 1000,
        budgetMax: 1500,
        suggestedQuote: 1250,
        preferredSlot: 'Today, Evening',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.urgent,
        createdAt: now.subtract(const Duration(minutes: 4)),
        expiresAt: now.add(const Duration(minutes: 12, seconds: 45)),
        viewedByOtherPros: 2,
        matchRate: 'High Match Rate',
      ),

      // Inbox card 2 — solid URGENT badge.
      Lead(
        id: 'ld_8926',
        reference: 'LD-8926',
        customerName: 'Pooja M.',
        customerPhone: '+91 90000 22222',
        serviceName: 'Water Heater Installation',
        categorySlug: 'appliance_care',
        description:
            'Brand new 15L geyser already delivered. Need certified technician '
            'for wall mounting and plumbing connection.',
        locality: 'Gachibowli, Hyderabad',
        fullAddress: 'Gachibowli, Hyderabad',
        distanceKm: 3.5,
        driveTime: 'Approx. 18 mins drive',
        budgetMin: 800,
        budgetMax: 1200,
        suggestedQuote: 1000,
        preferredSlot: 'Tomorrow, Morning',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.urgent,
        createdAt: now.subtract(const Duration(minutes: 25)),
        expiresAt: now.add(const Duration(minutes: 38)),
        viewedByOtherPros: 1,
      ),

      // Inbox card 3 — "Just now".
      Lead(
        id: 'ld_8927',
        reference: 'LD-8927',
        customerName: 'David R.',
        customerPhone: '+91 90000 33333',
        serviceName: 'Emergency Pipe Leakage',
        categorySlug: 'plumbing',
        description:
            'Main bathroom pipe is leaking under the basin cabinet, water is '
            'seeping through tiles. Need quick support.',
        locality: 'Kondapur, Hyderabad',
        fullAddress: 'Kondapur, Hyderabad',
        distanceKm: 1.4,
        driveTime: 'Approx. 8 mins drive',
        budgetMin: 1200,
        budgetMax: 1800,
        suggestedQuote: 1500,
        preferredSlot: 'Immediate (Urgent)',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.immediate,
        createdAt: now.subtract(const Duration(seconds: 20)),
        expiresAt: now.add(const Duration(minutes: 55)),
      ),

      // Dashboard preview card 1.
      Lead(
        id: 'ld_8928',
        reference: 'LD-8928',
        customerName: 'Sarah Jenkins',
        customerPhone: '+91 90000 44444',
        serviceName: 'Emergency Pipe Repair',
        categorySlug: 'plumbing',
        description:
            'Burst kitchen pipe causing active leakage. Water main shut off '
            'temporarily, need immediate visit within 2 hours.',
        locality: 'Jubilee Hills, Hyderabad',
        distanceKm: 1.8,
        budgetMin: 1200,
        budgetMax: 1500,
        suggestedQuote: 1350,
        preferredSlot: 'Immediate (Urgent)',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.urgent,
        createdAt: now.subtract(const Duration(minutes: 4)),
        expiresAt: now.add(const Duration(minutes: 50)),
      ),

      // Dashboard preview card 2.
      Lead(
        id: 'ld_8929',
        reference: 'LD-8929',
        customerName: 'David Ross',
        customerPhone: '+91 90000 55555',
        serviceName: 'Split AC Jet Service',
        categorySlug: 'ac_repair',
        description: 'Master bedroom AC cooling low, filter cleaning needed.',
        locality: 'Banjara Hills, Hyderabad',
        distanceKm: 3.2,
        budgetMin: 850,
        budgetMax: 850,
        budgetIsFixed: true,
        suggestedQuote: 850,
        preferredSlot: 'Tomorrow, Morning',
        status: LeadStatus.newLead,
        urgency: LeadUrgency.standard,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),

      // Contacted bucket.
      Lead(
        id: 'ld_8910',
        reference: 'LD-8910',
        customerName: 'Anil T.',
        customerPhone: '+91 90000 66666',
        contactRevealed: true,
        serviceName: 'Inverter AC Installation',
        categorySlug: 'ac_repair',
        description: 'Need installation for a new 1.5 ton inverter split AC.',
        locality: 'Miyapur, Hyderabad',
        distanceKm: 4.6,
        budgetMin: 1500,
        budgetMax: 2000,
        preferredSlot: 'Tomorrow, Afternoon',
        status: LeadStatus.contacted,
        urgency: LeadUrgency.standard,
        createdAt: now.subtract(const Duration(hours: 5)),
        quotedAmount: 1750,
      ),

      // Missed bucket.
      Lead(
        id: 'ld_8901',
        reference: 'LD-8901',
        customerName: 'Meera S.',
        serviceName: 'PCB Board Repair',
        categorySlug: 'ac_repair',
        description: 'Indoor unit display not responding, suspect board issue.',
        locality: 'Ameerpet, Hyderabad',
        distanceKm: 6.1,
        budgetMin: 700,
        budgetMax: 1100,
        preferredSlot: 'Yesterday, Evening',
        status: LeadStatus.missed,
        urgency: LeadUrgency.standard,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }

  @override
  Future<List<Lead>> fetchLeads({LeadStatus? status, int page = 1}) async {
    await Future<void>.delayed(_latency);
    final filtered = status == null
        ? _leads
        : _leads.where((l) => l.status == status).toList();
    return List.unmodifiable(
      filtered..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<Lead> fetchLead(String id) async {
    await Future<void>.delayed(_latency);
    return _leads.firstWhere(
      (l) => l.id == id,
      orElse: () => throw StateError('Lead $id not found'),
    );
  }

  @override
  Future<LeadInboxSummary> fetchSummary() async {
    await Future<void>.delayed(_latency);
    return LeadInboxSummary(
      todayCount: 12,
      urgentCount: 3,
      averageResponse: '4 mins',
      matchRate: '98%',
      counts: {
        LeadStatus.newLead: 12,
        LeadStatus.contacted: 5,
        LeadStatus.missed: 2,
      },
    );
  }

  @override
  Future<Lead> acceptLead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return _mutate(
      id,
      (lead) => lead.copyWith(
        status: LeadStatus.accepted,
        contactRevealed: true,
      ),
    );
  }

  @override
  Future<Lead> declineLead(String id, {String? reason}) async {
    await Future<void>.delayed(_latency);
    return _mutate(id, (lead) => lead.copyWith(status: LeadStatus.declined));
  }

  @override
  Future<Lead> submitQuote(
    String id, {
    required int amount,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _mutate(
      id,
      (lead) => lead.copyWith(
        status: LeadStatus.quoted,
        quotedAmount: amount,
      ),
    );
  }

  Lead _mutate(String id, Lead Function(Lead) transform) {
    final index = _leads.indexWhere((l) => l.id == id);
    if (index == -1) throw StateError('Lead $id not found');
    final updated = transform(_leads[index]);
    _leads[index] = updated;
    return updated;
  }
}
