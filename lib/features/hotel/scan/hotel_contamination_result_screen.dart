import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/role_contamination_result_view.dart';
import '../../../shared/widgets/role_scan_experience.dart';
import '../../restaurant/scan/annotated_contamination_image.dart';
import '../../restaurant/scan/food_contamination_service.dart';

class HotelContaminationResultScreen extends StatelessWidget {
  final ContaminationScanResultPayload payload;

  const HotelContaminationResultScreen({super.key, required this.payload});

  FoodAnalysisResult get result => payload.result;

  @override
  Widget build(BuildContext context) {
    return RoleContaminationResultView(
      role: ScanExperienceRole.hotel,
      title: result.isContaminated ? 'Guest Safety Review' : 'Product Cleared',
      subtitle: 'Hotel product analysis',
      preview: AnnotatedContaminationImage(
        imageBytes: payload.imageBytes,
        detections: result.detections,
      ),
      isContaminated: result.isContaminated,
      yoloOverrode: result.yoloOverrode,
      detectionCount: result.detectionCount,
      cleanPct: result.cleanPct,
      contaminatedPct: result.contaminatedPct,
      confidence: result.confidence,
      detections: result.detections.map((d) => d.label).toList(growable: false),
      onPrimary: () => context.go(AppRoutes.hotelDashboard),
      onScanAgain: () => context.go(AppRoutes.hotelContaminationScan),
      onBack: () => context.pop(),
    );
  }
}
