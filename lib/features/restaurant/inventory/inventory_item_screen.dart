import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';

const _rPrimary   = Color(0xFFF2A7A7);
const _rDeep      = Color(0xFFE47878);
const _rSurface   = Color(0xFFFFF5F5);
const _rSoftBg    = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody  = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _danger     = Color(0xFFFF7070);

class InventoryItemScreen extends StatefulWidget {
  final String id;

  const InventoryItemScreen({super.key, required this.id});

  @override
  State<InventoryItemScreen> createState() => _InventoryItemScreenState();
}

class _InventoryItemScreenState extends State<InventoryItemScreen> {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Product image ─────────────────────────────────────
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: _rSoftBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _rPrimary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _rPrimary.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: imageBytes != null
                            ? Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 56,
                                    color: _rPrimary.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No image',
                                    style: GoogleFonts.inter(
                                      color: _rTextMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _rSoftBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: _rDeep,
                              size: 20,
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
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 16),
      decoration: BoxDecoration(
        color: _rSoftBg,
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
                border:
                    Border.all(color: _rPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: _rDeep, size: 16),
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