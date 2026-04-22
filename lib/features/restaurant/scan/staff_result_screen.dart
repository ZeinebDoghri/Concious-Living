import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/models/waste_item_model.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/freshness_badge.dart';
import '../../../shared/widgets/olive_header.dart';

class StaffResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const StaffResultScreen({super.key, required this.args});

  @override
  State<StaffResultScreen> createState() => _StaffResultScreenState();
}

class _StaffResultScreenState extends State<StaffResultScreen> {
  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _scanMode() {
    final raw = widget.args['scanMode'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return 'freshness';
  }

  Map<String, dynamic> _result() {
    final raw = widget.args['result'];
    if (raw is Map<String, dynamic>) return raw;
    return <String, dynamic>{};
  }

  File? _imageFile() {
    final raw = widget.args['imageFile'];
    if (raw is File) return raw;

    final path = widget.args['imagePath'];
    if (path is String && path.trim().isNotEmpty) {
      return File(path);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mode = _scanMode();
    final result = _result();
    final imageFile = _imageFile();

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            const OliveHeader(
              title: 'Scan result',
              subtitle: null,
              showBack: true,
              height: 170,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageFile != null) ...[
                        Hero(
                          tag: 'scan_image',
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadii.screenCard),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Image.file(
                                imageFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (mode == 'freshness')
                        _FreshnessResult(
                          result: result,
                          onUpdateInventory: () async {
                            context.go(AppRoutes.restaurantInventory);
                          },
                          onLogRemoval: () async =>
                              _logRemovalFromInventory(result),
                        )
                      else if (mode == 'waste')
                        _WasteResult(
                          result: result,
                          onLogWaste: () async => _logWasteItems(result),
                          onViewWasteReport: () =>
                              context.go(AppRoutes.restaurantWaste),
                        )
                      else if (mode == 'compost')
                        _CompostResult(
                          result: result,
                          onLogWaste: () async => _logWaste(result),
                        )
                      else
                        _FreshnessResult(
                          result: result,
                          onUpdateInventory: () async {
                            context.go(AppRoutes.restaurantInventory);
                          },
                          onLogRemoval: () async =>
                              _logRemovalFromInventory(result),
                        ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Scan another item',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
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

  Future<void> _logWaste(Map<String, dynamic> result) async {
    final user = context.read<UserProvider>().currentUser;
    final venueId = user?.id ?? '';
    if (venueId.isEmpty) {
      _snack('Missing venue id.');
      return;
    }

    final isCompostable = (result['isCompostable'] as bool?) ?? false;
    final category = (result['category'] as String?)?.trim();

    final item = WasteItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: category?.isNotEmpty == true
          ? category!
          : (isCompostable ? 'Compostable item' : 'Non-compostable item'),
      quantityKg: 0.0,
      category: category ?? '',
      isCompostable: isCompostable,
      trend: 'up',
    );

    try {
      await FirebaseService.logWaste(venueId, item);
      if (!mounted) return;
      _snack(AppStrings.ok);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<void> _logRemovalFromInventory(Map<String, dynamic> result) async {
    final status = ((result['status'] as String?) ?? '').toLowerCase();
    if (status != 'spoiled') {
      _snack('Removal is only available for spoiled items.');
      return;
    }

    final inventory = context.read<InventoryProvider>();

    // Best-effort: remove the most urgent item (spoiled first, else expiring).
    final items = inventory.items;
    final candidate = items
        .where((e) => e.status == 'spoiled')
        .followedBy(items.where((e) => e.status == 'expiring'))
        .cast()
        .toList();

    if (candidate.isEmpty) {
      _snack('No inventory items available to remove.');
      return;
    }

    final id = candidate.first.id;

    try {
      await inventory.removeItem(id);
      if (!mounted) return;
      _snack('Removed from inventory');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<void> _logWasteItems(Map<String, dynamic> result) async {
    final user = context.read<UserProvider>().currentUser;
    final venueId = user?.id ?? '';
    if (venueId.isEmpty) {
      _snack('Missing venue id.');
      return;
    }

    final rawItems = result['detectedItems'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().toList()
        : const <Map>[];

    if (items.isEmpty) {
      _snack('No waste items detected.');
      return;
    }

    try {
      for (final entry in items) {
        final name = (entry['name'] as String?)?.trim() ?? 'Waste item';
        final quantityKg = (entry['quantityKg'] as num?)?.toDouble() ?? 0.0;

        await FirebaseService.logWaste(
          venueId,
          WasteItemModel(
            id: '${DateTime.now().millisecondsSinceEpoch}-$name',
            name: name,
            quantityKg: quantityKg,
            category: name,
            isCompostable: false,
            trend: 'up',
          ),
        );
      }

      if (!mounted) return;
      _snack('Waste logged');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }
}

class _FreshnessResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onUpdateInventory;
  final Future<void> Function()? onLogRemoval;

  const _FreshnessResult({
    required this.result,
    required this.onUpdateInventory,
    required this.onLogRemoval,
  });

  @override
  Widget build(BuildContext context) {
    final status = ((result['status'] as String?) ?? 'expiring').toLowerCase();
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final daysLeft = (result['daysLeft'] as num?)?.toInt();

    final isSpoiled = status == 'spoiled';
    final isExpiring = status == 'expiring';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Transform.scale(
            scale: 1.4,
            child: FreshnessBadge(status),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '${(confidence * 100).round()}% confidence',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cocoa,
            ),
          ),
        ),
        if (daysLeft != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              '$daysLeft day${daysLeft == 1 ? '' : 's'} left (estimate)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.cocoa,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (isSpoiled)
          _Banner(
            background: AppColors.cherryBlush,
            borderColor: AppColors.cherry,
            borderWidth: 2,
            text: 'Remove from stock immediately',
            textColor: AppColors.cherry,
          )
        else if (isExpiring)
          _Banner(
            background: AppColors.butter,
            borderColor: AppColors.sand,
            borderWidth: 1,
            text: daysLeft == null
                ? 'Use soon'
                : 'Use within $daysLeft day${daysLeft == 1 ? '' : 's'}',
            textColor: AppColors.riskModerateText,
          ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Update inventory',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onUpdateInventory,
          height: 52,
        ),
        if (isSpoiled) ...[
          const SizedBox(height: 10),
          AnimatedButton(
            label: 'Log removal',
            color: AppColors.cherry,
            textColor: AppColors.butter,
            onTap: onLogRemoval,
            height: 52,
          ),
        ],
      ],
    );
  }
}

class _WasteResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onLogWaste;
  final VoidCallback onViewWasteReport;

  const _WasteResult({
    required this.result,
    required this.onLogWaste,
    required this.onViewWasteReport,
  });

  List<Map<String, dynamic>> _detectedItems() {
    final raw = result['detectedItems'];
    if (raw is! List) return const <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map(
          (entry) => <String, dynamic>{
            'name': (entry['name'] as String?)?.trim() ?? 'Waste item',
            'quantityKg': (entry['quantityKg'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _detectedItems();
    final mostWasted = items.isEmpty
        ? <String, dynamic>{'name': 'Waste item', 'quantityKg': 0.0}
        : items.reduce(
            (a, b) => (a['quantityKg'] as double) >= (b['quantityKg'] as double)
                ? a
                : b,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.parchment,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            side: const BorderSide(color: AppColors.sand, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Waste detected',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(AppRadii.innerCard),
                border: Border.all(color: AppColors.sand, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: AppColors.cherry),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.espresso,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(item['quantityKg'] as double).toStringAsFixed(1)} kg',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.cocoa,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cherry,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most wasted item',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.butter,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mostWasted['name'] as String,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.butter,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(mostWasted['quantityKg'] as double).toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF5C0C2),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Log waste',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onLogWaste,
          height: 52,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onViewWasteReport,
          child: Text(
            'View waste report',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompostResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onLogWaste;

  const _CompostResult({
    required this.result,
    required this.onLogWaste,
  });

  @override
  Widget build(BuildContext context) {
    final isCompostable = (result['isCompostable'] as bool?) ?? false;
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;

    final badgeBg = isCompostable ? AppColors.oliveMist : AppColors.cherryBlush;
    final badgeText = isCompostable ? AppColors.olive : AppColors.cherry;

    final explanation = isCompostable
        ? 'This item can go in the compost bin.'
        : 'Dispose in general waste.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.sand, width: 0.5),
            ),
            child: Text(
              isCompostable ? 'Compostable' : 'Non-compostable',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: badgeText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '${(confidence * 100).round()}% confidence',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cocoa,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          explanation,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.cocoa,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Log to waste record',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onLogWaste,
          height: 52,
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color background;
  final Color borderColor;
  final double borderWidth;
  final String text;
  final Color textColor;

  const _Banner({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
