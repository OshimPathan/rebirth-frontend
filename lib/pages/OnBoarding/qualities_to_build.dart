import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/Components/onboarding_progress_bar.dart';
import 'package:rebirth_draft_2/Components/page_transitions.dart';
import 'package:rebirth_draft_2/pages/OnBoarding/negative_habits.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class QualitiesToBuild extends StatefulWidget {
  const QualitiesToBuild({super.key});

  @override
  State<QualitiesToBuild> createState() => _QualitiesToBuildState();
}

class _QualitiesToBuildState extends State<QualitiesToBuild> {
  final OnboardingService _onboardingService = OnboardingService();
  final TextEditingController _qualitiesController = TextEditingController();

  // Add validation state
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _addTextListener(); // Add listener to validate on text change
  }

  void _addTextListener() {
    _qualitiesController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _qualitiesController.text.trim().isNotEmpty;
    });
  }

  void _loadExistingData() async {
    await _onboardingService.loadFromLocalStorage();
    final data = _onboardingService.currentData;

    setState(() {
      _qualitiesController.text = data.qualitiesToBuild;
    });

    // Validate form after loading data
    _validateForm();
  }

  void _saveAndContinue() {
    // Save current data
    _onboardingService.updateQualitiesToBuild(_qualitiesController.text.trim());

    // Navigate to next screen with custom transition
    Navigator.of(
      context,
    ).push(FadeSlidePageRoute(page: const NegativeHabits()));
  }

  @override
  void dispose() {
    _qualitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar for step 4 of 5
              const OnboardingProgressBar(currentStep: 4, totalSteps: 5),
              const SizedBox(height: 40),
              const Text(
                "Qualities To Build",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _qualitiesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.accentColor,
                        width: 2,
                      ),
                    ),
                    hintText:
                        'List the qualities you want to develop...\n\nFor example: courage, resilience, patience, confidence, leadership, compassion.',
                    hintStyle: TextStyle(
                      color: AppColors.hintColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 12, left: 12),
                      child: Icon(
                        Icons.psychology_outlined,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 425),
              ElevatedButtonCustom(
                onPressed: _saveAndContinue,
                isEnabled: _isFormValid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
