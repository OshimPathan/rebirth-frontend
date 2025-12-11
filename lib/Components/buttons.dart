import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';

class ElevatedButtonCustom extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ElevatedButtonCustom({
    super.key,
    this.title = 'Next',
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow:
            isEnabled
                ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled
                  ? AppColors.primaryColor
                  : AppColors.hintColor.withOpacity(0.3),
          foregroundColor:
              isEnabled ? AppColors.textColor : AppColors.hintColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
        onPressed: isEnabled ? onPressed : null,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class ChoiceButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onPressed;

  final Color selectedButtonColor;
  final Color unselectedButtonColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const ChoiceButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onPressed,
    this.selectedButtonColor = const Color(0xFF4A90E2), // AppColors.accentColor
    this.unselectedButtonColor = const Color(
      0xFFF0F8FF,
    ), // AppColors.secondaryColor
    this.selectedTextColor = const Color(0xFFFFFFFF), // White text on selected
    this.unselectedTextColor = const Color(0xFF2C3E50), // AppColors.textColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: selectedButtonColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? selectedButtonColor : unselectedButtonColor,
          foregroundColor: isSelected ? selectedTextColor : unselectedTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isSelected
                    ? BorderSide.none
                    : BorderSide(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
          ),
          elevation: isSelected ? 2 : 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
