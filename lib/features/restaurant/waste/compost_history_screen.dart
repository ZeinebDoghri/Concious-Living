import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

class CompostHistoryScreen extends StatefulWidget {
  final bool hotelMode;

  const CompostHistoryScreen({super.key, this.hotelMode = false});

  @override
  State<CompostHistoryScreen> createState() => _CompostHistoryScreenState();
}

class _CompostHistoryScreenState extends State<CompostHistoryScreen> {
  String _range = 'weekly';

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().currentUser?.id ?? '';
    final accent = widget.hotelMode
        ? const Color(0xFF4A7FA5)
        : const Color(0xFF5C7A3E);
    final bg = widget.hotelMode
        ? const Color(0xFFF0F7FB)
        : const Color(0xFFF2FAF0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(
                  widget.hotelMode
                      ? AppRoutes.hotelDashboard
                      : AppRoutes.restaurantCompost,
                ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Compost history'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Week',
                        selected: _range == 'weekly',
                        accent: accent,
                        onTap: () => setState(() => _range = 'weekly'),
                      ),
                      const SizedBox(width: 10),
                      _Chip(
                        label: 'Month',
                        selected: _range == 'monthly',
                        accent: accent,
                        onTap: () => setState(() => _range = 'monthly'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('compost_totals')
                        .doc(uid)
                        .collection(_range)
                        .orderBy(FieldPath.documentId, descending: true)
                        .limit(30)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No compost records yet',
                            style: GoogleFonts.inter(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          return _HistoryTile(
                            date: doc.id,
                            compostKg:
                                (data['compostable_kg'] as num?)?.toDouble() ??
                                0,
                            wasteKg:
                                (data['waste_kg'] as num?)?.toDouble() ?? 0,
                            co2: (data['co2_saved'] as num?)?.toDouble() ?? 0,
                            accent: accent,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : accent,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String date;
  final double compostKg;
  final double wasteKg;
  final double co2;
  final Color accent;

  const _HistoryTile({
    required this.date,
    required this.compostKg,
    required this.wasteKg,
    required this.co2,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco_outlined, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3A5A25),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${compostKg.toStringAsFixed(1)} kg compostes · ${wasteKg.toStringAsFixed(1)} kg waste · ${co2.toStringAsFixed(1)} kg CO2',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
