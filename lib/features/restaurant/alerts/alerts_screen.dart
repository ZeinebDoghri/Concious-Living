import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/alerts_provider.dart';
import '../../../shared/widgets/olive_header.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final items = provider.filterByStatus(_filter);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(
              title: AppStrings.alerts,
              subtitle: AppStrings.unresolvedCount(provider.pendingCount),
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
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: AppStrings.pending,
                            selected: _filter == 'pending',
                            onTap: () => setState(() => _filter = 'pending'),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: AppStrings.resolved,
                            selected: _filter == 'resolved',
                            onTap: () => setState(() => _filter = 'resolved'),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final a = items[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 250 + (index * 35)),
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
                                onTap: () =>
                                  context.go(AppRoutes.restaurantAlertDetail(a.id)),
                              borderRadius: BorderRadius.circular(AppRadii.innerCard),
                              splashColor: AppColors.olive.withValues(alpha: 0.12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.innerCard),
                                  border: Border.all(
                                      color: AppColors.sand, width: 0.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: a.status == 'pending'
                                            ? AppColors.cherryBlush
                                            : AppColors.oliveMist,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        a.status == 'pending'
                                            ? Icons.warning_amber_rounded
                                            : Icons.check,
                                        color: a.status == 'pending'
                                            ? AppColors.cherry
                                            : AppColors.olive,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.dishName,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.espresso,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            a.customerName,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.cocoa,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            AppStrings.containsAllergen(a.allergen),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.cherry,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: AppColors.cocoa),
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
