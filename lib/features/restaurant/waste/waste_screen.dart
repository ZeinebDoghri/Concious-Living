import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../constants/tunisian_calendar.dart';
import '../../../services/weather_service.dart';
import '../../../services/ai_chat_service.dart';
import '../../../config/api_keys.dart';
import '../../../providers/user_provider.dart';

// ── Theme tokens ─────────────────────────────────────────────────────────────
const _warning = Color(0xFFFFAB5B);
const _danger = Color(0xFFFF7070);
const _fresh = Color(0xFF52C98A);

class WasteScreen extends StatefulWidget {
  final bool hotelMode;
  const WasteScreen({super.key, this.hotelMode = false});

  @override
  State<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends State<WasteScreen> {
  DateTime _viewDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  String? _aiPrediction;
  Map<String, dynamic>? _weather;

  // Colors based on mode
  Color get _primary => widget.hotelMode ? const Color(0xFFC4748A) : const Color(0xFF8FA84A);
  Color get _deep => widget.hotelMode ? const Color(0xFF9E5469) : const Color(0xFF5A7030);
  Color get _surface => widget.hotelMode ? const Color(0xFFFEFAFC) : const Color(0xFFF5F8EE);
  Color get _softBg => widget.hotelMode ? const Color(0xFFF9E9F2) : const Color(0xFFE3E8D1);
  Color get _textTitle => const Color(0xFF26201B);
  Color get _textBody => const Color(0xFF5C4F48);
  Color get _textMuted => const Color(0xFF8C7E78);

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    // Default coords for Tunis if user location not found
    double lat = 36.8065;
    double lng = 10.1815;

    final user = context.read<UserProvider>().currentUser;
    // Note: Real implementation would pull from user.location if available

    final w = await WeatherService.getTomorrowWeather(
      lat: lat,
      lng: lng,
      apiKey: openWeatherApiKey,
    );
    if (mounted) setState(() => _weather = w);
  }

  Future<void> _generateAIPrediction() async {
    setState(() => _isGenerating = true);

    final event = TunisianCalendar.getEventForDate(_selectedDate);
    final season = TunisianCalendar.getSeason(_selectedDate);
    final weekendBoost = TunisianCalendar.getWeekendMultiplier(_selectedDate);
    final dayName = DateFormat('EEEE').format(_selectedDate);

    final systemCtx = '''
You are WastePredict, a food waste reduction AI for ${widget.hotelMode ? 'hotels' : 'restaurants'}.
Analyze the following data and provide specific predictions and recommendations.
Respond in the same language the manager writes in.
Be specific with numbers. Reference the weather and event directly.
''';

    final userPrompt = '''
Restaurant/Hotel data: Current stock levels are normal. Previous waste was 15kg last week.
Target date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}
Day of week: $dayName (Multiplier: $weekendBoost)
Season: $season
Weather tomorrow: ${_weather?['description'] ?? 'Cloudy'}, ${_weather?['temp'] ?? 22}°C
Special event: ${event ?? "None"}

Based on ALL of these factors, predict:
1. Expected covers (number of guests)
2. Recommended order quantities for each ingredient category
3. Menu items to promote (use expiring stock first)
4. Estimated waste reduction vs last week (%)
''';

    final resp = await AIChatService.predictWaste(
      systemCtx: systemCtx,
      userPrompt: userPrompt,
    );

    if (mounted) {
      setState(() {
        _aiPrediction = resp;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_WasteItem>[
      _WasteItem(AppStrings.wasteItemLettuce, 12.5, _fresh),
      _WasteItem(AppStrings.wasteItemTomatoes, 9.1, _danger),
      _WasteItem(AppStrings.wasteItemBread, 6.4, _warning),
      _WasteItem(AppStrings.wasteItemChicken, 4.2, _deep),
    ];

    final total = items.fold<double>(0, (sum, it) => sum + it.kg);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textTitle, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.hotelMode
                  ? '/hotel/dashboard'
                  : '/restaurant/dashboard');
            }
          },
        ),
        title: Text(
          'WastePredict',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textTitle,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendarCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  _buildSelectionDetailCard(),
                  const SizedBox(height: 24),
                  _buildPredictionSection(),
                  const SizedBox(height: 24),
                  _buildLegacyWasteSection(items, total),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_viewDate),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textTitle,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Days Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Text(d, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted)))
                .toList(),
          ),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_viewDate.year, _viewDate.month, 1);
    final lastDay = DateTime(_viewDate.year, _viewDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startOffset = (firstDay.weekday - 1) % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final dayNum = index - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();

        final date = DateTime(_viewDate.year, _viewDate.month, dayNum);
        final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
        final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
        final isWeekend = date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
        final event = TunisianCalendar.getEventForDate(date);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _primary : (isWeekend ? const Color(0xFFFFF0F3) : Colors.transparent),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isToday ? _primary : _textTitle),
                  ),
                ),
                if (event != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: event.contains('Ramadan') ? Colors.amber : (event.contains('Eid') ? Colors.green : Colors.blue),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionDetailCard() {
    final event = TunisianCalendar.getEventForDate(_selectedDate);
    final isTomorrow = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
    final multiplier = TunisianCalendar.getWeekendMultiplier(_selectedDate);
    final boost = ((multiplier - 1.0) * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDate),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _textTitle),
              ),
            ],
          ),
          if (event != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(event, style: GoogleFonts.inter(fontSize: 14, color: _textBody)),
              ],
            ),
          ],
          if (isTomorrow && _weather != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _weather!['weather'] == 'Rain' ? Icons.cloudy_snowing : Icons.wb_sunny_rounded,
                  size: 18,
                  color: _primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_weather!['description']} (${(_weather!['temp'] ?? 0).toInt()}°C)',
                  style: GoogleFonts.inter(fontSize: 14, color: _textBody),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: _textMuted.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Predicted demand: ${boost > 0 ? "+$boost%" : "Standard"} vs average',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _textBody),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Waste Prediction',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: _textTitle),
            ),
            if (_aiPrediction != null)
              TextButton(
                onPressed: _generateAIPrediction,
                child: Text('Regenerate', style: TextStyle(color: _primary)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_aiPrediction == null)
          AnimatedButton(
            label: _isGenerating ? 'Analyzing Signals...' : 'Generate AI Forecast',
            color: _primary,
            isLoading: _isGenerating,
            onTap: _generateAIPrediction,
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _softBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _aiPrediction!,
              style: GoogleFonts.inter(fontSize: 14, color: _textBody, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget _buildLegacyWasteSection(List<_WasteItem> items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Waste Breakdown',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: _textTitle),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: items.map((it) => PieChartSectionData(value: it.kg, color: it.color, radius: 25, showTitle: false)).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: items.map((it) {
                    final pct = total <= 0 ? 0 : ((it.kg / total) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: it.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(it.name, style: GoogleFonts.inter(fontSize: 12, color: _textTitle))),
                          Text('$pct%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _textBody)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WasteItem {
  final String name;
  final double kg;
  final Color color;
  const _WasteItem(this.name, this.kg, this.color);
}
