import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../models/place_location_model.dart';
import '../../services/google_maps_service.dart';

class LocationAutocompletePickerModal extends StatefulWidget {
  final String title;
  final String initialQuery;
  final String hintText;

  const LocationAutocompletePickerModal({
    super.key,
    this.title = 'Select Location',
    this.initialQuery = '',
    this.hintText = 'Search area, landmark, or street...',
  });

  static Future<LocationPoint?> show(
    BuildContext context, {
    String title = 'Select Location',
    String initialQuery = '',
    String hintText = 'Search area, landmark, or street...',
  }) {
    return showModalBottomSheet<LocationPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationAutocompletePickerModal(
        title: title,
        initialQuery: initialQuery,
        hintText: hintText,
      ),
    );
  }

  @override
  State<LocationAutocompletePickerModal> createState() => _LocationAutocompletePickerModalState();
}

class _LocationAutocompletePickerModalState extends State<LocationAutocompletePickerModal> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  List<PlaceAutocompletePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isResolvingDetails = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final results = await GoogleMapsService.getAutocompleteSuggestions(query);
    if (!mounted) return;
    setState(() {
      _predictions = results;
      _isLoading = false;
    });
  }

  Future<void> _onSelectPrediction(PlaceAutocompletePrediction prediction) async {
    setState(() {
      _isResolvingDetails = true;
    });

    final locationPoint = await GoogleMapsService.getPlaceDetails(prediction.placeId);

    if (!mounted) return;
    setState(() {
      _isResolvingDetails = false;
    });

    if (locationPoint != null) {
      Navigator.pop(context, locationPoint);
    } else {
      // Fallback if details call fails
      Navigator.pop(
        context,
        LocationPoint(
          name: prediction.mainText,
          formattedAddress: prediction.description,
          latitude: 17.4486,
          longitude: 78.3908,
          placeId: prediction.placeId,
        ),
      );
    }
  }

  Future<void> _onUseCurrentLocation() async {
    setState(() {
      _isResolvingDetails = true;
    });

    try {
      final loc = await GoogleMapsService.getCurrentLocation();
      if (!mounted) return;
      if (loc != null) {
        Navigator.pop(context, loc);
      }
    } catch (e) {
      if (!mounted) return;
      _showLocationErrorDialog(e);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingDetails = false;
        });
      }
    }
  }

  void _showLocationErrorDialog(dynamic error) {
    final isServiceDisabled = error is LocationServiceDisabledException;
    final isPermission = error is PermissionDeniedException;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isServiceDisabled ? Icons.location_off_rounded : Icons.lock_outline_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isServiceDisabled ? 'GPS is Disabled' : 'Location Permission Needed',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GoogleMapsService.getReadableLocationError(error),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: You can also search your area or street directly in the search bar above.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Search Manually', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (isServiceDisabled) {
                Geolocator.openLocationSettings();
              } else if (isPermission) {
                Geolocator.openAppSettings();
              }
            },
            child: Text(
              isServiceDisabled ? 'Turn On GPS' : 'Open Settings',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Use Current Location Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: InkWell(
                onTap: _isResolvingDetails ? null : _onUseCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use My Current Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fetch live GPS location',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _isResolvingDetails
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading || _isResolvingDetails)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  ),
                ),
              ),

            // Results / Suggestions List
            Expanded(
              child: _searchController.text.trim().isNotEmpty
                  ? _buildSearchResults()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final queryText = _searchController.text.trim();

    if (_predictions.isEmpty && !_isLoading) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No live suggestions found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Google Places may be offline or restricted. You can still confirm your entered location directly below:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (queryText.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Use "$queryText"',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      LocationPoint(
                        name: queryText,
                        formattedAddress: queryText,
                        latitude: 17.3850,
                        longitude: 78.4867,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _predictions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final item = _predictions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
          ),
          title: Text(
            item.mainText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
          ),
          subtitle: item.secondaryText.isNotEmpty
              ? Text(
                  item.secondaryText,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => _onSelectPrediction(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final popularLocations = [
      'Hitec City',
      'Gachibowli',
      'Madhapur',
      'Banjara Hills',
      'Jubilee Hills',
      'Secunderabad',
      'Kukatpally',
      'Kondapur',
      'RGIA Airport',
      'Begumpet',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Pickup & Drop Areas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularLocations.map((name) {
              return ActionChip(
                backgroundColor: const Color(0xFFF7F5FE),
                side: BorderSide(color: AppColors.primary.withAlpha(40)),
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.primary),
                ),
                avatar: const Icon(Icons.location_city_rounded, size: 16, color: AppColors.primary),
                onPressed: () {
                  _searchController.text = name;
                  _onQueryChanged(name);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Icon(Icons.search_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                const Text(
                  'Search Live via Google Maps',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Type any street, landmark, or area to get instant autocomplete suggestions.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
