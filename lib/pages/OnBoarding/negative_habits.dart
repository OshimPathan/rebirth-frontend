import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/Components/onboarding_progress_bar.dart';
import 'package:rebirth_draft_2/Components/page_transitions.dart';
import 'package:rebirth_draft_2/pages/Summary/summary_page.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class NegativeHabits extends StatefulWidget {
  const NegativeHabits({super.key});

  @override
  State<NegativeHabits> createState() => _NegativeHabitsState();
}

class _NegativeHabitsState extends State<NegativeHabits> {
  final OnboardingService _onboardingService = OnboardingService();
  final TextEditingController _negativeHabitsController =
      TextEditingController();
  bool _isLoading = false;

  // Add validation state
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _addTextListener(); // Add listener to validate on text change
  }

  void _addTextListener() {
    _negativeHabitsController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _negativeHabitsController.text.trim().isNotEmpty;
    });
  }

  void _loadExistingData() async {
    await _onboardingService.loadFromLocalStorage();
    final data = _onboardingService.currentData;

    setState(() {
      _negativeHabitsController.text = data.negativeHabits;
    });

    // Validate form after loading data
    _validateForm();
  }

  void _saveAndContinue() async {
    // Save current data
    _onboardingService.updateNegativeHabits(
      _negativeHabitsController.text.trim(),
    );

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Send data to AI for summary (you can choose which API to use)
      // You can switch between different APIs by changing the method call:
      // final result = await _onboardingService.sendToAIForSummary(); // Custom API
      // final result = await _onboardingService.sendToOpenAI();        // OpenAI API
      final result = await _onboardingService.sendToGemini(); // Gemini API

      if (result['success']) {
        // Show success message and navigate
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text(
          //       'Data collected and summary generated successfully!',
          //     ),
          //     backgroundColor: Colors.grey,
          //   ),
          // );

          Navigator.of(
            context,
          ).push(FadeSlidePageRoute(page: const SummaryPage()));
        }
      } else {
        // Show error message but still navigate
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Error generating summary: ${result['error']}'),
          //     backgroundColor: Colors.orange,
          //   ),
          // );

          Navigator.of(
            context,
          ).push(FadeSlidePageRoute(page: const SummaryPage()));
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Unexpected error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _negativeHabitsController.dispose();
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
              // Progress bar for step 5 of 5
              const OnboardingProgressBar(currentStep: 5, totalSteps: 5),
              const SizedBox(height: 40),
              const Text(
                "Negative Habits to Avoid",
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
                  controller: _negativeHabitsController,
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
                        'List the negative habits you want to avoid...\n\nFor example: procrastination, negative thinking, poor time management, unhealthy eating.',
                    hintStyle: TextStyle(
                      color: AppColors.hintColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 12, left: 12),
                      child: Icon(
                        Icons.block_outlined,
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
              SizedBox(height: 385),
              _isLoading
                  ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentColor,
                    ),
                  )
                  : ElevatedButtonCustom(
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
