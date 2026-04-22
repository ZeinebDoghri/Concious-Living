import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
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
