import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/cherry_header.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/risk_badge.dart';

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
    final y = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
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
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.scanHistory,
              subtitle: AppStrings.searchScans,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchScans,
                          prefixIcon:
                              const Icon(Icons.search, color: AppColors.cocoa),
                        ),
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 18, 24, 24),
                              child: EmptyState(
                                icon: Icons.history,
                                title: AppStrings.noScansYet,
                                subtitle: AppStrings.noScansSubtitle,
                                actionLabel: AppStrings.scanYourDish,
                                onAction: () => context.go(AppRoutes.customerScan),
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 4, 24, 24),
                              children: [
                                for (final entry in sections.entries) ...[
                                  if (entry.key.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 12, bottom: 8),
                                      child: Text(
                                        entry.key,
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.espresso,
                                          height: 1.2,
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
          color: AppColors.cherryBlush,
          borderRadius: BorderRadius.circular(AppRadii.innerCard),
          border: Border.all(color: AppColors.sand, width: 0.5),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.cherry),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.cherry.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
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
                        color: AppColors.espresso,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ScanHistoryItem.timeAgo(item.scannedAt),
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
        color: AppColors.oat,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: p.isEmpty
            ? const Icon(Icons.image_outlined, color: AppColors.cocoa)
            : Image.file(
                File(p),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const Icon(Icons.image_outlined, color: AppColors.cocoa);
                },
              ),
      ),
    );
  }
}
