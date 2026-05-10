import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/models/scan_result.dart';

class CompostIngestionService {
  static Future<void> onScanComplete(ScanResult scan) async {
    final entityId = scan.entityId;
    final deptId = scan.departmentId;
    final date = DateFormat('yyyy-MM-dd').format(scan.timestamp);
    final week = _isoWeek(scan.timestamp);
    final month = DateFormat('yyyy-MM').format(scan.timestamp);

    final compostableKg =
        scan.waste.estimatedWasteKg * scan.waste.compostableRatio;
    final co2Saved = compostableKg * 0.5;
    final treesEquiv = co2Saved / 21;
    final waterSavedL = compostableKg * 6;

    final batch = FirebaseFirestore.instance.batch();

    final wasteRef = FirebaseFirestore.instance
        .collection('waste_logs')
        .doc(entityId)
        .collection('daily')
        .doc(date);
    batch.set(wasteRef, {
      'waste_kg': FieldValue.increment(scan.waste.estimatedWasteKg),
      'compostable_kg': FieldValue.increment(compostableKg),
      'compost_kg': FieldValue.increment(compostableKg),
      'co2_saved': FieldValue.increment(co2Saved),
      'items_scanned': FieldValue.increment(1),
      'scan_ids': FieldValue.arrayUnion([scan.id]),
      if (deptId != null)
        'dept_${deptId}_compostable_kg': FieldValue.increment(compostableKg),
    }, SetOptions(merge: true));

    final weeklyWasteRef = FirebaseFirestore.instance
        .collection('waste_logs')
        .doc(entityId)
        .collection('weekly')
        .doc(week);
    batch.set(weeklyWasteRef, {
      'waste_kg': FieldValue.increment(scan.waste.estimatedWasteKg),
      'compost_kg': FieldValue.increment(compostableKg),
      'compostable_kg': FieldValue.increment(compostableKg),
      'co2_saved': FieldValue.increment(co2Saved),
      'items_scanned': FieldValue.increment(1),
      'scan_ids': FieldValue.arrayUnion([scan.id]),
      if (deptId != null)
        'dept_${deptId}_compostable_kg': FieldValue.increment(compostableKg),
    }, SetOptions(merge: true));

    for (final period in [
      ('daily', date),
      ('weekly', week),
      ('monthly', month),
    ]) {
      final ref = FirebaseFirestore.instance
          .collection('compost_totals')
          .doc(entityId)
          .collection(period.$1)
          .doc(period.$2);
      batch.set(ref, {
        'compostable_kg': FieldValue.increment(compostableKg),
        'waste_kg': FieldValue.increment(scan.waste.estimatedWasteKg),
        'co2_saved': FieldValue.increment(co2Saved),
        'trees_equiv': FieldValue.increment(treesEquiv),
        'water_saved_L': FieldValue.increment(waterSavedL),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  static String _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 + (thursday.difference(firstThursday).inDays / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }
}
