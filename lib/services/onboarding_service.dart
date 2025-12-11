import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import 'auth_service.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _storageKey = 'onboarding_data';
  final AuthService _authService = AuthService();

  // All AI calls are handled by backend now

  OnboardingData _currentData = OnboardingData();
  String _aiGeneratedSummary = '';
  List<dynamic> _aiGeneratedSummarySpans = const [];

  // Getters and setters for current data
  OnboardingData get currentData => _currentData;
  String get aiGeneratedSummary => _aiGeneratedSummary;
  List<dynamic> get aiGeneratedSummarySpans => _aiGeneratedSummarySpans;

  // Save data to local storage
  Future<bool> saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataToSave = {
        'onboarding_data': _currentData.toJson(),
        'ai_summary': _aiGeneratedSummary,
        'ai_summary_spans': _aiGeneratedSummarySpans,
      };
      final jsonString = jsonEncode(dataToSave);
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving data to local storage: $e');
      return false;
    }
  }

  // Load data from local storage
  Future<bool> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final Map<String, dynamic> savedData = jsonDecode(jsonString);

        // Load onboarding data
        if (savedData['onboarding_data'] != null) {
          _currentData = OnboardingData.fromJson(savedData['onboarding_data']);
        }

        // Load AI summary
        _aiGeneratedSummary = savedData['ai_summary'] ?? '';
        _aiGeneratedSummarySpans = savedData['ai_summary_spans'] ?? [];

        return true;
      }
      return false;
    } catch (e) {
      print('Error loading data from local storage: $e');
      return false;
    }
  }

  // Clear local storage
  Future<bool> clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing local storage: $e');
      return false;
    }
  }

  // Update basic info (from onboarding screen)
  void updateBasicInfo({
    String? name,
    String? age,
    String? location,
    String? occupation,
    String? gender,
  }) {
    if (name != null) _currentData.name = name;
    if (age != null) _currentData.age = age;
    if (location != null) _currentData.location = location;
    if (occupation != null) _currentData.occupation = occupation;
    if (gender != null) _currentData.gender = gender;

    saveToLocalStorage();
  }

  // Update anti-vision
  void updateAntiVision(String antiVision) {
    _currentData.antiVision = antiVision;
    saveToLocalStorage();
  }

  // Update ideal self
  void updateIdealSelf(String idealSelf) {
    _currentData.idealSelf = idealSelf;
    saveToLocalStorage();
  }

  // Update qualities to build
  void updateQualitiesToBuild(String qualities) {
    _currentData.qualitiesToBuild = qualities;
    saveToLocalStorage();
  }

  // Update negative habits
  void updateNegativeHabits(String habits) {
    _currentData.negativeHabits = habits;
    saveToLocalStorage();
  }

  // Deprecated: direct AI calls removed; backend handles AI
  Future<Map<String, dynamic>> sendToAIForSummary() async => {'success': false, 'error': 'Deprecated'};

  Future<Map<String, dynamic>> getAISummary() async => {'success': false, 'error': 'Deprecated'};

  // Send data to OpenAI-compatible API (example)
  Future<Map<String, dynamic>> sendToOpenAI() async {
    try {
      const openAIEndpoint = 'https://api.openai.com/v1/chat/completions';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer YOUR_OPENAI_API_KEY', // Replace with your OpenAI API key
      };

      final body = jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a personal development coach. Analyze the user\'s onboarding data and provide a comprehensive personality summary with actionable insights.',
          },
          {
            'role': 'user',
            'content':
                'Please analyze this user data and provide a summary:\n\n${_currentData.getFormattedDataForAI()}',
          },
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      });

      final response = await http.post(
        Uri.parse(openAIEndpoint),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final summary = responseData['choices'][0]['message']['content'];

        // Store the generated summary
        _aiGeneratedSummary = summary;
        await saveToLocalStorage();

        return {'success': true, 'data': responseData, 'summary': summary};
      } else {
        return {
          'success': false,
          'error':
              'OpenAI API request failed with status: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Send data to Google Gemini API
  Future<Map<String, dynamic>> sendToGemini() async {
    try {
      final auth = _authService;
      if (auth.token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final uri = Uri.parse('${auth.baseUrl}/onboarding/generate-summary');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      };
      final body = jsonEncode({
        'onboardingData': {
          'personalInfo': {
            'age': int.tryParse(_currentData.age) ?? 0,
            'gender': _mapGenderToBackendEnum(_currentData.gender),
            'occupation': _currentData.occupation,
            'location': _currentData.location,
          },
          'transformation': {
            'thingsToRemove': [_currentData.antiVision],
            'idealSelfDescription': _currentData.idealSelf,
            'qualitiesToBuild': [_currentData.qualitiesToBuild],
            'negativeHabits': [_currentData.negativeHabits],
          }
        }
      });

      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String summary = data['text'] ?? '';
        final List<dynamic> spans = data['spans'] ?? [];
        _aiGeneratedSummary = summary;
        _aiGeneratedSummarySpans = spans;
        await saveToLocalStorage();
        return {'success': true, 'summary': summary, 'spans': spans};
      }
      return {
        'success': false,
        'error': 'Backend summary failed with status: ${response.statusCode}',
        'details': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get all collected data as a formatted string
  String getAllDataFormatted() {
    return _currentData.getFormattedDataForAI();
  }

  // Check if all data is collected
  bool isDataComplete() {
    return _currentData.isComplete();
  }

  // Check if AI summary is available
  bool hasSummary() {
    return _aiGeneratedSummary.isNotEmpty;
  }

  // Clear AI summary
  void clearSummary() {
    _aiGeneratedSummary = '';
    saveToLocalStorage();
  }

  // Reset all data
  void resetData() {
    _currentData = OnboardingData();
    _aiGeneratedSummary = '';
    clearLocalStorage();
  }

  // Save onboarding data to backend
  Future<Map<String, dynamic>> saveToBackend() async {
    try {
      // Map gender to backend enum values
      String mappedGender = _mapGenderToBackendEnum(_currentData.gender);

      final personalInfo = {
        'age': int.tryParse(_currentData.age) ?? 0,
        'gender': mappedGender,
        'occupation': _currentData.occupation,
        'location': _currentData.location,
      };

      final transformation = {
        'thingsToRemove': [_currentData.antiVision],
        'idealSelfDescription': _currentData.idealSelf,
        'qualitiesToBuild': [_currentData.qualitiesToBuild],
        'negativeHabits': [_currentData.negativeHabits],
      };

      // Update onboarding data
      final result = await _authService.updateOnboardingData(
        personalInfo: personalInfo,
        transformation: transformation,
      );

      return result;
    } catch (e) {
      return {'success': false, 'error': 'Failed to save to backend: $e'};
    }
  }

  // Map gender input to backend enum values
  String _mapGenderToBackendEnum(String gender) {
    String lowerGender = gender.toLowerCase().trim();

    // Handle common variations
    switch (lowerGender) {
      case 'male':
      case 'm':
        return 'male';
      case 'female':
      case 'f':
        return 'female';
      case 'non-binary':
      case 'nonbinary':
      case 'non binary':
      case 'enby':
        return 'non-binary';
      case 'prefer not to say':
      case 'prefer_not_to_say':
      case 'rather not say':
        return 'prefer_not_to_say';
      default:
        return 'other';
    }
  }

  // Complete onboarding process
  Future<Map<String, dynamic>> completeOnboarding() async {
    try {
      // First save data to backend
      final saveResult = await saveToBackend();
      if (!saveResult['success']) {
        return saveResult;
      }

      // Then mark onboarding as completed
      final completeResult = await _authService.completeOnboarding();
      if (completeResult['success']) {
        // Clear local storage since data is now saved to backend
        await clearLocalStorage();
      }

      return completeResult;
    } catch (e) {
      return {'success': false, 'error': 'Failed to complete onboarding: $e'};
    }
  }
}
