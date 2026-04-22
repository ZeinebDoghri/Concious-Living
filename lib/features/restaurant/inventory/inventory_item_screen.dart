import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/freshness_badge.dart';
import '../../../shared/widgets/olive_header.dart';

class InventoryItemScreen extends StatelessWidget {
  final String id;

  const InventoryItemScreen({super.key, required this.id});

  Future<void> _pickExpiry(BuildContext context) async {
    final provider = context.read<InventoryProvider>();
    final it = provider.byId(id);
    if (it == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: it.expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.olive,
              onPrimary: AppColors.butter,
              surface: AppColors.parchment,
              onSurface: AppColors.espresso,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    await provider.updateExpiryDate(id, picked);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.ok)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final it = provider.byId(id);

    if (it == null) {
      return Scaffold(
        backgroundColor: AppColors.oat,
        body: SafeArea(
          child: Column(
            children: [
              OliveHeader(title: AppStrings.inventoryItem, showBack: true),
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.genericError,
                    style: GoogleFonts.inter(color: AppColors.cocoa),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final date = DateFormat('MMM d, y').format(it.expiryDate);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(title: AppStrings.inventoryItem, showBack: true),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.name,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FreshnessBadge(it.status),
                          const Spacer(),
                          Text(
                            AppStrings.expiresOn(date),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.cocoa,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoTile(
                        label: AppStrings.quantity,
                        value:
                            '${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)} ${it.unit}',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.expiry,
                        value: date,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.status,
                        value: FreshnessBadge.label(it.status),
                        valueColor: FreshnessBadge.textColor(it.status),
                      ),
                      const SizedBox(height: 14),
                      AnimatedButton(
                        label: AppStrings.updateExpiry,
                        color: AppColors.olive,
                        textColor: AppColors.butter,
                        onTap: () => _pickExpiry(context),
                        height: 52,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedButton(
                              label: AppStrings.keep,
                              color: AppColors.olive,
                              textColor: AppColors.butter,
                              onTap: () => provider.updateStatus(id, 'fresh'),
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedButton(
                              label: AppStrings.useToday,
                              color: AppColors.riskModerateText,
                              textColor: AppColors.butter,
                              onTap: () => provider.updateStatus(id, 'expiring'),
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedButton(
                        label: AppStrings.remove,
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: () async {
                          await provider.removeItem(id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cocoa,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.espresso,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
