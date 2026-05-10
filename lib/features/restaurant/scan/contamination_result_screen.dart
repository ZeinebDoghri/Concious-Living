import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/role_contamination_result_view.dart';
import '../../../shared/widgets/role_scan_experience.dart';
import 'annotated_contamination_image.dart';
import 'food_contamination_service.dart';

class ContaminationResultScreen extends StatelessWidget {
  final ContaminationScanResultPayload payload;

  const ContaminationResultScreen({super.key, required this.payload});

  FoodAnalysisResult get result => payload.result;

  @override
  Widget build(BuildContext context) {
    return RoleContaminationResultView(
      role: ScanExperienceRole.restaurant,
      title: result.isContaminated ? 'Risk Detected' : 'Kitchen Analysis',
      subtitle: 'Restaurant food safety',
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
      onPrimary: () => context.go(AppRoutes.restaurantDashboard),
      onScanAgain: () => context.go(AppRoutes.restaurantContaminationScan),
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.restaurantDashboard),
    );
  }
}
