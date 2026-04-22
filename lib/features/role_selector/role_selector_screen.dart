import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectRole({
    required String venueType,
    required String route,
  }) async {
    if (_pendingRoute != null) return;

    final venueProvider = context.read<VenueTypeProvider>();
    if (venueType.isEmpty) {
      await venueProvider.clear();
    } else {
      await venueProvider.setVenueType(venueType);
    }
    if (!mounted) return;

    _pendingRoute = route;

    await _fadeController.reverse(from: 1.0);
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(color: AppColors.cherry),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 56,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.appNameUpper,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 26,
                                color: AppColors.cherryHeaderText,
                                letterSpacing: 2.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.taglineLong,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.cherryBlush,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                _Dot(color: AppColors.cherryBlush),
                                SizedBox(width: 10),
                                _Dot(color: AppColors.oliveMist),
                                SizedBox(width: 10),
                                _Dot(color: AppColors.butter),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.whoAreYou,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cherry,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.chooseRole,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.cocoa,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _RoleCard(
                        color: AppColors.cherry,
                        title: AppStrings.iAmCustomer,
                        subtitle: AppStrings.customerCardSubtitle,
                        subtitleColor: AppColors.cherryBlush,
                        icon: Icons.local_dining,
                        onTap: () => _selectRole(
                          venueType: '',
                          route: AppRoutes.customerLogin,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        color: AppColors.olive,
                        title: AppStrings.iAmRestaurant,
                        subtitle: AppStrings.restaurantCardSubtitle,
                        subtitleColor: AppColors.oliveMist,
                        icon: Icons.restaurant,
                        onTap: () => _selectRole(
                          venueType: 'restaurant',
                          route: AppRoutes.restaurantLogin,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        color: AppColors.butter,
                        title: AppStrings.iAmHotel,
                        subtitle: AppStrings.hotelCardSubtitle,
                        subtitleColor: AppColors.cherry,
                        icon: Icons.hotel,
                        isLightCard: true,
                        onTap: () => _selectRole(
                          venueType: 'hotel',
                          route: AppRoutes.hotelLogin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLightCard;

  const _RoleCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.onTap,
    this.isLightCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.screenCard),
        splashColor: AppColors.butter.withValues(alpha: 0.2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.screenCard),
            border: isLightCard
                ? Border.all(color: AppColors.sand, width: 0.8)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 18,
                        color: isLightCard ? AppColors.cherry : AppColors.cherryHeaderText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isLightCard
                      ? AppColors.cherryBlush
                      : AppColors.butter.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 28,
                  color: isLightCard ? AppColors.cherry : AppColors.cherryHeaderText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
