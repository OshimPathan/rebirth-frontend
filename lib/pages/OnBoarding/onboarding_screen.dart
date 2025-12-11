import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:auto_hide_keyboard/auto_hide_keyboard.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/Components/onboarding_progress_bar.dart';
import 'package:rebirth_draft_2/Components/page_transitions.dart';
import 'package:rebirth_draft_2/pages/OnBoarding/anti_vision.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingService _onboardingService = OnboardingService();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  // Add validation state
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _addTextListeners(); // Add listeners to validate on text change
  }

  void _addTextListeners() {
    _nameController.addListener(_validateForm);
    _ageController.addListener(_validateForm);
    _locationController.addListener(_validateForm);
    _occupationController.addListener(_validateForm);
    _genderController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _nameController.text.trim().isNotEmpty &&
          _ageController.text.trim().isNotEmpty &&
          _locationController.text.trim().isNotEmpty &&
          _occupationController.text.trim().isNotEmpty &&
          _genderController.text.trim().isNotEmpty;
    });
  }

  void _loadExistingData() async {
    await _onboardingService.loadFromLocalStorage();
    final data = _onboardingService.currentData;

    setState(() {
      _nameController.text = data.name;
      _ageController.text = data.age;
      _locationController.text = data.location;
      _occupationController.text = data.occupation;
      _genderController.text = data.gender;
    });

    // Validate form after loading data
    _validateForm();
  }

  void _saveAndContinue() {
    // Save current data
    _onboardingService.updateBasicInfo(
      name: _nameController.text.trim(),
      age: _ageController.text.trim(),
      location: _locationController.text.trim(),
      occupation: _occupationController.text.trim(),
      gender: _genderController.text.trim(),
    );

    // Navigate to next screen with custom transition
    Navigator.of(context).push(FadeSlidePageRoute(page: const AntiVision()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress bar for step 1 of 5
              const OnboardingProgressBar(currentStep: 1, totalSteps: 5),
              const SizedBox(height: 40),
              const Text(
                'Tell Us About Yourself',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 40),
              Column(
                children: [
                  AutoHideKeyboard(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
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
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(color: AppColors.hintColor),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  AutoHideKeyboard(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
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
                          hintText: 'Enter your age',
                          hintStyle: TextStyle(color: AppColors.hintColor),
                          prefixIcon: Icon(
                            Icons.cake_outlined,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  AutoHideKeyboard(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
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
                          hintText: 'Enter your location',
                          hintStyle: TextStyle(color: AppColors.hintColor),
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  AutoHideKeyboard(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _occupationController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
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
                          hintText: 'Enter your occupation',
                          hintStyle: TextStyle(color: AppColors.hintColor),
                          prefixIcon: Icon(
                            Icons.work_outline,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        style: TextStyle(color: AppColors.textColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownMenuExample(
                      controller: _genderController,
                      onChanged: _validateForm,
                    ),
                  ),
                  SizedBox(height: 95),
                ],
              ),
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

enum GenderLabel {
  male('Male'),
  female('Female'),
  other('Other'),
  preferNotToSay('Prefer not to say');

  const GenderLabel(this.label);
  final String label;
}

class DropdownMenuExample extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const DropdownMenuExample({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<DropdownMenuExample> createState() => _DropdownMenuExampleState();
}

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  GenderLabel? selectedGender;

  @override
  void initState() {
    super.initState();
    // Set initial value if controller has text
    if (widget.controller.text.isNotEmpty) {
      selectedGender = GenderLabel.values.firstWhere(
        (gender) => gender.label == widget.controller.text,
        orElse: () => GenderLabel.preferNotToSay,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          // Use Expanded to take available width within Row
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: const TextTheme(
                // Ensure text color for input field is dark
                titleMedium: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16, // Match text field font size
                  height: 1.4, // Match text field line height
                ),
              ),
            ),
            child: DropdownMenu<GenderLabel>(
              inputDecorationTheme: InputDecorationTheme(
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
                prefixIconColor: AppColors.primaryColor,
                // Explicitly set text style for the input field
                labelStyle: TextStyle(color: AppColors.hintColor),
                hintStyle: TextStyle(color: AppColors.hintColor),
                counterStyle: TextStyle(color: AppColors.hintColor),
                floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
                errorStyle: TextStyle(color: AppColors.errorColor),
                suffixStyle: TextStyle(color: AppColors.textColor),
                prefixStyle: TextStyle(color: AppColors.textColor),
                helperStyle: TextStyle(color: AppColors.hintColor),
                // Ensure text color for the input field itself is dark
                // This is handled by the Theme's titleMedium, but reinforce here
                // to be explicit.
                // TextStyle should ideally come from Theme.of(context).textTheme
              ),
              controller: widget.controller,
              requestFocusOnTap: true,
              leadingIcon: Icon(
                Icons.person_pin_outlined,
                color: AppColors.primaryColor,
              ),
              label: Text(
                'Select Gender',
                style: TextStyle(color: AppColors.hintColor),
              ),
              textStyle: TextStyle(
                color: AppColors.textColor,
              ), // Set text color for the selected item
              onSelected: (GenderLabel? gender) {
                setState(() {
                  selectedGender = gender;
                  if (gender != null) {
                    widget.controller.text = gender.label;
                  }
                });
                if (widget.onChanged != null) {
                  widget.onChanged!();
                }
              },
              dropdownMenuEntries:
                  GenderLabel.values.map((gender) {
                    return DropdownMenuEntry<GenderLabel>(
                      value: gender,
                      label: gender.label,
                      style: MenuItemButton.styleFrom(
                        foregroundColor:
                            AppColors.textColor, // Dark text for items
                        backgroundColor:
                            AppColors
                                .surfaceColor, // White background for items
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        visualDensity: VisualDensity.comfortable,
                      ),
                    );
                  }).toList(),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(
                  AppColors.surfaceColor, // White background for the menu
                ),
                surfaceTintColor: WidgetStateProperty.all(
                  AppColors.primaryColor.withOpacity(0.1),
                ),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
