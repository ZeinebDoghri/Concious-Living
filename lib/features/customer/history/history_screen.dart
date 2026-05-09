import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/risk_badge.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFA78BFA);
const _kSurface = Color(0xFFF5F3FF);
const _kSoftBg = Color(0xFFEDE9FE);
const _kTextTitle = Color(0xFF2D1B69);
const _kTextMuted = Color(0xFF8B7BC0);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snackUndo(ScanHistoryItem removed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.remove),
        action: SnackBarAction(
          label: AppStrings.keep,
          onPressed: () {
            context.read<ScanHistoryProvider>().restoreScan(removed);
          },
        ),
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isYesterday(DateTime dt) {
    final now = DateTime.now();
    final y = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    return dt.year == y.year && dt.month == y.month && dt.day == y.day;
  }

  bool _isThisWeek(DateTime dt) {
    final now = DateTime.now();
    return now.difference(dt).inDays <= 7;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanHistoryProvider>();
    final items = provider.filteredItems(_query);

    Map<String, List<ScanHistoryItem>> grouped() {
      final Map<String, List<ScanHistoryItem>> map = {
        AppStrings.today: <ScanHistoryItem>[],
        AppStrings.yesterday: <ScanHistoryItem>[],
        AppStrings.thisWeek: <ScanHistoryItem>[],
      };

      for (final it in items) {
        if (_isToday(it.scannedAt)) {
          map[AppStrings.today]!.add(it);
        } else if (_isYesterday(it.scannedAt)) {
          map[AppStrings.yesterday]!.add(it);
        } else if (_isThisWeek(it.scannedAt)) {
          map[AppStrings.thisWeek]!.add(it);
        } else {
          map.putIfAbsent('', () => <ScanHistoryItem>[]).add(it);
        }
      }

      map.removeWhere((k, v) => v.isEmpty);
      return map;
    }

    final sections = grouped();

    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.scanHistory,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.searchScans,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(fontSize: 14, color: _kTextTitle),
                decoration: InputDecoration(
                  hintText: AppStrings.searchScans,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: _kTextMuted,
                  ),
                  prefixIcon: Icon(Icons.search, color: _kPrimary),
                  filled: true,
                  fillColor: _kSoftBg,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
              ),
            ),

            Expanded(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: EmptyState(
                        icon: Icons.history,
                        title: AppStrings.noScansYet,
                        subtitle: AppStrings.noScansSubtitle,
                        actionLabel: AppStrings.scanYourDish,
                        onAction: () => context.go(AppRoutes.customerScan),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final entry in sections.entries) ...[
                          if (entry.key.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextTitle,
                                ),
                              ),
                            ),
                          ...entry.value.map((it) {
                            return _HistoryRow(
                              item: it,
                              onTap: () => context.go(
                                AppRoutes.customerHistoryDetail(it.id),
                              ),
                              onDelete: () async {
                                final removed = await context
                                    .read<ScanHistoryProvider>()
                                    .removeScan(it.id);
                                if (removed != null && mounted) {
                                  _snackUndo(removed);
                                }
                              },
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _HistoryRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF7070).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.innerCard),
          border: Border.all(
            color: const Color(0xFFFF7070).withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF7070)),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        splashColor: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            boxShadow: AppShadows.sm(_kPrimary),
          ),
          child: Row(
            children: [
              _Thumb(path: item.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextTitle,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ScanHistoryItem.timeAgo(item.scannedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _kTextMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RiskBadge(item.result.overallRisk),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? path;

  const _Thumb({required this.path});

  @override
  Widget build(BuildContext context) {
    final p = (path ?? '').trim();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _kSoftBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: p.isEmpty || kIsWeb
            ? Icon(Icons.image_outlined, color: _kTextMuted)
            : Image.file(
                File(p),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Icon(Icons.image_outlined, color: _kTextMuted);
                },
              ),
      ),
    );
  }
}
