import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/alerts_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/olive_header.dart';

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
          backgroundColor: AppColors.parchment,
          title: Text(
            AppStrings.markAsResolved,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
          content: Text(
            AppStrings.resolveAlertConfirm,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.cocoa,
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
                  color: AppColors.cocoa,
                ),
              ),
            ),
            TextButton(
              onPressed: () => dialogContext.pop(true),
              child: Text(
                AppStrings.confirm,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
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
        backgroundColor: AppColors.oat,
        body: SafeArea(
          child: Column(
            children: [
              OliveHeader(title: AppStrings.alertDetails, showBack: true),
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.alertNotFound,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.cocoa,
                    ),
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
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(title: AppStrings.alertDetails, showBack: true),
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
                      _InfoTile(
                        label: AppStrings.dish,
                        value: alert.dishName,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.customer,
                        value: alert.customerName,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.allergen,
                        value: alert.allergen,
                        valueColor: AppColors.cherry,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        label: AppStrings.status,
                        value: isPending
                            ? AppStrings.pending
                            : AppStrings.resolved,
                        valueColor: isPending
                            ? AppColors.cherry
                            : AppColors.olive,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppStrings.recommendedNextSteps,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
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
                        color: isPending ? AppColors.olive : AppColors.sand,
                        textColor: isPending ? AppColors.butter : AppColors.cocoa,
                        onTap: isPending ? () => _resolve(context) : null,
                        height: 52,
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
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline,
                size: 16, color: AppColors.olive),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.cocoa,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
