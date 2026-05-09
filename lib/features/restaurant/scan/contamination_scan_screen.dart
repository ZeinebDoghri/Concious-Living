import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/contamination_provider.dart';
import '../../../shared/widgets/role_scan_experience.dart';
import 'food_contamination_service.dart';

class ContaminationScanScreen extends StatefulWidget {
  const ContaminationScanScreen({super.key});

  @override
  State<ContaminationScanScreen> createState() =>
      _ContaminationScanScreenState();
}

class _ContaminationScanScreenState extends State<ContaminationScanScreen> {
  final _picker = ImagePicker();
  XFile? _lastFile;

  Future<void> _pick(ImageSource source) async {
    final provider = context.read<ContaminationProvider>();
    if (provider.isLoading) return;

    HapticFeedback.mediumImpact();

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1440,
      );
      if (file == null || !mounted) return;

      setState(() => _lastFile = file);
      final imageBytes = await file.readAsBytes();

      await provider.analyze(imageBytes);
      if (!mounted) return;

      if (provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
        return;
      }

      if (provider.result != null) {
        context.push(
          AppRoutes.restaurantContaminationResult,
          extra: ContaminationScanResultPayload(
            result: provider.result!,
            imageBytes: imageBytes,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContaminationProvider>(
      builder: (context, provider, child) => RoleScanExperience(
        role: ScanExperienceRole.restaurant,
        title: 'Kitchen Label Scan',
        subtitle: 'Food contamination and service safety',
        hint: 'Scanning label...',
        liveTitle: _lastFile == null ? 'Waiting for dish' : 'Dish captured',
        liveSubtitle: _lastFile == null
            ? 'Food category appears after capture'
            : 'Kitchen analysis is running',
        imagePath: _lastFile?.path,
        isLoading: provider.isLoading,
        onBack: () => context.pop(),
        onCameraTap: () => _pick(ImageSource.camera),
        onGalleryTap: () => _pick(ImageSource.gallery),
        onInfoTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan food to detect contamination and insects.'),
            ),
          );
        },
      ),
    );
  }
}
