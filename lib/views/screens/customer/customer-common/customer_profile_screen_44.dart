import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../authorization/login_screen_115.dart';
import '../customer-stay-updated/customer_my_bookings_screen_updated.dart';
import 'edit_profile_screen_45.dart';
import 'help_support_screen_48.dart';
import 'saved_favorites_screen_47.dart';
import 'saved_payment_methods_screen_46.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userLocation = '';
  String _userRole = 'Explorer';
  String _sinceYear = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await AuthService.getUserName(defaultFallback: '');
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        if (name.isNotEmpty && name != 'Customer') {
          _userName = name;
        }
        if (user != null) {
          if (user['email'] != null && user['email'].toString().isNotEmpty) {
            _userEmail = user['email'].toString();
          }
          if (user['phone'] != null && user['phone'].toString().isNotEmpty) {
            _userPhone = user['phone'].toString();
          }
          if (user['city'] != null && user['city'].toString().isNotEmpty) {
            _userLocation = '${user['city']}, Telangana';
          }
        }
      });
    }
  }

  void _showInfoModal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A4458), height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3AA8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedAddressesModal() {
    final addresses = [
      {'label': 'Home', 'addr': 'Plot 42, Hitech City, Madhapur, Hyderabad - 500081'},
      {'label': 'Work', 'addr': 'Cyber Towers, 4th Floor, Hitech City, Hyderabad - 500081'},
      {'label': 'Vacation Stay', 'addr': 'Sunset Villa, Baga Beach Road, North Goa - 403516'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...addresses.map((a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE7F6),
                    child: Icon(Icons.location_on_outlined, color: Color(0xFF5B3AA8)),
                  ),
                  title: Text(a['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(a['addr']!, style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                  trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF5B3AA8), size: 20),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add New Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3AA8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Zaatra account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Profile Banner matching 88246826.png
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // 2. Join Platform Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Join Platform'),
                  const SizedBox(height: 6),
                  _buildPlatformTile(
                    icon: Icons.villa_outlined,
                    title: 'Become as host',
                    subtitle: 'List your property on Zatra',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redirecting to Zaatra Host Onboarding...')),
                      );
                    },
                  ),
                  _buildPlatformTile(
                    icon: Icons.directions_car_outlined,
                    title: 'Become Driver',
                    subtitle: 'share your ride. Earn fuel shore',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redirecting to Zaatra Driver Partner Onboarding...')),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 3. 1. My Account Section
                  _buildSectionHeader('1. My Account'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      _loadProfileData();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavedPaymentMethodsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Saved addressed',
                    onTap: _showSavedAddressesModal,
                  ),
                  _buildMenuItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'My bookings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerMyBookingsScreenUpdated()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.rate_review_outlined,
                    title: 'My Reviews',
                    onTap: () {
                      _showInfoModal(
                        'My Reviews',
                        'You have submitted 4 property reviews and 1 driver rating.\n\n⭐ The Ocean View Resort - 4.8 / 5.0\n"Great hospitality and beachfront experience."\n\n⭐ Aranya Heritage Stay - 4.5 / 5.0\n"Peaceful getaway with wonderful local cuisine."',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Wishlist',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavedFavoritesScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 4. 2. Privacy Security Section
                  _buildSectionHeader('2. Privacy Security'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & security',
                    onTap: () {
                      _showInfoModal(
                        'Privacy & Security Settings',
                        'Zaatra protects your account with end-to-end security.\n\n• Two-Factor Authentication: Enabled\n• Biometric Login: Active\n• Last login: Today from Android app\n\nTo change your password or security PIN, visit Security Management.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification & Settings',
                    onTap: () {
                      _showInfoModal(
                        'Notification & Settings',
                        'Manage your communication preferences:\n\n✓ Booking Confirmations (Push & SMS)\n✓ Driver Arrival Alerts (Real-time Push)\n✓ Host Messages & Special Offers\n✓ Promotional Newsletters (Email)',
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 5. 3. Help & Support Section
                  _buildSectionHeader('3. Help & Support'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'FAQ\'s',
                    onTap: () {
                      _showInfoModal(
                        'Frequently Asked Questions',
                        '1. How do I cancel a stay booking?\nGo to My Bookings -> Select Booking -> Tap Cancel Booking.\n\n2. How do payments work?\nZaatra supports UPI, Credit/Debit cards, Net Banking, and Pay-at-Venue.\n\n3. Can I travel with domestic pets?\nYes, properties with the "Pets Allowed" badge welcome verified domestic pets.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.perm_phone_msg_outlined,
                    title: 'Contact US',
                    onTap: () {
                      _showInfoModal(
                        'Contact Zaatra Customer Care',
                        'We are here to assist 24/7:\n\n📞 Toll-Free Helpline: 1800-ZAATRA-00 (1800-922-872)\n✉️ Email Support: support@zaatra.com\n💬 WhatsApp Care: +91 91234 56789\n🏢 Headquarters: Hitech City, Hyderabad, Telangana',
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 6. 4. Policies Section
                  _buildSectionHeader('4. Policies'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      _showInfoModal(
                        'Terms & Conditions',
                        'By using Zaatra, you agree to our platform terms, guest conduct guidelines, and host service agreements. Reservations are binding contracts between registered guests and verified property hosts.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'Privacy policy',
                    onTap: () {
                      _showInfoModal(
                        'Privacy Policy',
                        'Zaatra is committed to safeguarding your personal data. We do not sell your personal data. Location data is only collected during active ride tracking or local stay recommendations.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.block_outlined,
                    title: 'Canceller Policy',
                    onTap: () {
                      _showInfoModal(
                        'Cancellation Policy',
                        'Free cancellation is available on eligible stays up to 48 hours prior to check-in. For rides, cancellations within 5 minutes of driver acceptance incur zero fee.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment_return_outlined,
                    title: 'Refund policy',
                    onTap: () {
                      _showInfoModal(
                        'Refund Policy',
                        'Eligible refunds are automatically credited back to your original payment method (UPI / Bank / Card) within 3 to 5 business days of cancellation approval.',
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 7. 5. About Zaatra Section
                  _buildSectionHeader('5. About Zaatra'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About zaatra',
                    onTap: () {
                      _showInfoModal(
                        'About Zaatra',
                        'Zaatra is India\'s premier unified travel and accommodation platform, connecting travelers with authentic heritage villas, boutique resorts, and reliable shared carpool rides.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.military_tech_outlined,
                    title: 'Rate Zaatra app',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Google Play Store rating page...')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.share_outlined,
                    title: 'Share app',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral link copied! Share with friends to earn ₹500 travel credits.')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.layers_outlined,
                    title: 'App version',
                    onTap: () {
                      _showInfoModal('App Version', 'Zaatra Mobile App\nVersion: 2.5.0 (Build 20261110)\nChannel: Production Release');
                    },
                  ),

                  const SizedBox(height: 24),

                  // 8. Logout Button matching 88246826.png
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: const Color(0xFFD32F2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Footer Version String matching 88246826.png
                  const Center(
                    child: Text(
                      'App Version 2.5.0',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w400),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Profile Header Widget matching 88246826.png
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF5B3AA8),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 76,
                  height: 76,
                  color: Colors.white.withValues(alpha: 0.15),
                  child: Image.asset(
                    'assets/images/image 27.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // User Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Explorer badge + since 2022
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _userRole,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ', $_sinceYear',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Text(
                      _userLocation,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Phone / Email Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, size: 12, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              _userPhone,
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ],
                        ),
                        const Text('/', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              _userEmail,
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Activity Stats Strip: 8 Stay, 3 Events, 1 Ride, 4.8 ★
          Row(
            children: [
              _buildStatPill('8 Stay'),
              const SizedBox(width: 8),
              _buildStatPill('3 Evenest'),
              const SizedBox(width: 8),
              _buildStatPill('1 Ride'),
              const SizedBox(width: 8),
              _buildStatPill('4.8 ★', isRating: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, {bool isRating = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.replaceAll(' ★', ''),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isRating ? const Color(0xFFFFD54F) : Colors.white,
              ),
            ),
            if (isRating) ...[
              const SizedBox(width: 3),
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD54F)),
            ],
          ],
        ),
      ),
    );
  }

  // Lavender Category Header Pill matching 88246826.png
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5B3AA8),
        ),
      ),
    );
  }

  // Platform Tile for Become Host / Driver matching 88246826.png
  Widget _buildPlatformTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFD6C8F2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$title $subtitle',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4458),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menu Item Row matching 88246826.png
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5A5364)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1B1E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF8C849B)),
          ],
        ),
      ),
    );
  }
}