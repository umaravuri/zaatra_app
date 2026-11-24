import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_19_post_unit_hub.dart';

/// Figma: frame 1228744489 (node 1:243)
class HostScreen18UploadPhotos extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic>? unitData;

  const HostScreen18UploadPhotos({
    super.key,
    required this.draft,
    this.unitData,
  });

  @override
  State<HostScreen18UploadPhotos> createState() => _HostScreen18UploadPhotosState();
}

class _HostScreen18UploadPhotosState extends State<HostScreen18UploadPhotos> {
  late HostUpdatedPropertyDraft _draft;
  // Photos start empty; the host adds their own (no pre-loaded sample photos).
  final List<String> _sampleAssets = [];

  final List<XFile> _pickedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _pickedFiles.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    }
  }

  void _removeSample(int index) {
    setState(() {
      _sampleAssets.removeAt(index);
    });
  }

  void _removePicked(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  void _onPublish() async {
    setState(() => _isUploading = true);

    List<String> photoList = [..._sampleAssets];

    // Upload picked files via API 6
    if (_pickedFiles.isNotEmpty) {
      final uploadRes = await HostApiService.uploadPropertyPhotos(
        propertyId: _draft.propertyId,
        files: _pickedFiles,
      );
      if (uploadRes['success'] == true && uploadRes['photos'] is List) {
        final uploaded = (uploadRes['photos'] as List)
            .map((p) => (p is Map ? p['url'] : p).toString())
            .toList();
        photoList.addAll(uploaded);
      } else {
        photoList.addAll(_pickedFiles.map((f) => f.path));
      }
    }

    if (mounted) setState(() => _isUploading = false);

    // Merge the unit details from screen 17 (price, beds, rules, ...) with the photos.
    final updatedUnits = List<Map<String, dynamic>>.from(_draft.units);
    final base = updatedUnits.isNotEmpty ? updatedUnits.first : <String, dynamic>{};
    final unit = <String, dynamic>{
      ...base,
      ...?widget.unitData,
      'photos': photoList,
    };
    if (updatedUnits.isNotEmpty) {
      updatedUnits[0] = unit;
    } else {
      updatedUnits.add(unit);
    }

    final updatedDraft = _draft.copyWith(units: updatedUnits);

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen19PostUnitHub(draft: updatedDraft),
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
                  title: 'Upload Photos',
                  onBack: () => Navigator.pop(context, _draft),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.55,
                          ),
                          children: [
                            // 1. Picked images from gallery
                            ..._pickedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? Image.network(file.path, fit: BoxFit.cover)
                                        : Image.file(File(file.path), fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: InkWell(
                                      onTap: () => _removePicked(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // 2. Sample property photos matching 1.png
                            ..._sampleAssets.asMap().entries.map((entry) {
                              final index = entry.key;
                              final assetPath = entry.value;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      assetPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFF2EFFD),
                                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF5E42C2)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: InkWell(
                                      onTap: () => _removeSample(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // 3. Dashed "+ Add Photos" button matching 1.png
                            InkWell(
                              onTap: _pickImages,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF5E42C2),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      color: Color(0xFF5E42C2),
                                      size: 26,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add Photos',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5E42C2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: HostBottomButton(
                    text: _isUploading ? 'Uploading Photos...' : 'Continue',
                    onPressed: _isUploading ? null : _onPublish,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
