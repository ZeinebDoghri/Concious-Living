import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';
import '../../../shared/widgets/freshness_badge.dart';
import '../../../shared/widgets/olive_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Load expiry scan results from shared_preferences
  Future<List<Map<String, dynamic>>> _loadExpiryScanResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('expiry_scan_results') ?? '[]';
      final List<dynamic> results = jsonDecode(jsonString);
      return results.cast<Map<String, dynamic>>().toList().reversed.toList();
    } catch (e) {
      debugPrint('Error loading expiry scan results: $e');
      return [];
    }
  }

  // Parse expiry date and calculate days until expiry
  Map<String, dynamic> _parseExpiryStatus(String expiryDateStr, String statusFromApi) {
    try {
      // Parse date string (format: "15/06/2025")
      final parts = expiryDateStr.split('/');
      if (parts.length != 3) return {'status': statusFromApi, 'daysUntil': 0, 'daysText': expiryDateStr};

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final expiryDate = DateTime(year, month, day);
      final today = DateTime.now();
      final difference = expiryDate.difference(today).inDays;

      String statusText = statusFromApi;
      if (difference < 0) {
        statusText = 'EXPIRED';
      } else if (difference <= 30) {
        statusText = 'EXPIRING SOON';
      } else if (statusFromApi == 'VALID') {
        statusText = 'VALID';
      }

      String daysText;
      if (difference < 0) {
        daysText = 'Expired ${(-difference)} day${(-difference) != 1 ? 's' : ''} ago';
      } else if (difference == 0) {
        daysText = 'Expires today';
      } else {
        daysText = 'Expires in $difference day${difference != 1 ? 's' : ''}';
      }

      return {
        'status': statusText,
        'daysUntil': difference,
        'daysText': daysText,
      };
    } catch (e) {
      return {'status': statusFromApi, 'daysUntil': 0, 'daysText': expiryDateStr};
    }
  }

  // Load freshness scan results from shared_preferences
  Future<List<Map<String, dynamic>>> _loadFreshnessResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('freshness_scan_results') ?? '[]';
      final List<dynamic> results = jsonDecode(jsonString);
      return results.cast<Map<String, dynamic>>().toList().reversed.toList();
    } catch (e) {
      debugPrint('Error loading freshness results: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final items = provider.filteredItems(query: _search.text, filter: _filter);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(
              title: AppStrings.inventory,
              subtitle: AppStrings.itemsNeedAttentionCount(provider.needsAttentionCount),
              showBack: false,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchInventory,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            borderSide: BorderSide(color: AppColors.sand.withValues(alpha: 0.8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            borderSide: BorderSide(color: AppColors.sand.withValues(alpha: 0.8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            borderSide: const BorderSide(color: AppColors.olive, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: AppStrings.all,
                            selected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: AppStrings.fresh,
                            selected: _filter == 'fresh',
                            onTap: () => setState(() => _filter = 'fresh'),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: AppStrings.expiringSoon,
                            selected: _filter == 'expiring',
                            onTap: () => setState(() => _filter = 'expiring'),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: AppStrings.spoiled,
                            selected: _filter == 'spoiled',
                            onTap: () => setState(() => _filter = 'spoiled'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
                        future: Future.wait([
                          _loadExpiryScanResults(),
                          _loadFreshnessResults(),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final expiryResults = snapshot.data![0];
                          final freshnessResults = snapshot.data![1];

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                            children: [
                              // Not Fresh Products Section - Only show when 'fresh' filter is selected
                              if (_filter == 'fresh') ...[
                                if (freshnessResults.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Not Fresh Products',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.espresso,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE74C3C),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${freshnessResults.length} item${freshnessResults.length != 1 ? 's' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ...List.generate(freshnessResults.length, (index) {
                                    final result = freshnessResults[index];
                                    final imageBytes = base64Decode(result['image'] ?? '');
                                    final confidence = (result['confidence'] ?? 0).toDouble();
                                    final scannedAt = result['scanned_at'] ?? '';

                                    // Parse scanned date
                                    DateTime? parsedDate;
                                    try {
                                      parsedDate = DateTime.parse(scannedAt);
                                    } catch (e) {
                                      parsedDate = null;
                                    }

                                    final dateText = parsedDate != null
                                        ? DateFormat('MMM d, yyyy HH:mm').format(parsedDate)
                                        : 'Date unknown';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF5F5),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Product Image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: SizedBox(
                                                width: 80,
                                                height: 80,
                                                child: Image.memory(
                                                  imageBytes,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Product Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Status Badge
                                                  SizedBox(
                                                    height: 24,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE74C3C),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        'NOT FRESH',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Confidence
                                                  Text(
                                                    'Confidence: ${confidence.toStringAsFixed(1)}%',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.espresso,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  // Scanned Date
                                                  Text(
                                                    'Scanned: $dateText',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: AppColors.cocoa,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          size: 48,
                                          color: Colors.green.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'All products are fresh!',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cocoa,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Great job keeping quality high',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.fog,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ],

                              // Expiring Soon Section Header
                              if (_filter == 'expiring')
                                if (expiryResults.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_rounded, color: Color(0xFFE74C3C), size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expiring Soon',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.espresso,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE74C3C),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${expiryResults.length} item${expiryResults.length != 1 ? 's' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                ] else ...[
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 48,
                                          color: Colors.green.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No expiring products',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cocoa,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'All products are in good condition',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.fog,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],

                              // Expiring Soon Cards
                              if (_filter == 'expiring' && expiryResults.isNotEmpty)
                                ...List.generate(expiryResults.length, (index) {
                                  final result = expiryResults[index];
                                  final imageBytes = base64Decode(result['image'] ?? '');
                                  final expiryDate = result['expiry_date'] ?? 'N/A';
                                  final statusFromApi = result['status'] ?? 'UNKNOWN';

                                  final statusInfo = _parseExpiryStatus(expiryDate, statusFromApi);
                                  final status = statusInfo['status'];
                                  final daysText = statusInfo['daysText'];

                                  final isExpired = status == 'EXPIRED';
                                  final isExpiringSoon = status == 'EXPIRING SOON';

                                  final cardBgColor = isExpired
                                      ? const Color(0xFFFFF5F5)
                                      : isExpiringSoon
                                          ? const Color(0xFFFFF8F0)
                                          : Colors.white;

                                  final statusBgColor = isExpired
                                      ? const Color(0xFFE74C3C)
                                      : isExpiringSoon
                                          ? const Color(0xFFF39C12)
                                          : const Color(0xFF27AE60);

                                  final statusTextColor = Colors.white;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Product Image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: Image.memory(
                                                imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Product Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Status Badge
                                                SizedBox(
                                                  height: 24,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusBgColor,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: statusTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Expiry Date
                                                Text(
                                                  expiryDate,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.espresso,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                // Days Text
                                                Text(
                                                  daysText,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.cocoa,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              // Inventory Items Section
                              if (_filter != 'expiring' || items.isNotEmpty) ...[
                                if (_filter == 'expiring' && expiryResults.isNotEmpty)
                                  const SizedBox(height: 20),
                                ...List.generate(items.length, (index) {
                                  final it = items[index];
                                  final date = DateFormat('MMM d').format(it.expiryDate);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 240 + (index * 35)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, child) {
                                      return Opacity(
                                        opacity: v,
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - v) * 10),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      onTap: () => context.go(AppRoutes.restaurantInventoryItem(it.id)),
                                      borderRadius: BorderRadius.circular(AppRadii.innerCard),
                                      splashColor: AppColors.olive.withValues(alpha: 0.12),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.parchment,
                                          borderRadius: BorderRadius.circular(AppRadii.innerCard),
                                          border: Border.all(color: AppColors.sand, width: 0.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    it.name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.espresso,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)} ${it.unit} · ${AppStrings.expiresOn(date)}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: AppColors.cocoa,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            FreshnessBadge(it.status),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.chevron_right, color: AppColors.cocoa),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      splashColor: AppColors.olive.withValues(alpha: 0.12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.sand, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.butter : AppColors.cocoa,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
