import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/alerts_provider.dart';
import '../../../shared/widgets/animated_button.dart';

// ── ORKA restaurant theme tokens ────────────────────────────────────────
const _rPrimary = Color(0xFF8FA84A);
const _rDeep = Color(0xFF5A7030);
const _rSurface = Color(0xFFF5F8EE);
const _rSoftBg = Color(0xFFE3E8D1);
const _rTextTitle = Color(0xFF26201B);
const _rTextBody = Color(0xFF5C4F48);
const _rTextMuted = Color(0xFF8C7E78);
const _fresh = Color(0xFF52C98A);
const _freshBg = Color(0xFFE8F9F1);
const _danger = Color(0xFFFF7070);
const _dangerBg = Color(0xFFFFEEEE);

class AlertDetailScreen extends StatelessWidget {
  final String id;

  const AlertDetailScreen({super.key, required this.id});

  Future<void> _resolve(BuildContext context) async {
    final ctx = context;
    final alertsProvider = ctx.read<AlertsProvider>();
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppStrings.markAsResolved,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _rTextTitle,
            ),
          ),
          content: Text(
            AppStrings.resolveAlertConfirm,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _rTextBody,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(false),
              child: Text(
                AppStrings.cancel,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: _rTextMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => dialogContext.pop(true),
              child: Text(
                AppStrings.confirm,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: _fresh,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!ctx.mounted || confirmed != true) return;
    alertsProvider.markResolved(id);

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(AppStrings.alertResolved),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () => alertsProvider.undoResolve(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final alert = provider.byId(id);

    if (alert == null) {
      return Scaffold(
        backgroundColor: _rSurface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, AppStrings.alertDetails),
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.alertNotFound,
                    style: GoogleFonts.inter(fontSize: 13, color: _rTextMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPending = alert.status == 'pending';

    return Scaffold(
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, AppStrings.alertDetails),
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
                      _InfoTile(label: AppStrings.dish, value: alert.dishName),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.customer,
                        value: alert.customerName,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.allergen,
                        value: alert.allergen,
                        valueColor: _danger,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.status,
                        value: isPending
                            ? AppStrings.pending
                            : AppStrings.resolved,
                        valueColor: isPending ? _danger : _fresh,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppStrings.recommendedNextSteps,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _rTextTitle,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Bullet(AppStrings.stepConfirmWithCustomer),
                      _Bullet(AppStrings.stepCheckIngredients),
                      _Bullet(AppStrings.stepSanitizeStation),
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: isPending
                            ? AppStrings.markAsResolved
                            : AppStrings.markedResolved,
                        color: isPending ? _rDeep : _rSoftBg,
                        textColor: isPending ? Colors.white : _rTextMuted,
                        onTap: isPending ? () => _resolve(context) : null,
                        height: 52,
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
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.restaurantAlerts),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rPrimary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: _rPrimary.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
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
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _rSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rPrimary.withValues(alpha: 0.2), width: 0.8),
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

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 16, color: _fresh),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _rTextBody,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
