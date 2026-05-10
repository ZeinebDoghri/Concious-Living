import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../services/auth_service.dart';

const _kBg = Color(0xFFFFF0F3);
const _kCustomer = Color(0xFFC4748A);
const _kRestaurant = Color(0xFF5C7A3E);
const _kHotel = Color(0xFF4A7FA5);
const _kText = Color(0xFF26201B);
const _kMuted = Color(0xFF6B5A60);

class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  Future<void> _chooseRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go(AppRoutes.roleSelector);
      return;
    }

    await AuthService.ensureUserDocument(user, role);
    if (!context.mounted) return;

    if (role == 'customer') {
      context.go(AppRoutes.customerProfileSetup, extra: {'fromGoogle': true});
    } else if (role == 'restaurant') {
      context.go(AppRoutes.restaurantSetup, extra: {'fromGoogle': true});
    } else if (role == 'hotel') {
      context.go(AppRoutes.hotelSetup, extra: {'fromGoogle': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              'Welcome to FreshGuard - I am a...',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            const SizedBox(height: 24),
            _RoleChoiceCard(
              color: _kCustomer,
              icon: Icons.person_rounded,
              title: 'Customer',
              description: 'Track nutrition, allergens, and daily limits.',
              onTap: () => _chooseRole(context, 'customer'),
            ),
            const SizedBox(height: 14),
            _RoleChoiceCard(
              color: _kRestaurant,
              icon: Icons.restaurant_rounded,
              title: 'Restaurant',
              description: 'Monitor kitchen scans, waste, and alerts.',
              onTap: () => _chooseRole(context, 'restaurant'),
            ),
            const SizedBox(height: 14),
            _RoleChoiceCard(
              color: _kHotel,
              icon: Icons.hotel_rounded,
              title: 'Hotel',
              description: 'Coordinate food safety across hotel departments.',
              onTap: () => _chooseRole(context, 'hotel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleChoiceCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.35,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
