import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/contamination_provider.dart';
import '../../../shared/widgets/role_scan_experience.dart';
import '../../restaurant/scan/food_contamination_service.dart';

class HotelContaminationScanScreen extends StatefulWidget {
  const HotelContaminationScanScreen({super.key});

  @override
  State<HotelContaminationScanScreen> createState() =>
      _HotelContaminationScanScreenState();
}

class _HotelContaminationScanScreenState
    extends State<HotelContaminationScanScreen> {
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
          AppRoutes.hotelContaminationResult,
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
        role: ScanExperienceRole.hotel,
        title: 'Hotel Food Scan',
        subtitle: 'Guest-safe product identification',
        hint: 'Identifying product...',
        liveTitle: 'Conscious Living Hotel',
        liveSubtitle: _lastFile == null
            ? 'Minibar, buffet, and spa items'
            : 'Product category captured',
        imagePath: _lastFile?.path,
        isLoading: provider.isLoading,
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(AppRoutes.hotelDashboard),
        onCameraTap: () => _pick(ImageSource.camera),
        onGalleryTap: () => _pick(ImageSource.gallery),
        onInfoTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Scan a food item before recommending it to guests.',
              ),
            ),
          );
        },
      ),
    );
  }
}
