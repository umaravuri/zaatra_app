import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../customer/customer-stay/customer_home_screen_38.dart';

class BecomeHostScreen extends StatelessWidget {
  final String? phoneNumber;
  final bool isExistingHost;

  const BecomeHostScreen({
    super.key,
    this.phoneNumber,
    this.isExistingHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isExistingHost ? 'Host Portal' : 'Host Registration',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDF7),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 3),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isExistingHost ? 'Welcome Back, Host!' : 'Become a Zaatra Host',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isExistingHost
                    ? 'Your host account is active. Manage your listings and reservations with ease.'
                    : 'List your property, welcome travelers from everywhere, and earn reliable income with Zaatra.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E5EE)),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.verified_user_rounded,
                      title: 'Verified Guests',
                      desc: 'All travelers on Zaatra are verified with government ID & phone.',
                    ),
                    const Divider(height: 24, color: Color(0xFFE8E5EE)),
                    _buildFeatureRow(
                      icon: Icons.payments_rounded,
                      title: 'Instant Payouts',
                      desc: 'Direct bank deposits for every completed stay with zero hidden cuts.',
                    ),
                    const Divider(height: 24, color: Color(0xFFE8E5EE)),
                    _buildFeatureRow(
                      icon: Icons.support_agent_rounded,
                      title: '24/7 Host Support',
                      desc: 'Dedicated concierge team available around the clock to support you.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isExistingHost
                              ? 'Entering Host Dashboard...'
                              : 'Host onboarding profile initiated for ${phoneNumber ?? "user"}.',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: AppRoutes.customerHome),
                        builder: (context) => const CustomerHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isExistingHost ? 'Go to Host Dashboard' : 'Get Started as Host',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
