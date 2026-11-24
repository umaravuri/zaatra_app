import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import '../../../core/utils/host_validators.dart';
import 'widgets/host_components.dart';
import 'host_screen_9_channel_manager.dart';

/// Figma: frame 1228744503 (node 1:1041)
class HostScreen8LocationMap extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen8LocationMap({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen8LocationMap> createState() => _HostScreen8LocationMapState();
}

class _HostScreen8LocationMapState extends State<HostScreen8LocationMap> {
  late HostUpdatedPropertyDraft _draft;
  late TextEditingController _locationController;
  late TextEditingController _hNoController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  String _selectedCountry = 'INDIA';
  bool _updateAddressWithPin = true;
  double _lat = 17.4486;
  double _lng = 78.3908;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _locationController = TextEditingController(text: _draft.locationInput);
    _hNoController = TextEditingController(text: _draft.hNo);
    _streetController = TextEditingController(text: _draft.street);
    _cityController = TextEditingController(text: _draft.city);
    _postalCodeController = TextEditingController(text: _draft.postalCode);
    _selectedCountry = _draft.country.isNotEmpty ? _draft.country : 'INDIA';
    _updateAddressWithPin = _draft.updateAddressWithPin;
    _lat = _draft.latitude;
    _lng = _draft.longitude;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _hNoController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    final error = HostValidators.required(_streetController.text, 'Street name') ??
        HostValidators.required(_cityController.text, 'City') ??
        HostValidators.postalCode(_postalCodeController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final updated = _draft.copyWith(
      locationInput: _locationController.text.trim(),
      hNo: _hNoController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _selectedCountry,
      updateAddressWithPin: _updateAddressWithPin,
      latitude: _lat,
      longitude: _lng,
    );

    // Save Step 5 asynchronously
    HostApiService.saveWizardStep(
      step: 5,
      propertyId: updated.propertyId,
      payload: {
        'location': updated.locationInput,
        'latitude': updated.latitude,
        'longitude': updated.longitude,
        'flatNo': updated.hNo,
        'street': updated.street,
        'city': updated.city,
        'postalCode': updated.postalCode,
        'country': updated.country,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen9ChannelManager(draft: updated),
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
              title: 'What is your property?',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildFieldLabel('Enter your location'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _locationController,
                      hintText: 'Enter your location',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757585), size: 20),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Select on google maps'),
                    const SizedBox(height: 8),
                    _buildMapSelector(),
                    const SizedBox(height: 16),
                    _buildFieldLabel('H. No/ Flat No'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _hNoController,
                      hintText: 'Enter Here',
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Street Name/ Colony'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _streetController,
                      hintText: 'Select type',
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('City'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cityController,
                      hintText: 'Enter Location',
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Postal / Zip Code'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _postalCodeController,
                      hintText: 'Enter price',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Country'),
                    const SizedBox(height: 8),
                    _buildCountryDropdown(),
                    const SizedBox(height: 16),
                    _buildPinSyncCheckbox(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: HostBottomButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E1E24),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E4ED)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF1E1E24),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: prefixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFA0A0B2),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E4ED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757585)),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E1E24),
          ),
          items: const [
            DropdownMenuItem(value: 'INDIA', child: Text('INDIA')),
            DropdownMenuItem(value: 'UNITED STATES', child: Text('UNITED STATES')),
            DropdownMenuItem(value: 'UNITED KINGDOM', child: Text('UNITED KINGDOM')),
            DropdownMenuItem(value: 'UAE', child: Text('UAE')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCountry = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPinSyncCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _updateAddressWithPin = !_updateAddressWithPin;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _updateAddressWithPin ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _updateAddressWithPin ? const Color(0xFF2E7D32) : const Color(0xFFA0A0B2),
                  width: 1.5,
                ),
              ),
              child: _updateAddressWithPin
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update the address when moving the pin on the google map',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF555566),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E4ED)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Styled stylized map lines
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _StylizedMapPainter(),
            ),
            // Pin marker with pulse
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Work',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Map controls overlay
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _lat += 0.001;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.add, size: 18, color: Color(0xFF555566)),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E4ED)),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _lat -= 0.001;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.remove, size: 18, color: Color(0xFF555566)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Landmark label
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Raiffeisen Bank • DOROBANTI',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF555566),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StylizedMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFF1F5ED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final greenParkPaint = Paint()..color = const Color(0xFFD4E7C5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, 10, size.width * 0.3, 70),
        const Radius.circular(8),
      ),
      greenParkPaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Road 1: diagonal
    final path1 = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.45, size.height * 0.5)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path1, roadBorderPaint);
    canvas.drawPath(path1, roadPaint);

    // Road 2: vertical cross
    final path2 = Path()
      ..moveTo(size.width * 0.55, size.height)
      ..lineTo(size.width * 0.52, 0);

    canvas.drawPath(path2, roadBorderPaint);
    canvas.drawPath(path2, roadPaint);

    // Road 3: horizontal
    final path3 = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.65);

    canvas.drawPath(path3, roadBorderPaint);
    canvas.drawPath(path3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


********************************************************************************
================================================================================
