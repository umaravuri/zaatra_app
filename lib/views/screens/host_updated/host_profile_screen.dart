import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/host_validators.dart';
import '../../../services/auth_service.dart';
import '../../../services/host_api_service.dart';
import '../authorization/login_screen_115.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

// Keep in sync with `version:` in pubspec.yaml.
const String _kAppVersion = '1.0.0';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kMuted = Color(0xFF757585);

/// Profile tab (Figma 1228744540): host header and the settings menu.
/// Figma: frame 1228744540 (node 1:4923)
class HostProfileScreen extends StatefulWidget {
  final String? userName;
  final VoidCallback onManageListings;

  const HostProfileScreen({super.key, this.userName, required this.onManageListings});

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final res = await HostApiService.getHostProfile();
    if (!mounted) return;
    if (res['success'] == true && res['profile'] is Map) {
      setState(() => _profile = Map<String, dynamic>.from(res['profile'] as Map));
    } else {
      setState(() => _error = res['message']?.toString() ?? 'Could not load your profile');
    }
  }

  void _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  void _comingSoon(String title) => _open(HostComingSoonScreen(title: title));

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Zaatra account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name']?.toString() ?? widget.userName ?? 'Host';
    final since = _profile?['hostSince']?.toString() ?? '';

    final items = <_MenuItem>[
      _MenuItem(Icons.person_outline_rounded, 'Personal Information',
          () => _open(HostPersonalInfoScreen(profile: _profile ?? const {}))),
      _MenuItem(Icons.home_work_outlined, 'Manage Listings', widget.onManageListings),
      _MenuItem(Icons.account_balance_outlined, 'Finance & Bank Account',
          () => _comingSoon('Finance & Bank Account')),
      _MenuItem(Icons.bar_chart_rounded, 'Reports & analytics',
          () => _comingSoon('Reports & analytics')),
      _MenuItem(Icons.local_offer_outlined, 'Promotions', () => _comingSoon('Promotions')),
      _MenuItem(Icons.lock_outline_rounded, 'Security settings',
          () => _comingSoon('Security settings')),
      _MenuItem(Icons.privacy_tip_outlined, 'Privacy policy', () => _comingSoon('Privacy policy')),
      _MenuItem(Icons.help_outline_rounded, 'Help & support', () => _comingSoon('Help & support')),
      _MenuItem(Icons.description_outlined, 'Terms & conditions',
          () => _comingSoon('Terms & conditions')),
      _MenuItem(Icons.notifications_none_rounded, 'Notification Preferences',
          () => _open(const HostNotificationPrefsScreen())),
      _MenuItem(Icons.settings_outlined, 'Settings', () => _comingSoon('Settings')),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEDE9FB),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'H',
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.w700, color: _kPurple),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w700, color: _kInk)),
                      if (since.isNotEmpty)
                        Text('Host since $since',
                            style: GoogleFonts.poppins(fontSize: 13, color: _kMuted)),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.redAccent)),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ],
            const SizedBox(height: 20),
            for (final item in items) _buildRow(item),
            _buildRow(_MenuItem(Icons.logout_rounded, 'Logout', _confirmLogout, danger: true)),
            const SizedBox(height: 16),
            Center(
              child: Text('App Version $_kAppVersion',
                  style: GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_MenuItem item) {
    final color = item.danger ? const Color(0xFFD32F2F) : _kInk;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: item.danger ? color : _kPurple, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.title,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w500, color: color)),
            ),
            if (!item.danger) const Icon(Icons.chevron_right_rounded, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _MenuItem(this.icon, this.title, this.onTap, {this.danger = false});
}

/// Personal Information: view and edit the host's name and email.
class HostPersonalInfoScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const HostPersonalInfoScreen({super.key, required this.profile});

  @override
  State<HostPersonalInfoScreen> createState() => _HostPersonalInfoScreenState();
}

class _HostPersonalInfoScreenState extends State<HostPersonalInfoScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile['name']?.toString() ?? '');
    _email = TextEditingController(text: widget.profile['email']?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error = HostValidators.required(_name.text, 'Name') ?? HostValidators.email(_email.text);
    if (error != null) return showHostError(context, error);

    setState(() => _saving = true);
    final res = await HostApiService.updateHostProfile(
      name: _name.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] != true) {
      return showHostError(context, res['message']?.toString() ?? 'Could not save changes');
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.profile['phone']?.toString() ?? '';
    return HostFormPage(
      title: 'Personal Information',
      buttonText: _saving ? 'Saving...' : 'Save Changes',
      onContinue: _saving ? () {} : _save,
      children: [
        const HostQuestion('Name', topSpace: 6),
        HostTextField(controller: _name, hint: 'Your name'),
        const HostQuestion('Email'),
        HostTextField(controller: _email, hint: 'you@example.com'),
        if (phone.isNotEmpty) ...[
          const HostQuestion('Mobile number'),
          Text(phone, style: GoogleFonts.poppins(fontSize: 15, color: _kMuted)),
          const SizedBox(height: 4),
          Text('Your mobile number is your login and cannot be changed here.',
              style: GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
        ],
      ],
    );
  }
}

/// Notification Preferences: toggles loaded and saved through the service.
class HostNotificationPrefsScreen extends StatefulWidget {
  const HostNotificationPrefsScreen({super.key});

  @override
  State<HostNotificationPrefsScreen> createState() => _HostNotificationPrefsScreenState();
}

class _HostNotificationPrefsScreenState extends State<HostNotificationPrefsScreen> {
  static const _labels = <String, String>{
    'newBookings': 'New bookings',
    'bookingRequests': 'Booking requests',
    'messages': 'Messages',
    'paymentUpdates': 'Payment updates',
    'promotions': 'Offers and promotions',
  };

  Map<String, bool>? _prefs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final res = await HostApiService.getNotificationPreferences();
    if (!mounted) return;
    if (res['success'] == true && res['preferences'] is Map) {
      setState(() => _prefs = (res['preferences'] as Map).map((k, v) => MapEntry('$k', v == true)));
    } else {
      setState(() => _error = res['message']?.toString() ?? 'Could not load preferences');
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final previous = _prefs![key] ?? false;
    setState(() => _prefs![key] = value);
    final res = await HostApiService.setNotificationPreferences({key: value});
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => _prefs![key] = previous);
      showHostError(context, res['message']?.toString() ?? 'Could not save preference');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HostTopBar(title: 'Notification Preferences', onBack: () => Navigator.pop(context)),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _prefs == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            for (final e in _labels.entries)
                              SwitchListTile(
                                activeThumbColor: _kPurple,
                                title: Text(e.value, style: GoogleFonts.poppins(fontSize: 15)),
                                value: _prefs![e.key] ?? false,
                                onChanged: (v) => _toggle(e.key, v),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown for profile pages that have no design yet.
class HostComingSoonScreen extends StatelessWidget {
  final String title;

  const HostComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HostTopBar(title: title, onBack: () => Navigator.pop(context)),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '$title is coming soon.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 15, color: _kMuted),
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

