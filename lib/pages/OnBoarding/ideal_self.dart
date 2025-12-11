import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/Components/onboarding_progress_bar.dart';
import 'package:rebirth_draft_2/Components/page_transitions.dart';
import 'package:rebirth_draft_2/pages/OnBoarding/qualities_to_build.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class IdealSelf extends StatefulWidget {
  const IdealSelf({super.key});

  @override
  State<IdealSelf> createState() => _IdealSelfState();
}

class _IdealSelfState extends State<IdealSelf> {
  final OnboardingService _onboardingService = OnboardingService();
  final TextEditingController _idealSelfController = TextEditingController();

  // Add validation state
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _addTextListener(); // Add listener to validate on text change
  }

  void _addTextListener() {
    _idealSelfController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _idealSelfController.text.trim().isNotEmpty;
    });
  }

  void _loadExistingData() async {
    await _onboardingService.loadFromLocalStorage();
    final data = _onboardingService.currentData;

    setState(() {
      _idealSelfController.text = data.idealSelf;
    });

    // Validate form after loading data
    _validateForm();
  }

  void _saveAndContinue() {
    // Save current data
    _onboardingService.updateIdealSelf(_idealSelfController.text.trim());

    // Navigate to next screen with custom transition
    Navigator.of(
      context,
    ).push(FadeSlidePageRoute(page: const QualitiesToBuild()));
  }

  @override
  void dispose() {
    _idealSelfController.dispose();
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
            children: [
              // Progress bar for step 3 of 5
              const OnboardingProgressBar(currentStep: 3, totalSteps: 5),
              const SizedBox(height: 40),
              const Text(
                "Describe your ideal self",
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
                  controller: _idealSelfController,
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
                        'Describe the person you aspire to become...\n\nThink about your ideal qualities, achievements, mindset, and the impact you want to have on the world.',
                    hintStyle: TextStyle(
                      color: AppColors.hintColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 12, left: 12),
                      child: Icon(
                        Icons.star_outline,
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
              SizedBox(height: 380),
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
