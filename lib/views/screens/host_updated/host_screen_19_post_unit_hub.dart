import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_17_unit_details.dart';
import 'host_screen_20_invoicing.dart';
import 'host_event_screen_11_event_types.dart';
import 'host_screen_15_accommodation_rooms.dart';

class HostScreen19PostUnitHub extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen19PostUnitHub({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen19PostUnitHub> createState() => _HostScreen19PostUnitHubState();
}

class _HostScreen19PostUnitHubState extends State<HostScreen19PostUnitHub> {
  late HostUpdatedPropertyDraft _draft;

  // Step 1 Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _facilitiesController;
  late TextEditingController _othersController;

  // Step 2 Controllers (Configured Unit)
  late TextEditingController _unitRoomTypeController;
  late TextEditingController _unitGuestsController;
  late TextEditingController _unitBedController;
  late TextEditingController _unitBathController;
  late TextEditingController _unitPriceController;
  late TextEditingController _unitCategoryController;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _initControllers();
  }

  void _initControllers() {
    // Step 1 Details
    _nameController = TextEditingController(
      text: _draft.propertyName.isNotEmpty ? _draft.propertyName : 'The Blue Hotel & Suites',
    );

    final addressStr = [
      if (_draft.hNo.isNotEmpty) _draft.hNo,
      if (_draft.street.isNotEmpty) _draft.street,
      if (_draft.city.isNotEmpty) _draft.city,
      if (_draft.postalCode.isNotEmpty) _draft.postalCode,
    ].join(', ');
    _addressController = TextEditingController(
      text: addressStr.isNotEmpty ? addressStr : 'Plot 42, Hitech City Main Road, Hyderabad',
    );

    final facilitiesStr = _draft.facilities.isNotEmpty
        ? _draft.facilities.take(4).join(', ') + (_draft.facilities.length > 4 ? ' +${_draft.facilities.length - 4} more' : '')
        : 'Wifi, AC, Pool, Lift, Garden';
    _facilitiesController = TextEditingController(text: facilitiesStr);

    final petStr = _draft.allowsPets == 'yes'
        ? 'Pets allowed'
        : (_draft.allowsPets == 'upon_request' ? 'Pets on request' : 'No pets');
    final breakfastStr = _draft.servesBreakfast ? 'Breakfast served' : 'No breakfast';
    _othersController = TextEditingController(text: '$breakfastStr • $petStr');

    // Step 2 Details (First Unit)
    final unit = _draft.units.isNotEmpty ? _draft.units.first : <String, dynamic>{};
    _unitRoomTypeController = TextEditingController(
      text: unit['unitType']?.toString().isNotEmpty == true
          ? unit['unitType'].toString()
          : 'Double',
    );
    _unitGuestsController = TextEditingController(
      text: unit['guests']?.toString().isNotEmpty == true
          ? unit['guests'].toString()
          : '2 Guests',
    );
    _unitBedController = TextEditingController(
      text: unit['bedSummary']?.toString().isNotEmpty == true
          ? unit['bedSummary'].toString()
          : (unit['beds'] != null ? '${unit['beds']} beds' : '1 extra large double bed'),
    );
    _unitBathController = TextEditingController(
      text: unit['bathrooms']?.toString().isNotEmpty == true
          ? '${unit['bathrooms']} Bathroom'
          : '1 Bathroom',
    );
    _unitPriceController = TextEditingController(
      text: unit['basePrice']?.toString().isNotEmpty == true
          ? '₹ ${unit['basePrice']} / night'
          : '₹ 2,500 / night',
    );
    _unitCategoryController = TextEditingController(
      text: unit['purpose']?.toString().isNotEmpty == true
          ? unit['purpose'].toString()
          : 'Stay / Accomadation',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _facilitiesController.dispose();
    _othersController.dispose();
    _unitRoomTypeController.dispose();
    _unitGuestsController.dispose();
    _unitBedController.dispose();
    _unitBathController.dispose();
    _unitPriceController.dispose();
    _unitCategoryController.dispose();
    super.dispose();
  }

  void _onEditUnit() async {
    final unit = _draft.units.isNotEmpty ? _draft.units.first : <String, dynamic>{};
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen17UnitDetails(
          draft: _draft,
          currentUnit: unit,
        ),
      ),
    );
    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
        _initControllers();
      });
    }
  }

  void _onDeleteUnit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Unit',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove this unit configuration?',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF555566)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _draft = _draft.copyWith(units: []);
                _initControllers();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unit removed.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onAddAnotherUnit() async {
    final selected = await showAddUnitTypeSelectionDialog(context);
    if (!mounted) return;
    if (selected == 'stay') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostScreen15AccommodationRooms(draft: _draft),
        ),
      );
      if (result != null && result is HostUpdatedPropertyDraft && mounted) {
        setState(() {
          _draft = result;
          _initControllers();
        });
      }
    } else if (selected == 'event') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostEventScreen11EventTypes(draft: _draft),
        ),
      );
      if (result != null && result is HostUpdatedPropertyDraft && mounted) {
        setState(() {
          _draft = result;
          _initControllers();
        });
      }
    }
  }

  void _onEditEventUnit(int index) async {
    final unit = _draft.units[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen11EventTypes(
          draft: _draft,
          initialEventData: unit,
        ),
      ),
    );
    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
        _initControllers();
      });
    }
  }

  void _onDeleteEventUnit(int index) {
    setState(() {
      final updated = List<Map<String, dynamic>>.from(_draft.units)..removeAt(index);
      _draft = _draft.copyWith(units: updated);
      _initControllers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event unit removed.')),
    );
  }

  void _onAddFinalDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen20Invoicing(draft: _draft),
      ),
    );
    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
          children: [
            HostTopBar(
              title: '',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1 Header
                    Text(
                      'Step 1',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Property Details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6E6E82),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryField(label: 'Name', controller: _nameController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Address', controller: _addressController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Facilities', controller: _facilitiesController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Others', controller: _othersController),
                    const SizedBox(height: 16),

                    // Step 1 Edit Button (full width gray pill matching 2.png)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E5EA),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, _draft),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Step 2 Header
                    Text(
                      'Step 2',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room layouts, bed options and rate.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6E6E82),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Render Unit 1 (Stay Unit)
                    Text(
                      'Unit 1 (Accommodations)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5E42C2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryField(label: 'Room Type', controller: _unitRoomTypeController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Guests', controller: _unitGuestsController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Bed', controller: _unitBedController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Bathrooms', controller: _unitBathController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Price', controller: _unitPriceController),
                    const SizedBox(height: 14),
                    _buildSummaryField(label: 'Category', controller: _unitCategoryController),
                    const SizedBox(height: 18),

                    // Unit 1 Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E5EA),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _onEditUnit,
                              child: Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E5EA),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _onDeleteUnit,
                              child: Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E5EA),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _onAddAnotherUnit,
                              child: Text(
                                'ADD',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional Event Units (e.g. Unit 2)
                    ..._draft.units.asMap().entries.where((e) => e.key > 0).map((entry) {
                      final idx = entry.key;
                      final u = entry.value;
                      final isEvent = u['purpose'] == 'Events Booking' || u['venueType'] != null;

                      return Container(
                        margin: const EdgeInsets.only(top: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit ${idx + 1} (${isEvent ? 'Events Booking' : 'Accommodations'})',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E42C2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSummaryFieldStatic(
                              label: 'Venue Type',
                              value: u['venueType']?.toString() ?? 'Banquet Hall',
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryFieldStatic(
                              label: 'Capacity',
                              value: '${u['seatingCapacity'] ?? '2,000'} Seating | ${u['hallCapacity'] ?? '3,000'} Floating',
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryFieldStatic(
                              label: 'Stage & Dining',
                              value: 'Stage: ${(u['stageLocations'] as List?)?.join(', ') ?? 'Fixed indoor'}\nDining: ${u['diningCapacity'] ?? '1,000 guests'}',
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryFieldStatic(
                              label: 'Price',
                              value: '₹ ${u['basePrice'] ?? '1,50,000'} / event',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE5E5EA),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _onEditEventUnit(idx),
                                      child: Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E1E24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE5E5EA),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _onDeleteEventUnit(idx),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E1E24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE5E5EA),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _onAddAnotherUnit,
                                      child: Text(
                                        'ADD',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E1E24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 28),

                    // Step 3 Header
                    Text(
                      'Step 3',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Setup Payment & invoice for bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6E6E82),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add final Details Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E5EA),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _onAddFinalDetails,
                        child: Text(
                          'Add final Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E2EC)),
          ),
          child: Text(
            controller.text.isNotEmpty ? controller.text : 'Enter Here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: controller.text.isNotEmpty ? const Color(0xFF333340) : const Color(0xFFA0A0B0),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryFieldStatic({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E2EC)),
          ),
          child: Text(
            value.isNotEmpty ? value : 'Enter Here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF333340),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
