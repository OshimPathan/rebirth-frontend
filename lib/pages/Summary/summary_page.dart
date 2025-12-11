import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/pages/Home/chat_home_screen.dart';
// import 'package:rebirth_draft_2/pages/intro/intro_screen.dart';
// import 'package:rebirth_draft_2/Components/buttons.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _isLoading = true;
  bool _isCompleting = false;
  String _summary = '';
  List<dynamic> _summarySpans = const [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() async {
    await _onboardingService.loadFromLocalStorage();
    setState(() {
      _summary = _onboardingService.aiGeneratedSummary;
      _summarySpans = _onboardingService.aiGeneratedSummarySpans;
      _isLoading = false;
    });
  }

  Future<void> _completeOnboardingAndNavigate() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // Complete the onboarding using the onboarding service
      final result = await _onboardingService.completeOnboarding();

      if (result['success']) {
        print('Onboarding completed successfully');

        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatHomeScreen()),
          );
        }
      } else {
        print(
          'Failed to complete onboarding: ${result['error'] ?? result['message']}',
        );
        // Still navigate to home screen even if completion fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: ${result['error'] ?? result['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatHomeScreen()),
          );
        }
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        // Still navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatHomeScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  // Function to parse and format text with **bold** markers (fallback)
  TextSpan _formatText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final List<String> parts = text.split(boldRegex);
    final List<String> matches =
        boldRegex.allMatches(text).map((m) => m.group(0)!).toList();

    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: const TextStyle(
            color: AppColors.textColor,
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.5,
          ),
        ),
      );

      if (i < matches.length) {
        spans.add(
          TextSpan(
            text: matches[i].replaceAll('**', ''),
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return TextSpan(children: spans);
  }

  Widget _buildRichFromSpans(List<dynamic> spans) {
    if (spans.isEmpty) return RichText(text: _formatText(_summary));
    final children = spans.map<TextSpan>((seg) {
      final Map<String, dynamic> s = Map<String, dynamic>.from(seg);
      final String text = (s['text'] ?? '').toString();
      final bool isBold = s['bold'] == true;
      return TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 16,
          height: 1.5,
          letterSpacing: 0.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
    return RichText(text: TextSpan(children: children));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Summary",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentColor,
                            ),
                          ),
                        )
                        : _summary.isNotEmpty
                        ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _summarySpans.isNotEmpty
                              ? _buildRichFromSpans(_summarySpans)
                              : RichText(text: _formatText(_summary)),
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                color: AppColors.primaryColor,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your Personalized Summary',
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete the onboarding process to generate your personalized AI summary and insights.',
                                style: TextStyle(
                                  color: AppColors.hintColor,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButtonCustom(
              onPressed: _isCompleting ? null : _completeOnboardingAndNavigate,
              title: _isCompleting ? 'Completing...' : 'Next',
            ),
          ],
        ),
      ),
    );
  }
}
