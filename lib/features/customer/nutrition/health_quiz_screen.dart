import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';

class HealthQuizScreen extends StatefulWidget {
  const HealthQuizScreen({super.key});

  @override
  State<HealthQuizScreen> createState() => _HealthQuizScreenState();
}

class _HealthQuizScreenState extends State<HealthQuizScreen> {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;

  // Quiz State
  String? _selectedGoal;
  String? _selectedActivity;
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _selectedGender = 'Male';
  List<String> _selectedPreferences = [];

  bool _isSaving = false;

  // Computed results
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;
  double _water = 0.0;
  double _bmi = 0.0;

  final List<Map<String, dynamic>> _goals = [
    {'id': 'build_muscle', 'label': 'Build muscle', 'emoji': '🏋️'},
    {'id': 'lose_weight', 'label': 'Lose weight', 'emoji': '🔥'},
    {'id': 'maintain_weight', 'label': 'Maintain weight', 'emoji': '⚖️'},
    {'id': 'improve_health', 'label': 'Improve health', 'emoji': '❤️'},
    {'id': 'eat_better', 'label': 'Eat better', 'emoji': '🍽️'},
  ];

  final List<Map<String, dynamic>> _activities = [
    {'id': 'sedentary', 'label': 'Sedentary', 'sub': 'office job, little exercise', 'mult': 1.2, 'emoji': ' Couch Potato'},
    {'id': 'light', 'label': 'Lightly active', 'sub': '1–3 days/week', 'mult': 1.375, 'emoji': '🚶'},
    {'id': 'moderate', 'label': 'Moderately active', 'sub': '3–5 days/week', 'mult': 1.55, 'emoji': '🏃'},
    {'id': 'very', 'label': 'Very active', 'sub': '6–7 days/week', 'mult': 1.725, 'emoji': '💪'},
    {'id': 'athlete', 'label': 'Athlete', 'sub': '2× per day training', 'mult': 1.9, 'emoji': '🏆'},
  ];

  final List<String> _dietaryOptions = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free',
    'Halal', 'Keto', 'Intermittent fasting', 'No restrictions'
  ];

  void _next() {
    if (_currentStep < 4) {
      if (_currentStep == 3) {
        _calculateResults();
      }
      _pageCtrl.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
      setState(() => _currentStep++);
    }
  }

  void _calculateResults() {
    final weight = double.tryParse(_weightCtrl.text) ?? 70;
    final height = double.tryParse(_heightCtrl.text) ?? 170;
    final age = int.tryParse(_ageCtrl.text) ?? 25;

    // BMR
    double bmr;
    if (_selectedGender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // TDEE
    final activity = _activities.firstWhere((a) => a['id'] == _selectedActivity, orElse: () => _activities[0]);
    final tdee = bmr * (activity['mult'] as double);

    // Calories
    if (_selectedGoal == 'lose_weight') {
      _calories = (tdee - 500).round();
    } else if (_selectedGoal == 'build_muscle') {
      _calories = (tdee + 300).round();
    } else {
      _calories = tdee.round();
    }

    // Macros
    final proteinPct = _selectedGoal == 'build_muscle' ? 0.35 : 0.25;
    final carbsPct = _selectedPreferences.contains('Keto') ? 0.05 : 0.50;
    final fatPct = 1.0 - proteinPct - carbsPct;

    _protein = ((_calories * proteinPct) / 4).round();
    _carbs = ((_calories * carbsPct) / 4).round();
    _fat = ((_calories * fatPct) / 9).round();

    // Water
    _water = weight * 0.033;

    // BMI
    _bmi = weight / ((height / 100) * (height / 100));
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);
    final uid = context.read<UserProvider>().currentUser?.id;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'healthGoal': _selectedGoal,
      'activityLevel': _selectedActivity,
      'age': int.tryParse(_ageCtrl.text) ?? 0,
      'height_cm': double.tryParse(_heightCtrl.text) ?? 0,
      'weight_kg': double.tryParse(_weightCtrl.text) ?? 0,
      'gender': _selectedGender,
      'dietaryPreferences': _selectedPreferences,
      'calorieGoal': _calories,
      'proteinGoal_g': _protein,
      'carbsGoal_g': _carbs,
      'fatGoal_g': _fat,
      'waterGoal_L': _water,
      'bmi': _bmi,
      'planCreatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      context.go(AppRoutes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0 && _currentStep < 4)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () {
                    _pageCtrl.previousPage(duration: 400.ms, curve: Curves.easeInOutCubic);
                    setState(() => _currentStep--);
                  },
                )
              else if (_currentStep == 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.customerProfile),
                )
              else
                const SizedBox(width: 48),
              Text(
                'Step ${_currentStep + 1} of 5',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD9899F),
                ),
              ),
              if (_currentStep < 4)
                TextButton(
                  onPressed: () => context.go(AppRoutes.customerHome),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8C7E78),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: const Color(0xFFF9E9F2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD9899F)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _StepLayout(
      title: 'What is your main goal?',
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _goals.length,
        itemBuilder: (context, i) {
          final g = _goals[i];
          final isSel = _selectedGoal == g['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedGoal = g['id']);
              _next();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFD9899F) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: isSel ? null : Border.all(color: const Color(0xFFEFCCE0)),
              ),
              child: Row(
                children: [
                  Text(g['emoji'], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Text(
                    g['label'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF26201B),
                    ),
                  ),
                ],
              ),
            ).animate(target: isSel ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02)),
          );
        },
      ),
    );
  }

  Widget _buildStep2() {
    return _StepLayout(
      title: 'How active are you?',
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _activities.length,
        itemBuilder: (context, i) {
          final a = _activities[i];
          final isSel = _selectedActivity == a['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedActivity = a['id']);
              _next();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFD9899F) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSel ? null : Border.all(color: const Color(0xFFEFCCE0)),
              ),
              child: Row(
                children: [
                  Text(a['emoji'], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['label'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : const Color(0xFF26201B),
                          ),
                        ),
                        Text(
                          a['sub'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isSel ? Colors.white70 : const Color(0xFF8C7E78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep3() {
    return _StepLayout(
      title: 'Tell us about yourself',
      child: Column(
        children: [
          _buildTextField(_ageCtrl, 'Age', 'years'),
          const SizedBox(height: 16),
          _buildTextField(_heightCtrl, 'Height', 'cm'),
          const SizedBox(height: 16),
          _buildTextField(_weightCtrl, 'Weight', 'kg'),
          const SizedBox(height: 24),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final isSel = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFD9899F) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isSel ? null : Border.all(color: const Color(0xFFEFCCE0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      g,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : const Color(0xFF26201B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          AnimatedButton(
            label: 'Continue',
            color: const Color(0xFFD9899F),
            onTap: () async => _next(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildStep4() {
    return _StepLayout(
      title: 'Any dietary preferences?',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dietaryOptions.map((opt) {
              final isSel = _selectedPreferences.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSel) _selectedPreferences.remove(opt);
                    else _selectedPreferences.add(opt);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFD9899F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSel ? null : Border.all(color: const Color(0xFFEFCCE0)),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF5C4F48),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          AnimatedButton(
            label: 'Generate My Plan 🎯',
            color: const Color(0xFFD9899F),
            onTap: () async => _next(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _StepLayout(
      title: 'Your Personalized Plan 🎯',
      child: Column(
        children: [
          _resultCard('🔥 Daily calories', '$_calories kcal', const Color(0xFFD9899F)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _resultCard('🥩 Protein', '${_protein}g', const Color(0xFFC4748A))),
              const SizedBox(width: 12),
              Expanded(child: _resultCard('🌾 Carbs', '${_carbs}g', const Color(0xFF8FA84A))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _resultCard('🥑 Fat', '${_fat}g', const Color(0xFFFFAB5B))),
              const SizedBox(width: 12),
              Expanded(child: _resultCard('💧 Water', '${_water.toStringAsFixed(1)}L/day', const Color(0xFF5A9FC9))),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFCCE0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, color: Color(0xFFD9899F)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your BMI: ${_bmi.toStringAsFixed(1)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text(_getBMICategory(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF52C98A), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AnimatedButton(
            label: 'Start my journey →',
            color: const Color(0xFFC4748A),
            isLoading: _isSaving,
            onTap: _saveAndFinish,
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  String _getBMICategory() {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Normal weight ✅';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _resultCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  final String title;
  final Widget child;
  const _StepLayout({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF26201B),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
