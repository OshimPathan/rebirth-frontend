import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/services/auth_service.dart';
import 'package:rebirth_draft_2/pages/auth/login_screen.dart';
import 'package:rebirth_draft_2/pages/OnBoarding/onboarding_screen.dart';
import 'package:rebirth_draft_2/pages/Home/chat_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Initialize auth service first
    await _authService.initialize();

    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is already logged in
    if (_authService.isLoggedIn) {
      try {
        // Verify token is still valid by getting user data
        final userResult = await _authService.getCurrentUser();

        if (userResult['success']) {
          // Check onboarding status
          final onboardingResult = await _authService.getOnboardingStatus();

          print('Splash - Onboarding Result: $onboardingResult');

          if (onboardingResult['success']) {
            if (onboardingResult['isCompleted'] == true) {
              // Navigate to home screen
              print('Navigating to Home Screen');
              _navigateToScreen(const ChatHomeScreen());
            } else {
              // Navigate to onboarding
              print('Navigating to Onboarding Screen');
              _navigateToScreen(const OnboardingScreen());
            }
          } else {
            // Assume onboarding not completed if can't get status
            print('Onboarding status check failed, navigating to Onboarding');
            _navigateToScreen(const OnboardingScreen());
          }
        } else {
          // Token is invalid or expired
          await _authService.logout();
          _navigateToScreen(const LoginScreen());
        }
      } catch (e) {
        // Error occurred, logout and go to login
        await _authService.logout();
        _navigateToScreen(const LoginScreen());
      }
    } else {
      // User not logged in, go to login screen
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.backgroundColor,
              AppColors.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder - you can replace this with an actual image
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Image.asset('assets/images/butterfly.png'),
                ),

                const SizedBox(height: 30),

                Text(
                  "Rebirth",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Begin your transformation',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentColor,
                  ),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
