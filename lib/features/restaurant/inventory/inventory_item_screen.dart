import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/freshness_badge.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary   = Color(0xFFF2A7A7);
const _rDeep      = Color(0xFFE47878);
const _rSurface   = Color(0xFFFFF5F5);
const _rSoftBg    = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody  = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _warning    = Color(0xFFFFAB5B);
const _danger     = Color(0xFFFF7070);

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
              primary: _rDeep,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF3D1515),
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

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_rSoftBg, _rSurface],
        ),
        border: Border(
          bottom: BorderSide(color: _rPrimary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rPrimary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: _rDeep, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _rTextTitle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final it = provider.byId(id);

    if (it == null) {
      return Scaffold(
        backgroundColor: _rSurface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, AppStrings.inventoryItem),
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.genericError,
                    style: GoogleFonts.inter(color: _rTextMuted),
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
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, AppStrings.inventoryItem),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _rTextTitle,
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
                              color: _rTextMuted,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: AppStrings.updateExpiry,
                        color: _rDeep,
                        textColor: Colors.white,
                        onTap: () => _pickExpiry(context),
                        height: 52,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedButton(
                              label: AppStrings.keep,
                              color: const Color(0xFF52C98A),
                              textColor: Colors.white,
                              onTap: () =>
                                  provider.updateStatus(id, 'fresh'),
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedButton(
                              label: AppStrings.useToday,
                              color: _warning,
                              textColor: Colors.white,
                              onTap: () =>
                                  provider.updateStatus(id, 'expiring'),
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedButton(
                        label: AppStrings.remove,
                        color: _danger,
                        textColor: Colors.white,
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
            ),
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
        color: _rSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _rPrimary.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _rTextMuted,
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
                color: valueColor ?? _rTextTitle,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
