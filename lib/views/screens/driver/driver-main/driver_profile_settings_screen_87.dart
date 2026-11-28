import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/driver_service.dart';
import '../../authorization/login_screen_115.dart';
import '../../authorization/otp_verification_screen_26.dart';
import 'driver_earnings_history_screen_82.dart';
import 'driver_edit_profile_screen.dart';
import 'driver_ratings_reviews_screen_113.dart';
import 'driver_support_help_screen_86.dart';

class DriverProfileSettingsScreen extends StatefulWidget {
  const DriverProfileSettingsScreen({super.key});

  @override
  State<DriverProfileSettingsScreen> createState() => _DriverProfileSettingsScreenState();
}

class _DriverProfileSettingsScreenState extends State<DriverProfileSettingsScreen> {
  String _driverName = '-';
  String _driverPhone = '-';
  String _driverEmail = '-';
  String _rating = '-';
  String _vehicleName = '-';
  String _vehicleMake = '-';
  String _vehicleModel = '-';
  String _vehicleType = '-';
  String _vehiclePlate = '-';
  String _fuelType = '-';
  String? _rcDocumentUrl;
  String? _insuranceDocumentUrl;
  String _licenseNumber = '-';
  String _licenseType = '-';
  String _licenseValidity = '-';
  String _licenseStatus = '-';
  String _accountHolder = '-';
  String _bankName = '-';
  String _accountNumber = '-';
  String _ifscCode = '-';
  String _payoutStatus = '-';
  String _city = '-';
  String _statusText = '-';
  Uint8List? _avatarBytes;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  bool _matchesCurrentPhone(dynamic phoneVal, String cleanDigits) {
    if (phoneVal == null || cleanDigits.isEmpty) return false;
    final digits = phoneVal.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    return digits == cleanDigits ||
        (digits.length >= 10 && cleanDigits.length >= 10 && digits.endsWith(cleanDigits));
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');

      if (currentPhone.isNotEmpty) {
        _driverPhone = currentPhone;
      }
      final savedName = prefs.getString('user_name_$cleanDigits') ?? prefs.getString('currentUserName') ?? '';
      if (savedName.isNotEmpty) {
        _driverName = savedName;
        _accountHolder = savedName;
      }

      final savedAvatar = prefs.getString('driver_avatar_base64_$cleanDigits');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        try {
          _avatarBytes = base64Decode(savedAvatar);
        } catch (_) {}
      }
      final savedPhotoUrl = prefs.getString('driver_photo_url_$cleanDigits') ??
          prefs.getString('driver_photo_url');
      if (savedPhotoUrl != null && savedPhotoUrl.isNotEmpty) {
        _avatarUrl = savedPhotoUrl;
      }

      _vehicleName = prefs.getString('driver_vehicle_$cleanDigits') ?? 
                     prefs.getString('driver_vehicle_name_$cleanDigits') ?? '-';
      _vehicleMake = prefs.getString('driver_vehicle_make_$cleanDigits') ?? '-';
      _vehicleModel = prefs.getString('driver_vehicle_model_$cleanDigits') ?? '-';
      _vehicleType = prefs.getString('driver_vehicle_type_$cleanDigits') ?? '-';
      _vehiclePlate = prefs.getString('driver_vehicle_plate_$cleanDigits') ?? '-';
      _fuelType = prefs.getString('driver_vehicle_fuel_$cleanDigits') ?? '-';
      _licenseNumber = prefs.getString('driver_license_$cleanDigits') ?? '-';
      _city = prefs.getString('driver_city_$cleanDigits') ?? '-';

      // 1. Fetch live Personal Info (GET /api/drivers/profile/personal)
      try {
        final personalRes = await DriverService.getPersonalInfo(phone: currentPhone);
        if (personalRes['success'] == true) {
          final p = personalRes['personalInformation'] ?? personalRes['data'] ?? personalRes;
          if (p is Map) {
            final pPhone = p['phoneNumber'] ?? p['phone'] ?? p['mobileNumber'];
            final bool pMatches = cleanDigits.isEmpty || (pPhone != null && _matchesCurrentPhone(pPhone, cleanDigits));
            final bool isMadhavSeed = (p['fullName']?.toString().toLowerCase() == 'madhav' || 
                                       p['name']?.toString().toLowerCase() == 'madhav') && 
                                       cleanDigits != '7417417417';

            if (pMatches && !isMadhavSeed) {
              if (p['fullName'] != null && p['fullName'].toString().isNotEmpty) {
                _driverName = p['fullName'].toString();
                _accountHolder = _driverName;
              }
              if (p['phoneNumber'] != null && p['phoneNumber'].toString().isNotEmpty) {
                _driverPhone = p['phoneNumber'].toString();
              }
              if (p['email'] != null && p['email'].toString().isNotEmpty) {
                _driverEmail = p['email'].toString();
              }
              if (p['city'] != null && p['city'].toString().isNotEmpty) {
                _city = p['city'].toString();
              }
              if (p['status'] != null) {
                _statusText = p['status'].toString();
              }
              final pPhoto = p['avatarUrl'] ?? p['driverPhotoUrl'] ?? p['driverPhoto'] ?? p['avatar'] ?? p['photo'];
              if (pPhoto != null && pPhoto.toString().trim().isNotEmpty) {
                _avatarUrl = pPhoto.toString().trim();
              }
            }
          }
        }
      } catch (_) {}

      // 2. Fetch live Vehicle Info (GET /api/drivers/profile/vehicle)
      try {
        final vehRes = await DriverService.getVehicleInfo(phone: currentPhone);
        if (vehRes['success'] == true) {
          final v = vehRes['vehicleInformation'] ?? vehRes['data'] ?? vehRes;
          if (v is Map) {
            final vPhone = v['phone'] ?? v['phoneNumber'];
            final bool vMatches = cleanDigits.isNotEmpty && vPhone != null && _matchesCurrentPhone(vPhone, cleanDigits);
            if (vMatches) {
              final rawName = v['vehicleName']?.toString() ?? '';
              final rawMake = v['vehicleMake']?.toString() ?? '';
              if (!rawName.toLowerCase().contains('merced') && !rawName.toLowerCase().contains('benz')) {
                _vehicleName = rawName.isNotEmpty ? rawName : '-';
              }
              if (!rawMake.toLowerCase().contains('merced') && !rawMake.toLowerCase().contains('benz')) {
                _vehicleMake = rawMake.isNotEmpty ? rawMake : '-';
              }
              if (v['vehicleModel'] != null) _vehicleModel = v['vehicleModel'].toString();
              if (v['vehicleType'] != null) _vehicleType = v['vehicleType'].toString();
              if (v['vehicleNumberPlate'] != null) _vehiclePlate = v['vehicleNumberPlate'].toString();
              if (v['fuelType'] != null) _fuelType = v['fuelType'].toString();
              final rcDoc = v['rcDocumentUrl'] ?? v['rcDocument'] ?? v['rcUrl'] ?? v['rc'];
              if (rcDoc != null && rcDoc.toString().trim().isNotEmpty) {
                _rcDocumentUrl = rcDoc.toString().trim();
              }
              final insDoc = v['insuranceDocumentUrl'] ?? v['insuranceDocument'] ?? v['insuranceUrl'] ?? v['insurance'];
              if (insDoc != null && insDoc.toString().trim().isNotEmpty) {
                _insuranceDocumentUrl = insDoc.toString().trim();
              }
            }
          }
        }
      } catch (_) {}

      // 3. Fetch live Driving License (GET /api/drivers/profile/license)
      try {
        final licRes = await DriverService.getDrivingLicenseInfo(phone: currentPhone);
        if (licRes['success'] == true) {
          final l = licRes['licenseInformation'] ?? licRes['data'] ?? licRes;
          if (l is Map) {
            final lPhone = l['phone'] ?? l['phoneNumber'];
            final bool lMatches = cleanDigits.isEmpty || lPhone == null || _matchesCurrentPhone(lPhone, cleanDigits);
            if (lMatches) {
              if (l['licenseNumber'] != null) _licenseNumber = l['licenseNumber'].toString();
              if (l['licenseType'] != null) _licenseType = l['licenseType'].toString();
              if (l['validity'] != null) _licenseValidity = l['validity'].toString();
              if (l['status'] != null) _licenseStatus = l['status'].toString();
            }
          }
        }
      } catch (_) {}

      // 4. Fetch live Bank Account (GET /api/drivers/profile/bank)
      try {
        final bankRes = await DriverService.getBankAccountInfo(phone: currentPhone);
        if (bankRes['success'] == true) {
          final b = bankRes['bankInformation'] ?? bankRes['data'] ?? bankRes;
          if (b is Map) {
            final bPhone = b['phone'] ?? b['phoneNumber'];
            final bool bMatches = cleanDigits.isEmpty || bPhone == null || _matchesCurrentPhone(bPhone, cleanDigits);
            if (bMatches) {
              if (b['accountHolder'] != null) _accountHolder = b['accountHolder'].toString();
              if (b['bankName'] != null) _bankName = b['bankName'].toString();
              if (b['accountNumber'] != null) _accountNumber = b['accountNumber'].toString();
              if (b['ifscCode'] != null) _ifscCode = b['ifscCode'].toString();
              if (b['payoutStatus'] != null) _payoutStatus = b['payoutStatus'].toString();
            }
          }
        }
      } catch (_) {}

      // 5. Fetch live Dashboard Summary (GET /api/drivers/dashboard-summary)
      try {
        final summary = await DriverService.getDashboardSummary(phone: currentPhone);
        if (summary['success'] == true) {
          final summaryProfile = summary['driverProfile'] is Map ? (summary['driverProfile'] as Map) : null;
          final sumPhone = summaryProfile?['phone'] ?? summaryProfile?['phoneNumber'] ?? summary['phone'];
          final String? sumDriverId = summary['driverId']?.toString() ?? summaryProfile?['driverId']?.toString();
          final bool isMadhavSeed = (sumDriverId == 'D-101' || 
                                     summaryProfile?['name']?.toString().toLowerCase() == 'madhav') && 
                                     cleanDigits != '7417417417';
          final bool sumMatches = !isMadhavSeed && 
              (cleanDigits.isEmpty || sumPhone == null || _matchesCurrentPhone(sumPhone, cleanDigits));

          if (sumMatches && summaryProfile != null) {
            if (summaryProfile['name'] != null && summaryProfile['name'].toString().isNotEmpty) {
              _driverName = summaryProfile['name'].toString();
            }
            if (summaryProfile['email'] != null && summaryProfile['email'].toString().isNotEmpty) {
              _driverEmail = summaryProfile['email'].toString();
            }
            if (summaryProfile['phone'] != null && summaryProfile['phone'].toString().isNotEmpty) {
              _driverPhone = summaryProfile['phone'].toString();
            }
            final sumPhoto = summaryProfile['avatarUrl'] ??
                summaryProfile['driverPhotoUrl'] ??
                summaryProfile['driverPhoto'] ??
                summaryProfile['avatar'] ??
                summaryProfile['photo'];
            if (sumPhoto != null && sumPhoto.toString().trim().isNotEmpty) {
              _avatarUrl = sumPhoto.toString().trim();
            }
            if (summary['stats'] is Map && summary['stats']['ratings'] != null) {
              _rating = summary['stats']['ratings'].toString();
            }
          }
        }
      } catch (_) {}

      // 6. Fetch driver approval status if available
      try {
        final status = await DriverService.getDriverApprovalStatus(phone: currentPhone);
        if (status['success'] == true && status['driver'] is Map) {
          final d = status['driver'] as Map;
          final dPhone = d['phone'] ?? d['phoneNumber'];
          final bool dMatches = cleanDigits.isEmpty || (dPhone != null && _matchesCurrentPhone(dPhone, cleanDigits));
          final bool isMadhavSeed = (d['name']?.toString().toLowerCase() == 'madhav') && cleanDigits != '7417417417';

          if (dMatches && !isMadhavSeed) {
            if (d['name'] != null && d['name'].toString().isNotEmpty) {
              _driverName = d['name'].toString();
            }
            if (d['vehicle'] != null) {
              final rawVeh = d['vehicle'].toString();
              if (!rawVeh.toLowerCase().contains('merced') && !rawVeh.toLowerCase().contains('benz')) {
                _vehicleName = rawVeh;
              }
            }
            if (d['vehicleMake'] != null) {
              final rawMake = d['vehicleMake'].toString();
              if (!rawMake.toLowerCase().contains('merced') && !rawMake.toLowerCase().contains('benz')) {
                _vehicleMake = rawMake;
              }
            }
            if (d['vehicleModel'] != null) _vehicleModel = d['vehicleModel'].toString();
            if (d['vehicleType'] != null) _vehicleType = d['vehicleType'].toString();
            if (d['vehicleNumberPlate'] != null) _vehiclePlate = d['vehicleNumberPlate'].toString();
            if (d['fuelType'] != null || d['vehicleFuelType'] != null) {
              _fuelType = (d['fuelType'] ?? d['vehicleFuelType']).toString();
            }
          }
        }
      } catch (_) {}

      if (_driverName == '-' || _driverName.trim().isEmpty) {
        _driverName = 'Driver';
      }
      if (_accountHolder == '-' || _accountHolder.trim().isEmpty) {
        _accountHolder = _driverName;
      }
      if (_rating == '-' || _rating.trim().isEmpty) {
        _rating = 'New';
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'Za';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  
  Widget _buildDocumentUploadBox({
    required String title,
    required String subtitle,
    required String? fileName,
    required VoidCallback onPick,
    VoidCallback? onView,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fileName != null ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fileName != null ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              fileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: fileName != null ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  fileName != null ? 'Selected: $fileName' : subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: fileName != null ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: fileName != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onView != null) ...[
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fileName != null ? 'Change' : 'Upload',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? hint,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              counterText: maxLength != null ? '' : null,
              prefixIcon: Icon(icon, color: readOnly ? AppColors.textMuted : AppColors.primary, size: 20),
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Personal Information Modal (View | Edit)
  void _showPersonalInfoModal() {
    final nameCtrl = TextEditingController(text: _driverName == '-' ? '' : _driverName);
    final cleanDigits = _driverPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    final phoneCtrl = TextEditingController(text: tenDigits);
    final emailCtrl = TextEditingController(text: _driverEmail == '-' ? '' : _driverEmail);
    final cityCtrl = TextEditingController(text: _city == '-' ? '' : _city);
    bool isEditing = false;
    bool isSubmitting = false;

    // Tracks the last OTP-verified phone number for this modal session; a driver must re-verify
    // via OTP (same flow as login) whenever they change the number to something not yet verified.
    String verifiedPhone = tenDigits;
    bool isPhoneVerified = tenDigits.isNotEmpty;
    phoneCtrl.addListener(() {
      final current = phoneCtrl.text.trim();
      if (current != verifiedPhone) {
        isPhoneVerified = false;
      } else if (verifiedPhone.isNotEmpty) {
        isPhoneVerified = true;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Personal Information' : 'Personal Information',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit Mode', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!isEditing) ...[
                      _buildModalField('Full Name', _driverName),
                      _buildModalField('Phone Number', _driverPhone),
                      _buildModalField('Email', _driverEmail),
                      _buildModalField('Status', _statusText),
                      _buildModalField('City', _city),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setModalState(() => isEditing = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Edit', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildModalTextField(
                        label: 'Full Name',
                        controller: nameCtrl,
                        icon: Icons.person_outline_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.]')),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Phone Number',
                        controller: phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        prefixText: '+91 ',
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Email Address',
                        controller: emailCtrl,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildModalTextField(
                        label: 'Operating City / State',
                        controller: cityCtrl,
                        icon: Icons.location_city_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s,]')),
                        ],
                      ),
                      _buildModalTextField(label: 'Status (Backend-Managed)', controller: TextEditingController(text: _statusText), icon: Icons.lock_outline_rounded, readOnly: true),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => setModalState(() => isEditing = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      final phone = phoneCtrl.text.trim();
                                      final email = emailCtrl.text.trim();
                                      final city = cityCtrl.text.trim();

                                      if (name.isEmpty || RegExp(r'[0-9]').hasMatch(name)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter a valid full name (letters only).'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }
                                      if (phone.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter a valid 10-digit phone number.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }
                                      if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter a valid email address (e.g. name@domain.com).'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }
                                      if (city.isNotEmpty && RegExp(r'[0-9]').hasMatch(city)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Operating City / State can only contain letters.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      Future<void> persistPersonalInfo() async {
                                        setModalState(() => isSubmitting = true);
                                        final res = await DriverService.updatePersonalInfo(
                                          fullName: name,
                                          phoneNumber: '+91$phone',
                                          email: email,
                                          city: city,
                                          location: city,
                                        );
                                        setModalState(() => isSubmitting = false);

                                        if (res['success'] == true) {
                                          setState(() {
                                            _driverName = name;
                                            _driverPhone = '+91$phone';
                                            _driverEmail = email;
                                            _city = city;
                                            _accountHolder = name;
                                          });

                                          final prefs = await SharedPreferences.getInstance();
                                          final cd = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                          await prefs.setString('user_name_$cd', name);
                                          await prefs.setString('currentUserName', name);
                                          await prefs.setString('driver_name_$cd', name);
                                          await prefs.setString('driver_email_$cd', email);
                                          await prefs.setString('driver_city_$cd', city);
                                          await prefs.setString('currentPhone', '+91$phone');

                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Personal Information updated successfully! 🎉'),
                                              backgroundColor: AppColors.success,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          setModalState(() => isEditing = false);
                                        } else {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(res['message']?.toString() ?? 'Failed to update personal information.'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }

                                      // Require OTP re-verification (same API/screen as login) whenever the
                                      // driver changes their phone number to one not yet verified this session.
                                      final cleanCurrentPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                      final bool phoneHasChanged = cleanCurrentPhone.isNotEmpty && cleanCurrentPhone != verifiedPhone;

                                      if (phoneHasChanged && !isPhoneVerified) {
                                        setModalState(() => isSubmitting = true);
                                        final formattedPhone = '+91 $phone';
                                        String otp = '';
                                        String matchedPhone = formattedPhone;
                                        bool otpRequested = false;
                                        try {
                                          final otpRes = await AuthService.loginInitMobile(phone: formattedPhone);
                                          if (otpRes['success'] == true) {
                                            otpRequested = true;
                                            matchedPhone = otpRes['matchedPhone']?.toString() ?? formattedPhone;
                                            otp = (otpRes['otp'] ?? (otpRes['data'] is Map ? otpRes['data']['otp'] : null))?.toString() ?? '';
                                          }
                                        } catch (_) {}
                                        setModalState(() => isSubmitting = false);

                                        if (!mounted) return;

                                        if (!otpRequested) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Could not send the verification code. Please try again.'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.mark_email_read_rounded, color: Colors.white),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    otp.isNotEmpty ? 'OTP Sent to $matchedPhone: $otp' : 'OTP sent to $matchedPhone',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppColors.primary,
                                            duration: const Duration(seconds: 4),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );

                                        final verified = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OtpVerificationScreen(
                                              phoneNumber: matchedPhone,
                                              expectedOtp: otp,
                                              isPhoneUpdateFlow: true,
                                              userName: name,
                                            ),
                                          ),
                                        );

                                        if (verified != true) {
                                          // Verification cancelled or failed — do not save the new phone number.
                                          return;
                                        }

                                        isPhoneVerified = true;
                                        verifiedPhone = cleanCurrentPhone;
                                      }

                                      await persistPersonalInfo();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Vehicle Information Modal (View | Edit)
  static const int _maxDocSizeBytes = 3 * 1024 * 1024; // 3 MB strict limit

  void _showDocumentSourcePickerSheet({
    required BuildContext context,
    required String title,
    required Function(dynamic fileObject, String fileName, String fileSize) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload image (JPG, PNG) or PDF document (Max: 3 MB)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture with your camera'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? img = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (img == null) return;
                      final length = await img.length();
                      if (length > _maxDocSizeBytes) {
                        _showFileSizeExceededError();
                        return;
                      }
                      final sizeStr = _formatBytes(length);
                      onSelected(img, img.name, sizeStr);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Choose Image (Gallery)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select a JPG or PNG from device'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? img = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (img == null) return;
                      final length = await img.length();
                      if (length > _maxDocSizeBytes) {
                        _showFileSizeExceededError();
                        return;
                      }
                      final sizeStr = _formatBytes(length);
                      onSelected(img, img.name, sizeStr);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gallery error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Select PDF Document', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Browse for a PDF document'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        allowMultiple: false,
                        withData: kIsWeb,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        if (file.size > _maxDocSizeBytes) {
                          _showFileSizeExceededError();
                          return;
                        }
                        final sizeStr = _formatBytes(file.size);
                        onSelected(file, file.name, sizeStr);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFileSizeExceededError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected file exceeds 3 MB limit. Please select a smaller file.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes > 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void _showVehicleInfoModal() {
    String cleanCtrl(String v) => (v == '-' || v.toLowerCase().contains('merced') || v.toLowerCase().contains('benz')) ? '' : v;
    final nameCtrl = TextEditingController(text: cleanCtrl(_vehicleName));
    final makeCtrl = TextEditingController(text: cleanCtrl(_vehicleMake));
    final modelCtrl = TextEditingController(text: cleanCtrl(_vehicleModel));
    final typeCtrl = TextEditingController(text: cleanCtrl(_vehicleType));
    final plateCtrl = TextEditingController(text: cleanCtrl(_vehiclePlate));
    final fuelCtrl = TextEditingController(text: cleanCtrl(_fuelType));
    String? rcDocName;
    String? insDocName;
    dynamic rcDocFile;
    dynamic insDocFile;
    bool isEditing = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Vehicle Information' : 'Vehicle Information',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit Mode', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!isEditing) ...[
                      _buildModalField('Vehicle Name', cleanCtrl(_vehicleName).isNotEmpty ? _vehicleName : '-'),
                      _buildModalField('Make / Brand', cleanCtrl(_vehicleMake).isNotEmpty ? _vehicleMake : '-'),
                      _buildModalField('Model', _vehicleModel),
                      _buildModalField('Type', _vehicleType),
                      _buildModalField('Number Plate', _vehiclePlate),
                      _buildModalField('Fuel Type', _fuelType),
                      _buildModalField('Capacity', _vehicleType.isNotEmpty && _vehicleType != '-' ? _vehicleType : '-'),
                      const SizedBox(height: 12),
                      const Text(
                        'Uploaded Documents',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildUploadedDocumentRow(
                        title: 'Registration Certificate (RC)',
                        url: _rcDocumentUrl,
                        localFile: rcDocFile,
                      ),
                      _buildUploadedDocumentRow(
                        title: 'Vehicle Insurance',
                        url: _insuranceDocumentUrl,
                        localFile: insDocFile,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setModalState(() => isEditing = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Edit', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildModalTextField(
                        label: 'Vehicle Name',
                        controller: nameCtrl,
                        icon: Icons.directions_car_rounded,
                        hint: 'e.g. Swift Dzire, Innova, XUV700',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Make / Brand',
                        controller: makeCtrl,
                        icon: Icons.branding_watermark_rounded,
                        hint: 'e.g. Maruti Suzuki, Hyundai, Tata, Kia',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Model',
                        controller: modelCtrl,
                        icon: Icons.car_repair_rounded,
                        hint: 'e.g. VXI, ZXI, 2022',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Vehicle Type',
                        controller: typeCtrl,
                        icon: Icons.category_rounded,
                        hint: 'MPV / Sedan / SUV',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      _buildModalTextField(
                        label: 'Number Plate',
                        controller: plateCtrl,
                        icon: Icons.badge_outlined,
                        hint: 'e.g. AP09BK1234',
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          LengthLimitingTextInputFormatter(10),
                          _UpperCaseTextFormatter(),
                        ],
                      ),
                      _buildModalTextField(label: 'Fuel Type', controller: fuelCtrl, icon: Icons.local_gas_station_rounded, hint: 'Diesel / Petrol / CNG / EV'),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Documents',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildDocumentUploadBox(
                        title: 'Registration Certificate (RC)',
                        subtitle: _rcDocumentUrl != null && _rcDocumentUrl!.isNotEmpty
                            ? 'Document uploaded on server'
                            : 'Upload vehicle RC document or photo (Max: 3 MB)',
                        fileName: rcDocName,
                        onView: (rcDocFile != null || (_rcDocumentUrl != null && _rcDocumentUrl!.isNotEmpty))
                            ? () => _showDocumentPreviewDialog(
                                  'Registration Certificate (RC)',
                                  url: _rcDocumentUrl,
                                  localFile: rcDocFile,
                                )
                            : null,
                        onPick: () {
                          _showDocumentSourcePickerSheet(
                            context: context,
                            title: 'Upload RC Document',
                            onSelected: (fileObj, name, size) {
                              setModalState(() {
                                rcDocName = '$name ($size)';
                                rcDocFile = fileObj;
                              });
                            },
                          );
                        },
                      ),
                      _buildDocumentUploadBox(
                        title: 'Vehicle Insurance',
                        subtitle: _insuranceDocumentUrl != null && _insuranceDocumentUrl!.isNotEmpty
                            ? 'Document uploaded on server'
                            : 'Upload valid insurance policy copy (Max: 3 MB)',
                        fileName: insDocName,
                        onView: (insDocFile != null || (_insuranceDocumentUrl != null && _insuranceDocumentUrl!.isNotEmpty))
                            ? () => _showDocumentPreviewDialog(
                                  'Vehicle Insurance',
                                  url: _insuranceDocumentUrl,
                                  localFile: insDocFile,
                                )
                            : null,
                        onPick: () {
                          _showDocumentSourcePickerSheet(
                            context: context,
                            title: 'Upload Vehicle Insurance',
                            onSelected: (fileObj, name, size) {
                              setModalState(() {
                                insDocName = '$name ($size)';
                                insDocFile = fileObj;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => setModalState(() => isEditing = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final vName = nameCtrl.text.trim();
                                      final vMake = makeCtrl.text.trim();
                                      final vModel = modelCtrl.text.trim();
                                      final vType = typeCtrl.text.trim();
                                      final vPlate = plateCtrl.text.trim();
                                      final vFuel = fuelCtrl.text.trim();

                                      if (vName.isEmpty && vPlate.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter vehicle details.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }
                                      if (vMake.isNotEmpty && RegExp(r'[0-9]').hasMatch(vMake)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Make / Brand cannot contain numbers.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }
                                      if (vType.isNotEmpty && RegExp(r'[0-9]').hasMatch(vType)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vehicle Type cannot contain numbers.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }
                                      if (vPlate.isNotEmpty && vPlate.length > 10) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Number Plate must be at most 10 characters.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      String normalizedFuel = vFuel;
                                      if (vFuel.isNotEmpty) {
                                        final lowerFuel = vFuel.toLowerCase();
                                        if (lowerFuel.contains('petrol')) {
                                          normalizedFuel = 'Petrol';
                                        } else if (lowerFuel.contains('diesel')) {
                                          normalizedFuel = 'Diesel';
                                        } else if (lowerFuel.contains('cng')) {
                                          normalizedFuel = 'CNG';
                                        } else if (lowerFuel.contains('elec') || lowerFuel.contains('ev')) {
                                          normalizedFuel = 'Electric';
                                        } else if (lowerFuel.contains('hyb')) {
                                          normalizedFuel = 'Hybrid';
                                        } else {
                                          normalizedFuel = 'Petrol';
                                        }
                                      }

                                      setModalState(() => isSubmitting = true);
                                      final res = await DriverService.updateVehicleInfo(
                                        vehicleName: vName.isNotEmpty ? vName : null,
                                        vehicleMake: vMake.isNotEmpty ? vMake : null,
                                        vehicleModel: vModel.isNotEmpty ? vModel : null,
                                        vehicleType: vType.isNotEmpty ? vType : null,
                                        vehicleNumberPlate: vPlate.isNotEmpty ? vPlate : null,
                                        fuelType: normalizedFuel.isNotEmpty ? normalizedFuel : null,
                                        rcDocumentFile: rcDocFile,
                                        insuranceDocumentFile: insDocFile,
                                      );
                                      setModalState(() => isSubmitting = false);

                                      if (res['success'] == true) {
                                        setState(() {
                                          if (vName.isNotEmpty) _vehicleName = vName;
                                          if (vMake.isNotEmpty) _vehicleMake = vMake;
                                          if (vModel.isNotEmpty) _vehicleModel = vModel;
                                          if (vType.isNotEmpty) _vehicleType = vType;
                                          if (vPlate.isNotEmpty) _vehiclePlate = vPlate;
                                          if (normalizedFuel.isNotEmpty) _fuelType = normalizedFuel;
                                        });

                                        final cd = _driverPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                        final prefs = await SharedPreferences.getInstance();
                                        if (vName.isNotEmpty) {
                                          await prefs.setString('driver_vehicle_$cd', vName);
                                          await prefs.setString('driver_vehicle_name_$cd', vName);
                                        }
                                        if (vMake.isNotEmpty) await prefs.setString('driver_vehicle_make_$cd', vMake);
                                        if (vModel.isNotEmpty) await prefs.setString('driver_vehicle_model_$cd', vModel);
                                        if (vType.isNotEmpty) await prefs.setString('driver_vehicle_type_$cd', vType);
                                        if (vPlate.isNotEmpty) await prefs.setString('driver_vehicle_plate_$cd', vPlate);
                                        if (normalizedFuel.isNotEmpty) await prefs.setString('driver_vehicle_fuel_$cd', normalizedFuel);

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Vehicle Information updated successfully! 🎉'),
                                            backgroundColor: AppColors.success,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        setModalState(() => isEditing = false);
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(res['message']?.toString() ?? 'Failed to update vehicle information.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Driving License Modal (View | Edit)
  void _showDrivingLicenseModal() {
    final numberCtrl = TextEditingController(text: _licenseNumber);
    String? dlFrontName;
    String? dlBackName;
    dynamic dlFrontFile;
    dynamic dlBackFile;
    bool isEditing = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Driving License' : 'Driving License',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit Mode', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!isEditing) ...[
                      _buildModalField('License Number', _licenseNumber),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setModalState(() => isEditing = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Edit', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildModalTextField(label: 'License Number', controller: numberCtrl, icon: Icons.description_outlined),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Documents',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildDocumentUploadBox(
                        title: 'Driving License (Front)',
                        subtitle: 'Upload front photo of license (Max: 3 MB)',
                        fileName: dlFrontName,
                        onPick: () {
                          _showDocumentSourcePickerSheet(
                            context: context,
                            title: 'Upload DL (Front)',
                            onSelected: (fileObj, name, size) {
                              setModalState(() {
                                dlFrontName = 'size)';
                                dlFrontFile = fileObj;
                              });
                            },
                          );
                        },
                      ),
                      _buildDocumentUploadBox(
                        title: 'Driving License (Back)',
                        subtitle: 'Upload rear photo of license (Max: 3 MB)',
                        fileName: dlBackName,
                        onPick: () {
                          _showDocumentSourcePickerSheet(
                            context: context,
                            title: 'Upload DL (Back)',
                            onSelected: (fileObj, name, size) {
                              setModalState(() {
                                dlBackName = 'size)';
                                dlBackFile = fileObj;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => setModalState(() => isEditing = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final num = numberCtrl.text.trim();

                                      if (num.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter your license number.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);
                                      final res = await DriverService.updateDrivingLicenseInfo(
                                        licenseNumber: num,
                                        licenseFrontFile: dlFrontFile,
                                        licenseBackFile: dlBackFile,
                                      );
                                      setModalState(() => isSubmitting = false);

                                      if (res['success'] == true) {
                                        setState(() {
                                          _licenseNumber = num;
                                        });

                                        final prefs = await SharedPreferences.getInstance();
                                        final cd = _driverPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                        await prefs.setString('driver_license_$cd', num);

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Driving License updated successfully! 🎉'),
                                            backgroundColor: AppColors.success,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        setModalState(() => isEditing = false);
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(res['message']?.toString() ?? 'Failed to update license information.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. Bank Account Modal (View | Edit)
  // ignore: unused_element
  void _showBankAccountModal() {
    final holderCtrl = TextEditingController(text: _accountHolder);
    final bankCtrl = TextEditingController(text: _bankName);
    final numberCtrl = TextEditingController(text: _accountNumber);
    final ifscCtrl = TextEditingController(text: _ifscCode);
    String? bankDocName;
    bool isEditing = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Bank Account' : 'Bank Account & Payouts',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit Mode', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!isEditing) ...[
                      _buildModalField('Account Holder', _accountHolder),
                      _buildModalField('Bank Name', _bankName),
                      _buildModalField('Account Number', _accountNumber),
                      _buildModalField('IFSC Code', _ifscCode),
                      _buildModalField('Payout Status', _payoutStatus),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setModalState(() => isEditing = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Edit', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildModalTextField(label: 'Account Holder Name', controller: holderCtrl, icon: Icons.person_outline_rounded),
                      _buildModalTextField(label: 'Bank Name', controller: bankCtrl, icon: Icons.account_balance_rounded),
                      _buildModalTextField(label: 'Account Number', controller: numberCtrl, icon: Icons.numbers_rounded, keyboardType: TextInputType.number),
                      _buildModalTextField(label: 'IFSC Code', controller: ifscCtrl, icon: Icons.qr_code_rounded),
                      _buildModalTextField(label: 'Payout Status (System-Managed)', controller: TextEditingController(text: _payoutStatus), icon: Icons.lock_outline_rounded, readOnly: true),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Documents',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildDocumentUploadBox(
                        title: 'Cancelled Cheque / Passbook',
                        subtitle: 'Upload photo of cheque leaf or passbook',
                        fileName: bankDocName,
                        onPick: () async {
                          final file = await _imagePicker.pickImage(source: ImageSource.gallery);
                          if (file != null) setModalState(() => bankDocName = file.name);
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => setModalState(() => isEditing = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final holder = holderCtrl.text.trim();
                                      final bank = bankCtrl.text.trim();
                                      final num = numberCtrl.text.trim();
                                      final ifsc = ifscCtrl.text.trim();

                                      if (holder.isEmpty || bank.isEmpty || num.isEmpty || ifsc.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please fill all bank details.'), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);
                                      final res = await DriverService.updateBankAccountInfo(
                                        accountHolder: holder,
                                        bankName: bank,
                                        accountNumber: num,
                                        ifscCode: ifsc,
                                      );
                                      setModalState(() => isSubmitting = false);

                                      if (res['success'] == true) {
                                        setState(() {
                                          _accountHolder = holder;
                                          _bankName = bank;
                                          _accountNumber = num;
                                          _ifscCode = ifsc;
                                        });

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Bank Account details updated successfully! 🎉'),
                                            backgroundColor: AppColors.success,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        setModalState(() => isEditing = false);
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(res['message']?.toString() ?? 'Failed to update bank account details.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  
  Future<void> _showDeleteAccountDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your Zaatra account?\n\n'
          'This will remove all your profile information, ride history, documents, and credentials. '
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final res = await AuthService.deleteAccount();
    if (!mounted) return;
    final isSuccess = res['success'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSuccess ? 'Your Zaatra account has been deleted.' : 'Account deleted locally.'),
        backgroundColor: Colors.redAccent,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen(isExistingUser: false)),
      (route) => false,
    );
  }

  // ignore: unused_element
  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.check_circle_outline_rounded)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (currentPassController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter current password.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          if (newPassController.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New password must be at least 6 characters.'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          if (newPassController.text != confirmPassController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final res = await DriverService.changePassword(
                            currentPassword: currentPassController.text.trim(),
                            newPassword: newPassController.text.trim(),
                          );
                          setDialogState(() => isSubmitting = false);

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;

                          final success = res['success'] == true;
                          final msg = res['message']?.toString() ??
                              (success ? 'Password updated successfully!' : 'Failed to update password.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: success ? AppColors.success : Colors.redAccent,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final ext = file.name.split('.').last.toLowerCase();
      if (ext != 'png' && ext != 'jpg' && ext != 'jpeg') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a PNG or JPEG image.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be under 5MB.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      setState(() {
        _avatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.isNotEmpty) {
        await prefs.setString('driver_avatar_base64_$cleanDigits', base64Encode(bytes));
      }

      // Upload to backend: POST /api/drivers/profile/photo (alias /api/drivers/avatar)
      final uploadRes = await DriverService.uploadProfilePhoto(file);
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);

      if (uploadRes['success'] == true) {
        final uploadedUrl = uploadRes['resolvedPhotoUrl']?.toString() ??
            uploadRes['avatarUrl']?.toString() ??
            uploadRes['driverPhotoUrl']?.toString() ??
            uploadRes['avatar']?.toString() ??
            uploadRes['driverPhoto']?.toString();
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          setState(() => _avatarUrl = uploadedUrl);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadRes['message']?.toString() ?? 'Profile photo updated successfully! 🎉',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadRes['message']?.toString() ?? 'Failed to sync photo with server.',
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_driverName);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Driver Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              fit: StackFit.expand,
              children: [
          // Bottom Background Graphic
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/image 31.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Header with Purple Background matching Image 2
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(200), width: 2),
                              ),
                              child: ClipOval(
                                child: _isUploadingAvatar
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : _avatarBytes != null
                                        ? Image.memory(
                                            _avatarBytes!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                          )
                                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                            ? Image.network(
                                                _avatarUrl!.startsWith('http')
                                                    ? _avatarUrl!
                                                    : '${ApiService.baseUrl.replaceAll('/api', '')}${_avatarUrl!.startsWith('/') ? _avatarUrl : '/$_avatarUrl'}',
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driverPhone,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DriverRatingsReviewsScreen()),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Verified Driver',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Settings Card Container matching Image 2
                Container(
                  transform: Matrix4.translationValues(0, -20, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [

                      _buildSettingsItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        onTap: _showPersonalInfoModal,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.directions_car_outlined,
                        title: 'Vehicle Information',
                        onTap: _showVehicleInfoModal,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.description_outlined,
                        title: 'Driving License',
                        onTap: _showDrivingLicenseModal,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.support_agent_rounded,
                        title: 'Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DriverSupportHelpScreen()),
                          );
                        },
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.local_gas_station_rounded,
                        title: 'Fuel Share',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DriverEarningsHistoryScreen()),
                          );
                        },
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isLogout: true,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to log out of your driver account?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  child: const Text('Logout', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          await AuthService.logout();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged Out Successfully.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen(isExistingUser: true)),
                            (route) => false,
                          );
                        },
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildSettingsItem(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account from Zaatra',
                        isLogout: true,
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer Version Tag matching Image 2
                const Text(
                  'App Version 2.5.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title...')),
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.redAccent : AppColors.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isLogout ? Colors.redAccent : AppColors.textPrimary,
                ),
              ),
            ),
            if (!isLogout)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedDocumentRow({
    required String title,
    String? url,
    dynamic localFile,
  }) {
    final hasLocal = localFile != null;
    final hasUrl = url != null && url.trim().isNotEmpty;
    final hasDoc = hasLocal || hasUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDoc ? Icons.description_rounded : Icons.description_outlined,
            color: hasDoc ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  hasDoc ? 'Uploaded' : 'Not uploaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasDoc ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                    fontWeight: hasDoc ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (hasDoc)
            TextButton.icon(
              onPressed: () => _showDocumentPreviewDialog(
                title,
                url: url,
                localFile: localFile,
              ),
              icon: const Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
              label: const Text(
                'View',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDocumentPreviewDialog(
    String title, {
    String? url,
    dynamic localFile,
  }) async {
    String? resolvedUrl;
    if (url != null && url.trim().isNotEmpty) {
      final clean = url.trim();
      resolvedUrl = clean.startsWith('http')
          ? clean
          : '${ApiService.baseUrl.replaceAll('/api', '')}${clean.startsWith('/') ? clean : '/$clean'}';
    }

    Uint8List? localBytes;
    String? fileName;
    if (localFile != null) {
      try {
        if (localFile is XFile) {
          fileName = localFile.name;
          localBytes = await localFile.readAsBytes();
        } else if (localFile is PlatformFile) {
          fileName = localFile.name;
          localBytes = localFile.bytes;
        }
      } catch (_) {}
    }

    final isPdf = (fileName ?? resolvedUrl ?? '').toLowerCase().contains('.pdf');
    if (isPdf && resolvedUrl != null) {
      final uri = Uri.tryParse(resolvedUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 420),
              padding: const EdgeInsets.all(16),
              child: localBytes != null
                  ? InteractiveViewer(
                      child: Image.memory(localBytes, fit: BoxFit.contain),
                    )
                  : (resolvedUrl != null
                      ? InteractiveViewer(
                          child: Image.network(
                            resolvedUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 10),
                                  Text(
                                    'Could not load document preview.',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No document preview available.'),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}