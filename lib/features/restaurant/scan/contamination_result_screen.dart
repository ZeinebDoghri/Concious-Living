import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../core/constants.dart';
import 'annotated_contamination_image.dart';
import 'food_contamination_service.dart';
import '../../../shared/widgets/olive_header.dart';
import '../../../shared/widgets/animated_button.dart';

class ContaminationResultScreen extends StatefulWidget {
  final ContaminationScanResultPayload payload;

  const ContaminationResultScreen({super.key, required this.payload});

  FoodAnalysisResult get result => payload.result;

  @override
  State<ContaminationResultScreen> createState() =>
      _ContaminationResultScreenState();
}

class _ContaminationResultScreenState extends State<ContaminationResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            const OliveHeader(
              title: 'Contamination Analysis',
              subtitle: 'Food safety insights',
              showBack: true,
              height: 140,
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
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Annotated image
                        AnnotatedContaminationImage(
                          imageBytes: widget.payload.imageBytes,
                          detections: widget.result.detections,
                        ),
                        const SizedBox(height: 20),

                        // Status Card
                        _buildStatusCard(),
                        const SizedBox(height: 20),

                        // Confidence Bars
                        _buildConfidenceBars(),
                        const SizedBox(height: 24),

                        // Detection Details
                        if (widget.result.detectionCount > 0)
                          _buildDetectionDetails(),

                        // YOLO Override Info
                        if (widget.result.yoloOverrode) ...[
                          const SizedBox(height: 16),
                          _buildYoloInfo(),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        AnimatedButton(
                          label: 'Scan Again',
                          color: widget.result.isContaminated
                              ? AppColors.cherry
                              : AppColors.olive,
                          textColor: Colors.white,
                          onTap: () async {
                            context.go(AppRoutes.restaurantContaminationScan);
                          },
                          height: 52,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              context.go(AppRoutes.restaurantDashboard),
                          child: const Text('Back to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isContaminated = widget.result.isContaminated;
    final bgColor = isContaminated
        ? const Color(0xFFFFF5F5)
        : const Color(0xFFF0FFF4);
    final borderColor = isContaminated
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFA7F3D0);
    final iconColor = isContaminated
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final statusEmoji = isContaminated ? '⚠️' : '✅';
    final statusText = isContaminated
        ? 'Contamination Detected'
        : 'Clean Food';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isContaminated
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                color: iconColor,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$statusEmoji $statusText',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${widget.result.confidence.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Breakdown',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 16),
        // Clean percentage bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clean',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cocoa,
                  ),
                ),
                Text(
                  '${widget.result.cleanPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearPercentIndicator(
                percent: (widget.result.cleanPct / 100).clamp(0.0, 1.0),
                progressColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFE8F3CC),
                lineHeight: 8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Contaminated percentage bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contaminated',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cocoa,
                  ),
                ),
                Text(
                  '${widget.result.contaminatedPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearPercentIndicator(
                percent: (widget.result.contaminatedPct / 100).clamp(0.0, 1.0),
                progressColor: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFFCA5A5),
                lineHeight: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetectionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Details',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.result.detections.length,
          itemBuilder: (context, index) {
            final detection = widget.result.detections[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cocoa,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Detected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYoloInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFF185FA5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Detected by visual scan (YOLO)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF185FA5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
