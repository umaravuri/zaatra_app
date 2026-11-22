import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'host_dashboard_screen.dart';
import 'host_screen_5_property_type.dart';
import 'host_screen_6_property_count.dart';
import 'host_screen_7_listing_confirmation.dart';
import 'host_screen_8_location_map.dart';
import 'host_screen_9_channel_manager.dart';
import 'host_screen_10_property_name_rating.dart';
import 'host_screen_11_facilities.dart';
import 'host_screen_12_facility_pricing.dart';
import 'host_screen_13_breakfast_rules_languages.dart';
import 'host_screen_14_pet_policy.dart';
import 'host_screen_15_property_hub.dart';
import 'host_screen_15_accommodation_rooms.dart';
import 'host_screen_16_unit_type.dart';
import 'host_screen_17_unit_details.dart';
import 'host_screen_18_upload_photos.dart';
import 'host_screen_19_post_unit_hub.dart';
import 'host_event_screen_11_event_types.dart';
import 'host_event_screen_12_venue_details.dart';
import 'host_event_screen_13_capacity_stage_dining.dart';
import 'host_event_screen_14_bridal_rooms.dart';
import 'host_screen_20_invoicing.dart';
import 'host_screen_21_verification.dart';
import 'host_screen_22_gst_purpose.dart';
import 'host_screen_23_guest_pay.dart';
import 'host_screen_24_registration.dart';

/// Interactive showcase screen allowing 1-click inspection of all 26 developed screens
class HostScreensGalleryScreen extends StatefulWidget {
  const HostScreensGalleryScreen({super.key});

  @override
  State<HostScreensGalleryScreen> createState() => _HostScreensGalleryScreenState();
}

class _HostScreensGalleryScreenState extends State<HostScreensGalleryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  late final HostUpdatedPropertyDraft _sampleDraft;
  late final Map<String, dynamic> _sampleUnit;
  late final Map<String, dynamic> _sampleEventData;

  @override
  void initState() {
    super.initState();
    _sampleDraft = const HostUpdatedPropertyDraft(
      propertyId: 'PROP-PREVIEW-2026',
      propertyName: 'Sri Lakeview Palace & Convention',
      propertyType: 'Villa',
      listingCountMode: 'multiple',
      locationInput: 'HITEC City, Madhapur, Hyderabad',
      city: 'Hyderabad',
      postalCode: '500081',
      latitude: 17.4486,
      longitude: 78.3908,
      starRating: '4',
      isChainOrGroup: false,
      useChannelManager: true,
      facilities: ['Wifi', 'Swimming Pool', 'AC', 'Power Backup', 'Parking', 'Kitchen'],
      facilityPricing: {
        'Wifi': 'Included',
        'Swimming Pool': 'Extra Charge',
        'AC': 'Included',
        'Power Backup': 'Included',
      },
      servesBreakfast: true,
      allowsChildren: true,
      staffLanguages: ['English', 'Hindi', 'Telugu'],
      allowsPets: 'yes',
      petFeeMode: 'free',
      units: [
        {
          'id': 'unit-1',
          'name': 'Luxury King Suite',
          'type': 'Double',
          'guests': 3,
          'beds': 1,
          'bathrooms': 1,
          'price': 4500.0,
          'roomCount': 4,
          'status': 'configured',
        },
        {
          'id': 'unit-2',
          'name': 'Grand Royal Banquet Hall',
          'type': 'Convention Hall',
          'guests': 800,
          'beds': 0,
          'bathrooms': 4,
          'price': 150000.0,
          'roomCount': 1,
          'status': 'configured',
        }
      ],
      invoiceName: 'Sri Lakeview Hospitality LLP',
      invoiceAddressSame: true,
      entityType: 'business',
      isGstRegistered: true,
      gstNumber: '36AAAAA0000A1Z5',
      panNumber: 'AAAAA0000A',
      guestPaymentMethod: 'online_zaatra',
      registrationGoal: 'bookings',
      isLegitimateCertified: true,
      acceptedTerms: true,
    );

    _sampleUnit = {
      'id': 'unit-preview',
      'name': 'Deluxe Garden Room',
      'type': 'Double',
      'guests': 2,
      'beds': 1,
      'bathrooms': 1,
      'price': 3200.0,
      'roomCount': 2,
    };

    _sampleEventData = {
      'eventType': 'Wedding / Reception',
      'eventCategory': 'Marriage',
      'venueType': 'Banquet Hall + Lawn',
      'hallName': 'Grand Ballroom 1',
      'indoor': true,
      'outdoor': true,
      'seatedCapacity': 600,
      'floatingCapacity': 1200,
      'stageLength': 40,
      'stageWidth': 25,
      'diningCapacity': 300,
      'brideRooms': 2,
      'groomRooms': 1,
      'vipRooms': 2,
    };
  }

  List<Map<String, dynamic>> _getAllScreens() {
    return [
      // Phase 0
      {
        'category': 'Phase 0: Dashboard',
        'number': 'Dashboard',
        'title': 'Host Operations Dashboard',
        'desc': 'KPI Cards, Occupancy trend, Revenue Bezier chart, Active Bookings & Draft resume prompt',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => const HostDashboardScreen(userName: 'Manohar'),
      },

      // Phase 1: Property Details (Screens 5 - 14)
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 5',
        'title': 'Property Category',
        'desc': '11 category selection cards (Hotel, Villa, Flat, Farm stay, Convention Hall, etc.)',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen5PropertyType(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 6',
        'title': 'Property Quantity Scope',
        'desc': 'Single property unit vs Multiple units where guests book individual rooms',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen6PropertyCount(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 7',
        'title': 'Scope Confirmation',
        'desc': 'Contextual confirmation card explaining listing scope implications',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen7ListingConfirmation(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 8',
        'title': 'Location & Interactive Map',
        'desc': 'Address form, postal code, city, country, and interactive draggable map pin',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen8LocationMap(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 9',
        'title': 'Channel Manager Connection',
        'desc': 'Toggle channel manager integration vs direct management on Zaatra',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen9ChannelManager(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 10',
        'title': 'Property Name & Star Rating',
        'desc': 'Title input with character limits, 1-5 star rating selector, chain affiliation switch',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen10PropertyNameRating(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 11',
        'title': 'Facilities & Amenities Checklist',
        'desc': '28+ property-level facilities, multi-select checkboxes, and custom facility creation dialog',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen11Facilities(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 12',
        'title': 'Dynamic Facility Pricing',
        'desc': 'Provisioning selector for each checked facility (Included / Extra Charge / On Request)',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen12FacilityPricing(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 13',
        'title': 'Breakfast, Children & Languages',
        'desc': 'Breakfast price inclusion toggle, children rules, 15+ staff spoken languages',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen13BreakfastRulesLanguages(draft: _sampleDraft),
      },
      {
        'category': 'Phase 1: Wizard',
        'number': 'Screen 14',
        'title': 'Pet Policy & Charges',
        'desc': 'Pet allowance toggle (Yes / Upon Request / No) and surcharge mode selector',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen14PetPolicy(draft: _sampleDraft),
      },

      // Phase 2: Units & Photos (Screens 15 - 19)
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 15 Hub',
        'title': 'Property Setup Hub',
        'desc': '3-stage master onboarding hub with checkmarks and [+ Add Unit] modal router',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen15PropertyHub(draft: _sampleDraft),
      },
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 15 Stay',
        'title': 'Stay Rooms Unit Builder',
        'desc': 'Comprehensive room setup with bed steppers, bathroom check, net payout calculation',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen15AccommodationRooms(draft: _sampleDraft),
      },
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 16',
        'title': 'Unit Type & Purpose',
        'desc': 'Listing purpose radio (Stay vs Event books) and room type dropdown',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen16UnitType(draft: _sampleDraft),
      },
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 17',
        'title': 'Unit Specs & Rate Plans',
        'desc': 'Room count, bed counters, private/shared bath, 20% commission badge, rate plans',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen17UnitDetails(draft: _sampleDraft, currentUnit: _sampleUnit),
      },
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 18',
        'title': 'Multi-Photo Upload Grid',
        'desc': 'Interactive image gallery with dashed photo picker, thumbnails, and multipart upload',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen18UploadPhotos(draft: _sampleDraft, unitData: _sampleUnit),
      },
      {
        'category': 'Phase 2: Units',
        'number': 'Screen 19',
        'title': 'Post-Unit Setup Hub',
        'desc': 'Configured unit cards inventory with edit/delete actions and [Add Final Details] button',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen19PostUnitHub(draft: _sampleDraft),
      },

      // Phase 2B: Event Venue Sub-Flow
      {
        'category': 'Phase 2B: Events',
        'number': 'Event 11',
        'title': 'Event Venue Types',
        'desc': 'Event category selectors (Weddings, Birthdays, Corporate, Social, etc.)',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostEventScreen11EventTypes(draft: _sampleDraft),
      },
      {
        'category': 'Phase 2B: Events',
        'number': 'Event 12',
        'title': 'Venue Spaces & Views',
        'desc': 'Multi-area spaces (Banquet Hall, Lawn, Dining) with Lake/Garden/City views',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostEventScreen12VenueDetails(draft: _sampleDraft, eventData: _sampleEventData),
      },
      {
        'category': 'Phase 2B: Events',
        'number': 'Event 13',
        'title': 'Capacity, Stage & Dining',
        'desc': 'Seated capacity, floating crowd, stage dimensions (LxW ft), and dining slots',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostEventScreen13CapacityStageDining(draft: _sampleDraft, eventData: _sampleEventData),
      },
      {
        'category': 'Phase 2B: Events',
        'number': 'Event 14',
        'title': 'Bridal, Groom & VIP Rooms',
        'desc': 'Green room facilities (attached bath, AC, full-length mirrors, wardrobes)',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostEventScreen14BridalRooms(draft: _sampleDraft, eventData: _sampleEventData),
      },

      // Phase 3: Verification & Publish (Screens 20 - 24)
      {
        'category': 'Phase 3: Publish',
        'number': 'Screen 20',
        'title': 'Invoicing Details',
        'desc': 'Invoice recipient legal name and billing address match toggle',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen20Invoicing(draft: _sampleDraft),
      },
      {
        'category': 'Phase 3: Publish',
        'number': 'Screen 21',
        'title': 'Entity KYC Verification',
        'desc': 'Individual vs Business Entity KYC with dynamic co-owners (>25% share) form',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen21Verification(draft: _sampleDraft),
      },
      {
        'category': 'Phase 3: Publish',
        'number': 'Screen 22',
        'title': 'GST & Tax Purpose',
        'desc': 'GST registered selector with 15-char GSTIN and 10-char PAN regex validation',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen22GstPurpose(draft: _sampleDraft),
      },
      {
        'category': 'Phase 3: Publish',
        'number': 'Screen 23',
        'title': 'Guest Payment & Payouts',
        'desc': 'Zaatra online checkout vs direct guest charging and Razorpay payout terms',
        'status': 'UI Ready',
        'statusColor': const Color(0xFF5E42C2),
        'builder': (context) => HostScreen23GuestPay(draft: _sampleDraft),
      },
      {
        'category': 'Phase 3: Publish',
        'number': 'Screen 24',
        'title': 'Legal Agreement & Publish',
        'desc': 'Business certification, Terms acceptance, publish API, and confetti celebration modal',
        'status': 'API Live',
        'statusColor': const Color(0xFF2E7D32),
        'builder': (context) => HostScreen24Registration(draft: _sampleDraft),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allScreens = _getAllScreens();
    final categories = ['All', 'Phase 0: Dashboard', 'Phase 1: Wizard', 'Phase 2: Units', 'Phase 2B: Events', 'Phase 3: Publish'];

    final filtered = allScreens.where((s) {
      final matchesFilter = _selectedFilter == 'All' || s['category'] == _selectedFilter;
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          s['number'].toString().toLowerCase().contains(query) ||
          s['title'].toString().toLowerCase().contains(query) ||
          s['desc'].toString().toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Host Screens Gallery (${allScreens.length})',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E1E24),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E24), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search screens by name, number, or feature...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFA0A0B2)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF5E42C2), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F4F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = cat);
                          },
                          selectedColor: const Color(0xFF5E42C2),
                          backgroundColor: const Color(0xFFF0F0F5),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B6B7F),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Screen List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _buildScreenCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E42C2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['number'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5E42C2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (item['statusColor'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item['statusColor'],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  final WidgetBuilder builder = item['builder'];
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: builder),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E42C2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['title'],
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['desc'],
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757585),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}