import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/Components/onboarding_progress_bar.dart';
import 'package:rebirth_draft_2/Components/page_transitions.dart';
import 'package:rebirth_draft_2/pages/OnBoarding/ideal_self.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class AntiVision extends StatefulWidget {
  const AntiVision({super.key});

  @override
  State<AntiVision> createState() => _AntiVisionState();
}

class _AntiVisionState extends State<AntiVision> {
  final OnboardingService _onboardingService = OnboardingService();
  final TextEditingController _antiVisionController = TextEditingController();

  // Add validation state
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _addTextListener(); // Add listener to validate on text change
  }

  void _addTextListener() {
    _antiVisionController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _antiVisionController.text.trim().isNotEmpty;
    });
  }

  void _loadExistingData() async {
    await _onboardingService.loadFromLocalStorage();
    final data = _onboardingService.currentData;

    setState(() {
      _antiVisionController.text = data.antiVision;
    });

    // Validate form after loading data
    _validateForm();
  }

  void _saveAndContinue() {
    // Save current data
    _onboardingService.updateAntiVision(_antiVisionController.text.trim());

    // Navigate to next screen with custom transition
    Navigator.of(context).push(FadeSlidePageRoute(page: const IdealSelf()));
  }

  @override
  void dispose() {
    _antiVisionController.dispose();
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
              // Progress bar for step 2 of 5
              const OnboardingProgressBar(currentStep: 2, totalSteps: 5),
              const SizedBox(height: 40),
              const Text(
                "What do you want to remove from your life?",
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
                  controller: _antiVisionController,
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
                        'Share what you want to remove from your life...\n\nThis could be negative habits, toxic relationships, limiting beliefs, or anything else holding you back.',
                    hintStyle: TextStyle(
                      color: AppColors.hintColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 12, left: 12),
                      child: Icon(
                        Icons.remove_circle_outline,
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
              SizedBox(height: 330),
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
