import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/alert_model.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/venue_type_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  int? _touchedBarIndex;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _serviceLabel(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 18) return 'Snack';
    return 'Dinner';
  }

  Color _venueColor(bool isHotel) => isHotel ? AppColors.cherry : AppColors.olive;

  Color _venueTint(bool isHotel) => isHotel ? const Color(0xFFF5C0C2) : const Color(0xFFD4E8A8);

  String _formatVenueTitle(UserProvider userProvider, bool isHotel) {
    final user = userProvider.currentUser;
    final name = isHotel ? user?.hotelName : user?.restaurantName;
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? AppStrings.appName : trimmed;
  }

  String _formatVenueSubtitle(UserProvider userProvider, bool isHotel) {
    final user = userProvider.currentUser;
    if (isHotel) {
      final category = (user?.hotelType ?? '').trim();
      final rooms = user?.rooms ?? 0;
      final categoryText = category.isEmpty ? 'Hotel' : category;
      return '$categoryText · $rooms rooms';
    }

    final cuisine = (user?.cuisineType ?? '').trim();
    final covers = user?.covers ?? 0;
    final cuisineText = cuisine.isEmpty ? 'Restaurant' : cuisine;
    return '$cuisineText · $covers covers';
  }

  int _hotelOutletsCount(UserProvider userProvider) {
    final rooms = userProvider.currentUser?.rooms ?? 0;
    if (rooms <= 0) return 1;
    return max(1, (rooms / 10).round());
  }

  int _expiringSoonCount(InventoryProvider inventoryProvider) {
    return inventoryProvider.items.where((item) => item.isExpiringSoon).length;
  }

  int _wasteEstimateKg({
    required int alertsCount,
    required int expiringSoonCount,
    required int scanCount,
  }) {
    return max(1, (alertsCount * 2 + expiringSoonCount * 3 + max(2, scanCount ~/ 2)));
  }

  double _freshnessScore({
    required int alertsCount,
    required int expiringSoonCount,
  }) {
    final deductions = min(24, alertsCount * 3 + expiringSoonCount * 2);
    return (100 - deductions).clamp(0, 100).toDouble();
  }

  double _roomServiceOrders(UserProvider userProvider, ScanHistoryProvider scanProvider) {
    final rooms = userProvider.currentUser?.rooms ?? 0;
    final seed = rooms > 0 ? rooms / 12 : 4;
    final scans = scanProvider.items.length / 4;
    return max(1, (seed + scans).round()).toDouble();
  }

  List<_TipData> _restaurantTips() {
    return const [
      _TipData(
        title: 'Log waste before the rush ends',
        body: 'FIFO storage works best when the team records waste as soon as it appears.',
      ),
      _TipData(
        title: 'Label allergens at prep time',
        body: 'A quick label on the station prevents cross-contact when service gets busy.',
      ),
      _TipData(
        title: 'Keep portions consistent',
        body: 'When portions are predictable, your scans are easier to compare and your waste drops.',
      ),
      _TipData(
        title: 'Check temperatures twice',
        body: 'Cold items and hot holding both stay safer when the team verifies them on schedule.',
      ),
      _TipData(
        title: 'Use the first-in, first-out shelf',
        body: 'Pull the older stock forward so it moves through service before it expires.',
      ),
      _TipData(
        title: 'Keep hands and surfaces ready',
        body: 'A short hygiene reset between batches prevents mistakes when orders stack up.',
      ),
    ];
  }

  List<_TipData> _hotelTips() {
    return const [
      _TipData(
        title: 'Time room service around peaks',
        body: 'Batch deliveries so hot food reaches guests quickly and stays within safe temperature range.',
      ),
      _TipData(
        title: 'Confirm allergy notes early',
        body: 'A quick guest check-in on dietary needs saves time and avoids awkward remakes later.',
      ),
      _TipData(
        title: 'Refresh buffet items in small batches',
        body: 'Smaller replenishments keep food looking fresh while reducing end-of-service waste.',
      ),
      _TipData(
        title: 'Separate shared prep surfaces',
        body: 'Cross-contamination is easier to avoid when tools and trays are grouped by use.',
      ),
      _TipData(
        title: 'Label room-service allergens clearly',
        body: 'Visible labeling keeps housekeeping and kitchen teams aligned when orders move fast.',
      ),
      _TipData(
        title: 'Keep guest requests visible',
        body: 'A simple handoff note reduces missed instructions and keeps service personal.',
      ),
    ];
  }

  List<double> _wasteSeries({
    required int alertsCount,
    required int expiringSoonCount,
    required int scanCount,
    required bool isHotel,
  }) {
    final base = max(4, alertsCount + expiringSoonCount + max(2, scanCount ~/ 3));
    return List<double>.generate(5, (index) {
      final wobble = isHotel ? [1, -1, 2, 0, 1][index] : [0, 2, -1, 1, -1][index];
      return max(2, base + index + wobble).toDouble();
    });
  }

  String _topWasteLabel(bool isHotel) => isHotel ? 'Buffet' : 'Bread';

  List<AlertModel> _sortedAlerts(AlertsProvider alertsProvider) {
    final items = alertsProvider.alerts.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: Consumer<VenueTypeProvider>(
        builder: (context, venueProvider, _) {
          final isHotel = venueProvider.venueType == 'hotel';
          final venueColor = _venueColor(isHotel);
          final venueTint = _venueTint(isHotel);
          final alertsProvider = context.watch<AlertsProvider>();
          final inventoryProvider = context.watch<InventoryProvider>();
          final userProvider = context.watch<UserProvider>();
          final scanProvider = context.watch<ScanHistoryProvider>();
          final user = userProvider.currentUser;

          final venueName = _formatVenueTitle(userProvider, isHotel);
          final venueSubtitle = _formatVenueSubtitle(userProvider, isHotel);
          final now = DateTime.now();
          final greeting = _greetingForHour(now.hour);
          final serviceChip = _serviceLabel(now);

          final pendingAlerts = alertsProvider.pendingCount;
          final expiringSoonCount = _expiringSoonCount(inventoryProvider);
          final scanCount = scanProvider.items.length;
          final wasteKg = _wasteEstimateKg(
            alertsCount: pendingAlerts,
            expiringSoonCount: expiringSoonCount,
            scanCount: scanCount,
          );
          final freshnessScore = _freshnessScore(
            alertsCount: pendingAlerts,
            expiringSoonCount: expiringSoonCount,
          ).round();
          final roomServiceOrders = _roomServiceOrders(userProvider, scanProvider).round();
          final outletsCount = _hotelOutletsCount(userProvider);
          final wasteSeries = _wasteSeries(
            alertsCount: pendingAlerts,
            expiringSoonCount: expiringSoonCount,
            scanCount: scanCount,
            isHotel: isHotel,
          );
          final alertsSorted = _sortedAlerts(alertsProvider);
          final recentAlerts = alertsSorted.take(3).toList(growable: false);
          final inventoryAlertCount = expiringSoonCount;
          final tipData = isHotel ? _hotelTips() : _restaurantTips();
          final tip = tipData[now.day % tipData.length];
          final topWasteLabel = _topWasteLabel(isHotel);

          final headerStats = isHotel
              ? <String>[
                  '🚨 $pendingAlerts alerts',
                  '🛎 $outletsCount outlets',
                  '♻ ${wasteKg}kg waste',
                ]
              : <String>[
                  '🚨 $pendingAlerts alerts',
                  '📦 $expiringSoonCount expiring',
                  '♻ ${wasteKg}kg waste',
                ];

          final performanceTiles = <_KpiTileData>[
            _KpiTileData(
              value: '$pendingAlerts',
              label: 'Allergen alerts',
              valueColor: AppColors.cherry,
              trendColor: AppColors.cherry,
              trendText: '↑ ${max(1, pendingAlerts)} active',
              trendArrow: '↑',
            ),
            _KpiTileData(
              value: isHotel ? '$roomServiceOrders' : '$expiringSoonCount',
              label: isHotel ? 'Room service orders' : 'Expiring soon',
              valueColor: const Color(0xFF7A5E00),
              trendColor: AppColors.cherry,
              trendText: isHotel ? '↑ Guest requests' : '↑ Check soon',
              trendArrow: '↑',
            ),
            _KpiTileData(
              value: '$wasteKg kg',
              label: 'Waste today',
              valueColor: AppColors.olive,
              trendColor: AppColors.olive,
              trendText: '↓ ${max(1, 8 - min(5, pendingAlerts))}% vs last week',
              trendArrow: '↓',
            ),
            _KpiTileData(
              value: '$freshnessScore%',
              label: 'Freshness score',
              valueColor: AppColors.olive,
              trendColor: AppColors.olive,
              trendText: freshnessScore >= 90 ? '↓ Stable' : '↓ Improving',
              trendArrow: '↓',
            ),
          ];

          final activeAlertBanner = pendingAlerts > 0;
          final inventoryWarningVisible = inventoryAlertCount > 0;
          final activeIcon = isHotel ? Icons.apartment : Icons.restaurant;
          final activeHeaderColor = venueColor;
          final statTextColor = venueTint;
          final detailSubtitle = venueSubtitle;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Container(
                    color: activeHeaderColor,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: statTextColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venueName,
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.butter,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    detailSubtitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: statTextColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.butter.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      serviceChip,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.butter,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: headerStats
                                        .map(
                                          (stat) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.butter.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              stat,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.butter,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.butter.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.butter.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: _VenueAvatar(
                                  user: user,
                                  isHotel: isHotel,
                                  fallbackIcon: activeIcon,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        title: ' ',
                        actionLabel: ' ',
                        actionColor: AppColors.olive,
                        onTap: () => context.go(AppRoutes.restaurantWaste),
                        topPadding: 0,
                      ),
                      _CardShell(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Today\'s performance',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.espresso,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.restaurantWaste),
                                  child: Text(
                                    'Full report',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.olive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.0,
                              children: [
                                for (final tile in performanceTiles)
                                  _KpiTile(data: tile),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (activeAlertBanner)
                        _ActiveAlertsBanner(
                          count: pendingAlerts,
                          onTap: () => context.go(AppRoutes.restaurantAlerts),
                        ),
                      _SectionTitle(
                        title: 'Quick actions',
                        actionLabel: null,
                        onTap: null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.notifications_active_outlined,
                                iconColor: AppColors.cherry,
                                label: 'Alerts',
                                onTap: () => context.go(AppRoutes.restaurantAlerts),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.inventory_2_outlined,
                                iconColor: const Color(0xFF7A5E00),
                                label: isHotel ? 'Inventory' : 'Inventory',
                                onTap: () => context.go(AppRoutes.restaurantInventory),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.delete_outline,
                                iconColor: AppColors.olive,
                                label: 'Waste',
                                onTap: () => context.go(AppRoutes.restaurantWaste),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.document_scanner_outlined,
                                iconColor: AppColors.olive,
                                label: 'Scan food item',
                                subtitle: 'Freshness · Compost check',
                                onTap: () => context.go(AppRoutes.restaurantScan),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SectionTitle(
                        title: '',
                        actionLabel: ' ',
                        actionColor: AppColors.olive,
                        onTap: () => context.go(AppRoutes.restaurantWaste),
                      ),
                      _CardShell(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Waste this week',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.espresso,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.restaurantWaste),
                                  child: Text(
                                    'Full report',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.olive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: _WasteChart(
                                values: wasteSeries,
                                onTouchIndexChanged: (index) {
                                  setState(() => _touchedBarIndex = index);
                                },
                                touchedIndex: _touchedBarIndex,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniPill(
                                    text: '↓ 8% vs last week',
                                    background: AppColors.oliveMist,
                                    color: AppColors.olive,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _MiniPill(
                                    text: '$topWasteLabel — top waste',
                                    background: AppColors.cherryBlush,
                                    color: AppColors.cherry,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (inventoryWarningVisible)
                        _InventoryAlertCard(
                          count: inventoryAlertCount,
                          onTap: () => context.go(AppRoutes.restaurantInventory),
                        ),
                      _SectionTitle(
                        title: "Today's tip",
                        actionLabel: null,
                        onTap: null,
                      ),
                      _TipCard(
                        title: tip.title,
                        body: tip.body,
                        chipText: 'Tip',
                      ),
                      _SectionTitle(
                        title: 'Recent alerts',
                        actionLabel: 'See all',
                        actionColor: AppColors.cherry,
                        onTap: () => context.go(AppRoutes.restaurantAlerts),
                      ),
                      if (recentAlerts.isEmpty)
                        _CardShell(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'No recent alerts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.cocoa,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: List.generate(recentAlerts.length, (index) {
                            final alert = recentAlerts[index];
                            return _StaggerIn(
                              controller: _enterController,
                              index: index,
                              child: _RecentAlertCard(
                                alert: alert,
                                onTap: () => context.go(AppRoutes.restaurantAlertDetail(alert.id)),
                              ),
                            );
                          }),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VenueAvatar extends StatelessWidget {
  final dynamic user;
  final bool isHotel;
  final IconData fallbackIcon;

  const _VenueAvatar({
    required this.user,
    required this.isHotel,
    required this.fallbackIcon,
  });

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final second = parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return (first + second).trim();
  }

  @override
  Widget build(BuildContext context) {
    final logo = (user?.avatarPath ?? '').toString().trim();
    final venueName = isHotel ? (user?.hotelName ?? '').toString() : (user?.restaurantName ?? '').toString();
    final initials = _initials(venueName);

    if (logo.isNotEmpty) {
      return Image.network(
        logo,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            color: AppColors.butter.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.butter,
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      color: AppColors.butter.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.butter,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Color? actionColor;
  final double topPadding;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onTap,
    this.actionColor,
    this.topPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
          ),
          if (actionLabel != null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: actionColor ?? AppColors.cherry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _CardShell({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: child,
    );
  }
}

class _KpiTileData {
  final String value;
  final String label;
  final Color valueColor;
  final Color trendColor;
  final String trendArrow;
  final String trendText;

  const _KpiTileData({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.trendColor,
    required this.trendArrow,
    required this.trendText,
  });
}

class _KpiTile extends StatelessWidget {
  final _KpiTileData data;

  const _KpiTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.value,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: data.valueColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.cocoa,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.trendArrow,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: data.trendColor,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data.trendText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: data.trendColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertsBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ActiveAlertsBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cherryBlush,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.cherry, width: 4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.cherry, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count allergen alert${count == 1 ? '' : 's'} need attention',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cherry,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to review and resolve',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.cherryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.cherry),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sand, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.oliveMist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.cocoa,
                height: 1.15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.fog,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WasteChart extends StatelessWidget {
  final List<double> values;
  final ValueChanged<int?> onTouchIndexChanged;
  final int? touchedIndex;

  const _WasteChart({
    required this.values,
    required this.onTouchIndexChanged,
    required this.touchedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 10.0 : values.reduce(max) + 2;

    return BarChart(
      BarChartData(
        maxY: maxValue,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.oatDeep,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: 16,
                borderRadius: BorderRadius.circular(6),
                color: AppColors.cherry,
              ),
            ],
          );
        }).toList(growable: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} kg',
                GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.parchment,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            final touched = response?.spot?.touchedBarGroupIndex;
            onTouchIndexChanged(touched);
          },
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;

  const _MiniPill({
    required this.text,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InventoryAlertCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _InventoryAlertCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.butter,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFF7A5E00), width: 4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFF7A5E00), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count items expiring within 3 days',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A5E00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check inventory to prevent spoilage',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7A5E00),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7A5E00)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipData {
  final String title;
  final String body;

  const _TipData({required this.title, required this.body});
}

class _TipCard extends StatelessWidget {
  final String title;
  final String body;
  final String chipText;

  const _TipCard({
    required this.title,
    required this.body,
    required this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oliveMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.olive,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.butter, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cherryBlush,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chipText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cocoa,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _RecentAlertCard({required this.alert, required this.onTap});

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    String firstChar(String value) {
      final text = value.trim();
      if (text.isEmpty) return '';
      return text.substring(0, 1).toUpperCase();
    }

    final first = firstChar(parts.first);
    final second = parts.length > 1 ? firstChar(parts[1]) : '';
    return (first + second).trim();
  }

  Color _statusColor() => alert.status == 'resolved' ? AppColors.olive : AppColors.cherry;

  String _statusText() => alert.status == 'resolved' ? 'Resolved' : 'Pending';

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor,
                child: Text(
                  _initials(alert.customerName),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.butter,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⚠ ${alert.allergen} detected in ${alert.dishName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.cherry,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(alert.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.fog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(text: _statusText(), color: statusColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerIn({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.06 * index).clamp(0.0, 0.8);
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    final offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
