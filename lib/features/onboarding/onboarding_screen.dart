import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../shared/widgets/animated_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _index = 0;

  final _pages = const [
    _OnboardingPageData(
      bg: AppColors.cherry,
      emoji: '🍃',
      emojiColor: AppColors.parchment,
      title: 'Scan your dish',
      body:
          'Take a photo of any meal. Our AI instantly estimates cholesterol, sodium, sugar and saturated fat.',
    ),
    _OnboardingPageData(
      bg: AppColors.olive,
      emoji: '❤️',
      emojiColor: AppColors.parchment,
      title: 'Track your health',
      body:
          'Monitor daily nutrient intake and receive alerts when nutrients approach your personal limits.',
    ),
    _OnboardingPageData(
      bg: AppColors.butter,
      emoji: '♻️',
      emojiColor: AppColors.cherry,
      title: 'Fight food waste',
      body:
          'Help restaurants identify waste patterns and contribute to a more sustainable food system.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(() {
      final newIndex = (_controller.page ?? 0).round().clamp(0, _pages.length - 1);
      if (newIndex != _index) {
        setState(() => _index = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.seenOnboarding, true);
    if (!mounted) return;
    context.go(AppRoutes.roleSelector);
  }

  Future<void> _next() async {
    if (_index == _pages.length - 1) {
      await _complete();
      return;
    }

    await _controller.animateToPage(
      _index + 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, i) {
                final data = _pages[i];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final page = _controller.hasClients ? (_controller.page ?? _index.toDouble()) : _index.toDouble();
                    final delta = (page - i);
                    final parallax = -delta * 24 * 0.5;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(parallax, 0),
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: data.bg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.sand, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                data.emoji,
                                style: TextStyle(
                                  fontSize: 72,
                                  color: data.emojiColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cherry,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.body,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.cocoa,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            Positioned(
              right: 16,
              top: 8,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  AppStrings.skip,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cocoa,
                    height: 1.2,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 10,
                        width: active ? 24 : 10,
                        decoration: BoxDecoration(
                          color: active ? AppColors.cherry : AppColors.sand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  AnimatedButton(
                    label: _index == _pages.length - 1
                        ? AppStrings.getStarted
                        : AppStrings.next,
                    icon: _index == _pages.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: AppColors.cherry,
                    textColor: AppColors.butter,
                    onTap: _next,
                    height: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final Color bg;
  final String emoji;
  final Color emojiColor;
  final String title;
  final String body;

  const _OnboardingPageData({
    required this.bg,
    required this.emoji,
    required this.emojiColor,
    required this.title,
    required this.body,
  });
}
