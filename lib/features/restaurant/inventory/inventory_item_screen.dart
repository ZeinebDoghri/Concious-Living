import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';
import '../../../shared/widgets/freshness_badge.dart';
import '../../../shared/widgets/animated_button.dart';

// ── ORKA restaurant theme tokens ────────────────────────────────────────
const _rPrimary = Color(0xFF8FA84A);
const _rDeep = Color(0xFF5A7030);
const _rSurface = Color(0xFFF5F8EE);
const _rSoftBg = Color(0xFFE3E8D1);
const _rTextTitle = Color(0xFF26201B);
const _rTextBody = Color(0xFF5C4F48);
const _rTextMuted = Color(0xFF8C7E78);
const _warning = Color(0xFFFFAB5B);
const _danger = Color(0xFFFF7070);

class InventoryItemScreen extends StatefulWidget {
  final String id;

  const InventoryItemScreen({super.key, required this.id});

  @override
  State<InventoryItemScreen> createState() => _InventoryItemScreenState();
}

class _InventoryItemScreenState extends State<InventoryItemScreen> {
  Future<void> _pickExpiry(BuildContext context) async {
    final provider = context.read<InventoryProvider>();
    final it = provider.byId(widget.id);
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
              onSurface: Color(0xFF26201B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    await provider.updateExpiryDate(widget.id, picked);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.ok)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final it = provider.byId(widget.id);

    // ── Item not found ──────────────────────────────────────────────────────
    if (it == null) {
      return Scaffold(
        backgroundColor: _rSurface,
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => GoRouter.of(context).go('/restaurant/inventory')),
              Expanded(
                child: Center(
                  child: Text(
                    'Item not found',
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
    final imageBytes = it.imageBytes; // Uint8List? from base64

    return Scaffold(
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => GoRouter.of(context).go('/restaurant/inventory')),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      const SizedBox(height: 16),
                      _InfoTile(
                        label: AppStrings.quantity,
                        value:
                            '${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)} ${it.unit}',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(label: AppStrings.expiry, value: date),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.status,
                        value: FreshnessBadge.label(it.status),
                        valueColor: FreshnessBadge.textColor(it.status),
                      ),

                      const SizedBox(height: 20),

                    // ── Expiry date card ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _rPrimary.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _rPrimary.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                            Expanded(
                              child: AnimatedButton(
                                label: AppStrings.keep,
                                color: const Color(0xFF52C98A),
                                textColor: Colors.white,
                                onTap: () => provider.updateStatus(widget.id, 'fresh'),
                                height: 48,
                              ),
                            ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry date',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _rTextMuted,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                date,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _rTextTitle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Delete button ─────────────────────────────────────
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: InkWell(
                        onTap: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            useRootNavigator: true,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                'Remove item?',
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.w700,
                                  color: _rTextTitle,
                                ),
                              ),
                              content: Text(
                                'This product will be permanently deleted from your inventory.',
                                style: GoogleFonts.inter(
                                  color: _rTextBody,
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                        color: _rTextMuted),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text(
                                    'Remove',
                                    style: GoogleFonts.inter(
                                      color: _danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ) ?? false;

                          // ✅ Only proceed if user confirmed and widget still mounted
                          if (shouldDelete && mounted) {
                            try {
                              // Delete the item
                              await provider.removeItem(widget.id);
                              
                              // Only navigate if still mounted after deletion
                              if (mounted) {
                                // ✅ Try to pop, if it fails (empty stack), go back to inventory
                                try {
                                  GoRouter.of(context).pop();
                                } catch (e) {
                                  // If pop fails (empty stack on web), navigate to inventory
                                  if (mounted) {
                                    GoRouter.of(context).go('/restaurant/inventory');
                                  }
                                }
                              }
                            } catch (e) {
                              print('❌ Delete error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: _danger,
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
                            boxShadow: [
                              BoxShadow(
                                color: _danger.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Remove from inventory',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
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
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: _rDeep, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Inventory item',
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
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _rTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: valueColor ?? _rTextTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}