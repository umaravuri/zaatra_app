import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_16_unit_type.dart';
import 'host_screen_15_accommodation_rooms.dart';

class HostScreen15PropertyHub extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen15PropertyHub({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen15PropertyHub> createState() => _HostScreen15PropertyHubState();
}

class _HostScreen15PropertyHubState extends State<HostScreen15PropertyHub> {
  late HostUpdatedPropertyDraft _draft;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _facilitiesController;
  late TextEditingController _othersController;

  final List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
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

    final petStr = _draft.allowsPets == 'yes' ? 'Pets allowed' : (_draft.allowsPets == 'upon_request' ? 'Pets on request' : 'No pets');
    final breakfastStr = _draft.servesBreakfast ? 'Breakfast served' : 'No breakfast';
    _othersController = TextEditingController(text: '$breakfastStr • $petStr');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _facilitiesController.dispose();
    _othersController.dispose();
    super.dispose();
  }


  void _onAddUnitTapped() async {
    final updated = _draft.copyWith(
      propertyName: _nameController.text.trim(),
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen15AccommodationRooms(draft: updated),
      ),
    );
    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
      });
    }
  }

  void _navigateToScreen16() async {
    final updated = _draft.copyWith(
      propertyName: _nameController.text.trim(),
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen16UnitType(draft: updated),
      ),
    );
    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
      });
    }
  }

  void _showAddPayoutDialog() {
    final upiController = TextEditingController(text: 'host@okhdfcbank');
    final ifscController = TextEditingController(text: 'HDFC0001234');
    final accController = TextEditingController(text: '50100234567890');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Payout Details',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: upiController,
              decoration: const InputDecoration(labelText: 'UPI ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accController,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ifscController,
              decoration: const InputDecoration(labelText: 'IFSC Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E42C2)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout details configured successfully!')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              title: 'Property Setup Hub',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Step 1',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    Text(
                      'Property Details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757585),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldSection(label: 'Name', controller: _nameController, hint: 'Enter Here'),
                    const SizedBox(height: 14),
                    _buildFieldSection(label: 'Address', controller: _addressController, hint: 'Select type'),
                    const SizedBox(height: 14),
                    _buildFieldSection(label: 'Facilities', controller: _facilitiesController, hint: 'Enter Location'),
                    const SizedBox(height: 14),
                    _buildFieldSection(label: 'Others', controller: _othersController, hint: 'Enter price'),
                    const SizedBox(height: 24),

                    // Step 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 2',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E24),
                              ),
                            ),
                            Text(
                              'Units',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF757585),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _onAddUnitTapped,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E42C2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Unit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E4ED)),
                      ),
                      child: _units.isEmpty
                          ? Text(
                              'Tell Us about your units',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFFA0A0B2),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _units.map((u) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${u['type']} (${u['quantity']} units)',
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '₹${u['price']} / night',
                                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF5E42C2), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Step 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 3',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E24),
                              ),
                            ),
                            Text(
                              'Final Step',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF757585),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _showAddPayoutDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E42C2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E4ED)),
                      ),
                      child: Text(
                        'Set up payments and invoicing for bookings.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFFA0A0B2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: HostBottomButton(
                text: 'Complete & Publish Listing',
                onPressed: _navigateToScreen16,
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSection({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E1E24),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E4ED)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1E1E24),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFA0A0B2),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
