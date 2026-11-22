import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import 'driver_vehicle_info_screen_35.dart';

class DriverDocumentUploadScreen extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? driverData;

  const DriverDocumentUploadScreen({
    super.key,
    this.role = 'Driver',
    this.driverData,
  });

  @override
  State<DriverDocumentUploadScreen> createState() => _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState extends State<DriverDocumentUploadScreen> {
  bool _isLoading = false;

  // Document 1: Driver's License (Front)
  bool _licenseFrontUploaded = false;
  String _licenseFrontFileName = '';
  String _licenseFrontFileSize = '';
  dynamic _licenseFrontFile;

  // Document 2: Vehicle Registration (RC)
  bool _rcUploaded = false;
  String _rcFileName = '';
  String _rcFileSize = '';
  dynamic _rcFile;

  // Document 3: Driver's License (Back) / Insurance
  bool _licenseBackUploaded = false;
  String _licenseBackFileName = '';
  String _licenseBackFileSize = '';
  dynamic _licenseBackFile;

  static const int maxFileSizeBytes = 3 * 1024 * 1024; // 3 MB strict limit

  void _pickDocument(String docType) {
    _showDocumentPickerSheet(docType);
  }

  void _showDocumentPickerSheet(String docType) {
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
                const Text(
                  'Select Document Source',
                  style: TextStyle(
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
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromImageSource(docType, ImageSource.camera);
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
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromImageSource(docType, ImageSource.gallery);
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
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPdfDocument(docType);
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

  Future<void> _pickFromImageSource(String docType, ImageSource source) async {
    try {
      final XFile? img = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (img == null) return;

      final length = await img.length();
      if (length > maxFileSizeBytes) {
        _showFileSizeExceededError();
        return;
      }

      _processSelectedDocument(
        docType: docType,
        fileName: img.name,
        fileBytesLength: length,
        fileObject: img,
      );
    } catch (e) {
      _showError('Camera/Gallery error: $e');
    }
  }

  Future<void> _pickPdfDocument(String docType) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxFileSizeBytes) {
          _showFileSizeExceededError();
          return;
        }

        _processSelectedDocument(
          docType: docType,
          fileName: file.name,
          fileBytesLength: file.size,
          fileObject: file,
        );
      }
    } catch (e) {
      _showError('PDF selection error: $e');
    }
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _processSelectedDocument({
    required String docType,
    required String fileName,
    required int fileBytesLength,
    required dynamic fileObject,
  }) {
    final sizeKb = (fileBytesLength / 1024).toStringAsFixed(1);
    final sizeStr = fileBytesLength > 1024 * 1024
        ? '${(fileBytesLength / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

    setState(() {
      if (docType == 'license_front') {
        _licenseFrontUploaded = true;
        _licenseFrontFileName = fileName;
        _licenseFrontFileSize = sizeStr;
        _licenseFrontFile = fileObject;
      } else if (docType == 'rc') {
        _rcUploaded = true;
        _rcFileName = fileName;
        _rcFileSize = sizeStr;
        _rcFile = fileObject;
      } else if (docType == 'license_back') {
        _licenseBackUploaded = true;
        _licenseBackFileName = fileName;
        _licenseBackFileSize = sizeStr;
        _licenseBackFile = fileObject;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('$fileName attached ($sizeStr)')),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _nextStep() async {
    // 🛡️ CRITICAL: None of the fields or uploads on Screen 33 are mandatory!
    // Drivers can upload documents or proceed without uploading anything.
    setState(() {
      _isLoading = true;
    });

    final phone = widget.driverData?['cleanPhone'] ?? widget.driverData?['phone'] ?? '';
    final cleanDigits = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    // Call API 3: POST /api/drivers/register/step-2 (or /drivers/onboarding/step-2)
    Map<String, dynamic>? step2Response;
    try {
      step2Response = await DriverService.registerStep2(
        phone: tenDigits,
        drivingLicense: _licenseFrontUploaded ? (_licenseFrontFile ?? _licenseFrontFileName) : null,
        vehicleRegistration: _rcUploaded ? (_rcFile ?? _rcFileName) : null,
        drivingLicenseBack: _licenseBackUploaded ? (_licenseBackFile ?? _licenseBackFileName) : null,
      );
    } catch (_) {}

    final updatedDriverData = {
      ...?widget.driverData,
      'documents': {
        'licenseFront': _licenseFrontUploaded ? _licenseFrontFileName : null,
        'licenseFrontSize': _licenseFrontFileSize,
        'rc': _rcUploaded ? _rcFileName : null,
        'rcSize': _rcFileSize,
        'licenseBack': _licenseBackUploaded ? _licenseBackFileName : null,
        'licenseBackSize': _licenseBackFileSize,
      },
      if (step2Response != null) 'step2Response': step2Response,
    };

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (!mounted) return;

    // Navigate to Screen 35 (Vehicle Information)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverVehicleInfoScreen(
          role: widget.role,
          driverData: updatedDriverData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dotted flight trail in background
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OnboardingFlightPathPainter(),
              ),
            ),
          ),

          // Bottom City Skyline Watermark (image 31.png)
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Circular Back Button matching Screen 33
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E8EC)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Progress Bar: Step 2 of 3 (66%) matching Screen 33
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.66,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE8DEF8),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title & Subtitle matching Screen 33
                  const Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2D),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please upload requirement documents (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A8C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Document Card 1: Driver's license (Front side)
                  _buildDocumentCard(
                    title: "Driver's license",
                    subtitle: _licenseFrontUploaded
                        ? '$_licenseFrontFileName ($_licenseFrontFileSize)'
                        : 'upload font side',
                    isUploaded: _licenseFrontUploaded,
                    icon: Icons.airline_seat_recline_normal_rounded,
                    onTapUpload: () => _pickDocument('license_front'),
                  ),

                  const SizedBox(height: 16),

                  // Document Card 2: Vehicle Registration (RC)
                  _buildDocumentCard(
                    title: 'Vehicle Registration',
                    subtitle: _rcUploaded
                        ? '$_rcFileName ($_rcFileSize)'
                        : 'Upload Document',
                    isUploaded: _rcUploaded,
                    icon: Icons.assignment_outlined,
                    onTapUpload: () => _pickDocument('rc'),
                  ),

                  const SizedBox(height: 16),

                  // Document Card 3: Driver's license (Back side) / Insurance
                  _buildDocumentCard(
                    title: "Driver's license (Back) / Insurance",
                    subtitle: _licenseBackUploaded
                        ? '$_licenseBackFileName ($_licenseBackFileSize)'
                        : 'Upload Document',
                    isUploaded: _licenseBackUploaded,
                    icon: Icons.security_rounded,
                    onTapUpload: () => _pickDocument('license_back'),
                  ),

                  const SizedBox(height: 36),

                  // Continue CTA Button matching Screen 33
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required IconData icon,
    required VoidCallback onTapUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFE2E4E9),
          width: isUploaded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon inside soft container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFFE8F5E9)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? const Color(0xFF2E7D32) : AppColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUploaded ? const Color(0xFF2E7D32) : const Color(0xFF7A7A8C),
                    fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Upload action button on right
          GestureDetector(
            onTap: onTapUpload,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUploaded
                    ? const Color(0xFFE8F5E9)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploaded
                      ? const Color(0xFF81C784)
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Icon(
                  isUploaded ? Icons.refresh_rounded : Icons.file_upload_outlined,
                  color: isUploaded ? const Color(0xFF2E7D32) : AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted flight path decoration matching the onboarding screens
class _OnboardingFlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1C4E9).withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.35);
    path.cubicTo(
      size.width * 0.3, size.height * 0.28,
      size.width * 0.5, size.height * 0.22,
      size.width * 0.5, size.height * 0.14,
    );
    path.cubicTo(
      size.width * 0.5, size.height * 0.08,
      size.width * 0.38, size.height * 0.08,
      size.width * 0.38, size.height * 0.14,
    );
    path.cubicTo(
      size.width * 0.38, size.height * 0.22,
      size.width * 0.7, size.height * 0.18,
      size.width * 0.94, size.height * 0.06,
    );

    // Draw dashed path
    final dashPath = Path();
    double distance = 0.0;
    const dashLength = 4.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);

    // Airplane vector icon at path end
    final planePainter = TextPainter(
      text: const TextSpan(
        text: '✈',
        style: TextStyle(
          fontSize: 22,
          color: Color(0xFFB39DDB),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(size.width * 0.86, size.height * 0.03);
    canvas.rotate(0.25);
    planePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
