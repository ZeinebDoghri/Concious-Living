import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/olive_header.dart';

class CompostScreen extends StatelessWidget {
  const CompostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compostable = <String>[
      AppStrings.compostableFruitVeg,
      AppStrings.compostableCoffee,
      AppStrings.compostableEggshells,
      AppStrings.compostablePaper,
    ];

    final nonCompostable = <String>[
      AppStrings.nonCompostablePlastic,
      AppStrings.nonCompostableGlass,
      AppStrings.nonCompostableMetal,
      AppStrings.nonCompostableOil,
    ];

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(
              title: AppStrings.compostClassification,
              subtitle: AppStrings.whatsCompostable,
              showBack: true,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.whatsCompostable,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...compostable.map((t) => _Bullet(text: t, ok: true)),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.nonCompostableItems,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...nonCompostable.map((t) => _Bullet(text: t, ok: false)),
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: AppStrings.takeAction,
                        color: AppColors.olive,
                        textColor: AppColors.butter,
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.ok)),
                          );
                        },
                        height: 52,
                      ),
                      const SizedBox(height: 10),
                      AnimatedButton(
                        label: AppStrings.wasteReportTitle,
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: () async =>
                            context.go(AppRoutes.restaurantWaste),
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
}

class _Bullet extends StatelessWidget {
  final String text;
  final bool ok;

  const _Bullet({required this.text, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              ok ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 16,
              color: ok ? AppColors.olive : AppColors.cherry,
            ),
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
