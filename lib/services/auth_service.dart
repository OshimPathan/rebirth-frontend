import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _baseUrl =
      'https://rebirth-backend.vercel.app/api'; // Update with your backend URL

  String? _token;
  Map<String, dynamic>? _user;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  String get baseUrl => _baseUrl;

  // Initialize service by loading stored data
  Future<void> initialize() async {
    await _loadStoredData();
  }

  // Load stored authentication data
  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _user = jsonDecode(userJson);
      }
    } catch (e) {
      print('Error loading stored auth data: $e');
    }
  }

  // Save authentication data to storage
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user));
      _token = token;
      _user = user;
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }

  // Clear authentication data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      _token = null;
      _user = null;
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveAuthData(responseData['token'], responseData['user']);
        return {'success': true, 'user': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveAuthData(responseData['token'], responseData['user']);
        return {'success': true, 'user': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get current user from backend
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _user = userData;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(userData));
        return {'success': true, 'user': userData};
      } else {
        // Token might be invalid
        await logout();
        return {'success': false, 'message': 'Invalid token'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update profile (name or profile picture URL)
  Future<Map<String, dynamic>> updateProfile({String? name, String? profilePicture}) async {
    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (profilePicture != null) 'profilePicture': profilePicture,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedUser = data['user'] as Map<String, dynamic>?;
        if (updatedUser != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(updatedUser));
          _user = updatedUser;
        }
        return {'success': true, 'user': updatedUser};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Profile update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Goals APIs
  Future<List<dynamic>> getGoals() async {
    if (_token == null) return [];
    final resp = await http.get(Uri.parse('$_baseUrl/auth/goals'), headers: {
      'Authorization': 'Bearer $_token',
    });
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['goals'] as List?) ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>?> createGoal({required String title, required String category, DateTime? targetDate}) async {
    if (_token == null) return null;
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/goals'),
      headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': category,
        if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
      }),
    );
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['goal'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateGoal(String goalId, Map<String, dynamic> updates) async {
    if (_token == null) return null;
    final resp = await http.patch(
      Uri.parse('$_baseUrl/auth/goals/$goalId'),
      headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['goal'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> deleteGoal(String goalId) async {
    if (_token == null) return false;
    final resp = await http.delete(
      Uri.parse('$_baseUrl/auth/goals/$goalId'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return resp.statusCode == 200;
  }

  // Check onboarding status
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      print('Making request to: $_baseUrl/onboarding/status');
      print('With token: $_token');

      final response = await http.get(
        Uri.parse('$_baseUrl/onboarding/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');

        // Handle different possible response structures
        bool isCompleted = false;

        if (data['onboarding'] != null) {
          final onboarding = data['onboarding'];

          // Check for different possible field names and types
          if (onboarding['isCompleted'] != null) {
            // Handle boolean or string
            if (onboarding['isCompleted'] is bool) {
              isCompleted = onboarding['isCompleted'];
            } else if (onboarding['isCompleted'] is String) {
              isCompleted = onboarding['isCompleted'].toLowerCase() == 'true';
            }
          } else if (onboarding['completed'] != null) {
            // Alternative field name
            if (onboarding['completed'] is bool) {
              isCompleted = onboarding['completed'];
            } else if (onboarding['completed'] is String) {
              isCompleted = onboarding['completed'].toLowerCase() == 'true';
            }
          }
        }

        final result = {
          'success': true,
          'isCompleted': isCompleted,
          'onboarding': data['onboarding'],
        };

        print('Returning result: $result');
        return result;
      } else {
        return {'success': false, 'message': 'Failed to get onboarding status'};
      }
    } catch (e) {
      print('Error in getOnboardingStatus: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout user
  Future<void> logout() async {
    await _clearAuthData();
  }

  // Verify token validity
  Future<bool> verifyToken() async {
    if (_token == null) return false;

    final result = await getCurrentUser();
    return result['success'] == true;
  }

  // Test method to debug onboarding status
  Future<void> testOnboardingStatus() async {
    print('=== TESTING ONBOARDING STATUS ===');
    final result = await getOnboardingStatus();
    print('Final result: $result');
    print('isCompleted value: ${result['isCompleted']}');
    print('isCompleted type: ${result['isCompleted'].runtimeType}');
    print('=== END TEST ===');
  }

  // Complete onboarding
  Future<Map<String, dynamic>> completeOnboarding() async {
    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      print('Completing onboarding with token: $_token');

      final response = await http.post(
        Uri.parse('$_baseUrl/onboarding/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('Complete onboarding response status: ${response.statusCode}');
      print('Complete onboarding response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Onboarding completed successfully',
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to complete onboarding',
        };
      }
    } catch (e) {
      print('Error in completeOnboarding: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update onboarding data
  Future<Map<String, dynamic>> updateOnboardingData({
    Map<String, dynamic>? personalInfo,
    Map<String, dynamic>? transformation,
  }) async {
    try {
      if (_token == null) {
        return {'success': false, 'message': 'No token available'};
      }

      final body = <String, dynamic>{};
      if (personalInfo != null) body['personalInfo'] = personalInfo;
      if (transformation != null) body['transformation'] = transformation;

      final response = await http.patch(
        Uri.parse('$_baseUrl/onboarding/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Onboarding data updated successfully',
          'onboarding': data['onboarding'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update onboarding data',
        };
      }
    } catch (e) {
      print('Error in updateOnboardingData: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
