import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_22_gst_purpose.dart';

class HostScreen21Verification extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen21Verification({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen21Verification> createState() => _HostScreen21VerificationState();
}

class _HostScreen21VerificationState extends State<HostScreen21Verification> {
  late HostUpdatedPropertyDraft _draft;

  final String _individualOption = "i am a Individua's running business";
  final String _businessOption = "i represent a business";
  late String _selectedEntityMode;

  // Individual owners list
  final List<Map<String, TextEditingController>> _ownerControllers = [];

  // Business representative controllers
  late TextEditingController _businessFirstNameController;
  late TextEditingController _businessDobController;
  late TextEditingController _businessDesignationController;
  late TextEditingController _businessMobileController;
  late TextEditingController _businessEmailController;
  late TextEditingController _businessLegalNameController;
  String _selectedBusinessType = 'Select';

  final List<String> _businessTypes = const [
    'Select',
    'Sole Proprietorship',
    'Partnership',
    'Private Limited Company',
    'Limited Liability Partnership (LLP)',
    'Public Limited Company',
  ];

  final List<String> _designations = const [
    'Enter Location',
    'Owner / Proprietor',
    'Director',
    'Managing Partner',
    'General Manager',
    'Authorized Signatory',
  ];
  String _selectedDesignation = 'Enter Location';

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _selectedEntityMode = _draft.entityType == 'business'
        ? _businessOption
        : _individualOption;

    // Initialize individual owner controllers
    if (_draft.owners.isNotEmpty) {
      for (final owner in _draft.owners) {
        _ownerControllers.add({
          'firstName': TextEditingController(text: owner['firstName'] ?? ''),
          'lastName': TextEditingController(text: owner['lastName'] ?? ''),
          'dob': TextEditingController(text: owner['dob'] ?? ''),
        });
      }
    } else {
      _ownerControllers.add({
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'dob': TextEditingController(),
      });
    }

    // Initialize business controllers
    final rep = _draft.businessRep;
    _businessFirstNameController = TextEditingController(text: rep['firstName'] ?? '');
    _businessDobController = TextEditingController(text: rep['dob'] ?? '');
    _businessDesignationController = TextEditingController(text: rep['designation'] ?? '');
    _businessMobileController = TextEditingController(text: rep['mobile'] ?? '');
    _businessEmailController = TextEditingController(text: rep['email'] ?? '');
    _businessLegalNameController = TextEditingController(text: rep['legalName'] ?? '');
    if (rep['businessType'] != null && _businessTypes.contains(rep['businessType'])) {
      _selectedBusinessType = rep['businessType']!;
    }
    if (rep['designation'] != null && _designations.contains(rep['designation'])) {
      _selectedDesignation = rep['designation']!;
    }
  }

  @override
  void dispose() {
    for (final map in _ownerControllers) {
      map['firstName']?.dispose();
      map['lastName']?.dispose();
      map['dob']?.dispose();
    }
    _businessFirstNameController.dispose();
    _businessDobController.dispose();
    _businessDesignationController.dispose();
    _businessMobileController.dispose();
    _businessEmailController.dispose();
    _businessLegalNameController.dispose();
    super.dispose();
  }

  void _addOwner() {
    setState(() {
      _ownerControllers.add({
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'dob': TextEditingController(),
      });
    });
  }

  void _removeOwner(int index) {
    if (_ownerControllers.length > 1) {
      setState(() {
        final removed = _ownerControllers.removeAt(index);
        removed['firstName']?.dispose();
        removed['lastName']?.dispose();
        removed['dob']?.dispose();
      });
    }
  }

  void _onContinue() async {
    final isBusiness = _selectedEntityMode == _businessOption;

    final ownersData = _ownerControllers.map((ctrls) {
      return {
        'firstName': ctrls['firstName']?.text.trim() ?? '',
        'lastName': ctrls['lastName']?.text.trim() ?? '',
        'dob': ctrls['dob']?.text.trim() ?? '',
      };
    }).toList();

    final businessRepData = {
      'firstName': _businessFirstNameController.text.trim(),
      'dob': _businessDobController.text.trim(),
      'designation': _selectedDesignation != 'Enter Location'
          ? _selectedDesignation
          : _businessDesignationController.text.trim(),
      'mobile': _businessMobileController.text.trim(),
      'email': _businessEmailController.text.trim(),
      'legalName': _businessLegalNameController.text.trim(),
      'businessType': _selectedBusinessType != 'Select' ? _selectedBusinessType : '',
    };

    final updated = _draft.copyWith(
      entityType: isBusiness ? 'business' : 'individual',
      owners: ownersData,
      businessRep: businessRepData,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen22GstPurpose(draft: updated),
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
    final isIndividual = _selectedEntityMode == _individualOption;

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
              title: 'Verification',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Is the property owned by an individual or a business entity ?',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Entity Mode Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E2EC)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEntityMode,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF1E1E24),
                            size: 26,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1E1E24),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: _individualOption,
                              child: Text(_individualOption),
                            ),
                            DropdownMenuItem(
                              value: _businessOption,
                              child: Text(_businessOption),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedEntityMode = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields based on selection
                    if (isIndividual) ...[
                      Text(
                        'Please provide details of all individual who own 25% or more of property',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF555566),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      ..._ownerControllers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final ctrls = entry.value;
                        return _buildOwnerCard(index: idx, ctrls: ctrls);
                      }),

                      const SizedBox(height: 8),

                      // + Add another Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEAEAEA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _addOwner,
                          child: Text(
                            '+ Add another',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E24),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Business entity form (matching 5.png)
                      _buildTextField(
                        label: 'First Name',
                        hint: 'Enter Here',
                        controller: _businessFirstNameController,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Date of birth',
                        hint: 'Enter Location',
                        controller: _businessDobController,
                        onTap: () => _selectDate(context, _businessDobController),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      // Designation Dropdown
                      _buildDropdownField(
                        label: 'Designation',
                        value: _selectedDesignation,
                        items: _designations,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDesignation = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Mobile number',
                        hint: 'Enter',
                        controller: _businessMobileController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Email',
                        hint: 'Enter',
                        controller: _businessEmailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Legal name bussiness',
                        hint: 'Enter',
                        controller: _businessLegalNameController,
                      ),
                      const SizedBox(height: 16),

                      // Business Type Dropdown
                      _buildDropdownField(
                        label: 'Business Type',
                        value: _selectedBusinessType,
                        items: _businessTypes,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBusinessType = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 36),
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

  Widget _buildOwnerCard({
    required int index,
    required Map<String, TextEditingController> ctrls,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Co-owner ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E24),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeOwner(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _buildTextField(
            label: 'First Name',
            hint: 'Enter Here',
            controller: ctrls['firstName']!,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Last name',
            hint: 'Select type',
            controller: ctrls['lastName']!,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Date of birth',
            hint: 'Enter Location',
            controller: ctrls['dob']!,
            onTap: () => _selectDate(context, ctrls['dob']!),
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E1E24),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFFA0A0B0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E2EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E2EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5E42C2), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2EC)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1E1E24),
                size: 26,
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1E24),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5E42C2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1E24),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        controller.text = formatted;
      });
    }
  }
}
