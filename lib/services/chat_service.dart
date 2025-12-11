import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/models/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatService extends ChangeNotifier {
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;

  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;

  ChatService() {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList('chat_sessions') ?? [];

      _sessions =
          sessionsJson.map((json) {
            final Map<String, dynamic> data = jsonDecode(json);

            return ChatSession(
              id: data['id'],
              title: data['title'],
              messages:
                  (data['messages'] as List)
                      .map(
                        (msg) => ChatMessage(
                          text: msg['text'],
                          isUser: msg['isUser'],
                          timestamp: DateTime.parse(msg['timestamp']),
                        ),
                      )
                      .toList(),
              createdAt: DateTime.parse(data['createdAt']),
              lastUpdated: DateTime.parse(data['lastUpdated']),
            );
          }).toList();

      // Sort sessions by lastUpdated
      _sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sessionsJson =
          _sessions.map((session) {
            return jsonEncode({
              'id': session.id,
              'title': session.title,
              'messages':
                  session.messages
                      .map(
                        (msg) => {
                          'text': msg.text,
                          'isUser': msg.isUser,
                          'timestamp': msg.timestamp.toIso8601String(),
                        },
                      )
                      .toList(),
              'createdAt': session.createdAt.toIso8601String(),
              'lastUpdated': session.lastUpdated.toIso8601String(),
            });
          }).toList();

      await prefs.setStringList('chat_sessions', sessionsJson);
    } catch (e) {
      debugPrint('Error saving sessions: $e');
    }
  }

  Future<void> createNewSession() async {
    final newSession = ChatSession(id: _uuid.v4(), title: 'New Chat');

    _sessions.insert(0, newSession);
    _currentSession = newSession;

    await _saveSessions();
    notifyListeners();
  }

  Future<void> selectSession(String sessionId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    _currentSession = session;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);

    if (_currentSession?.id == sessionId) {
      _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
    }

    await _saveSessions();
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final updatedSession = _sessions[index].copyWith(
        title: newTitle,
        lastUpdated: DateTime.now(),
      );

      _sessions[index] = updatedSession;

      if (_currentSession?.id == sessionId) {
        _currentSession = updatedSession;
      }

      await _saveSessions();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (_currentSession == null) {
      await createNewSession();
    }

    final userMessage = ChatMessage(text: text, isUser: true);

    // Update session with new message
    final updatedMessages = [..._currentSession!.messages, userMessage];

    // If this is the first message, update the session title
    String sessionTitle = _currentSession!.title;
    if (_currentSession!.messages.isEmpty) {
      sessionTitle = text.length > 30 ? '${text.substring(0, 27)}...' : text;
    }

    final updatedSession = _currentSession!.copyWith(
      messages: updatedMessages,
      title: sessionTitle,
      lastUpdated: DateTime.now(),
    );

    // Update sessions list
    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    _sessions[index] = updatedSession;
    _currentSession = updatedSession;

    notifyListeners();
    await _saveSessions();

    // Simulate AI response
    await _simulateResponse(text);
  }

  Future<void> _simulateResponse(String userMessage) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final response = _generateAIResponse(userMessage);
    final aiMessage = ChatMessage(text: response, isUser: false);

    // Update session with AI response
    final updatedMessages = [..._currentSession!.messages, aiMessage];

    final updatedSession = _currentSession!.copyWith(
      messages: updatedMessages,
      lastUpdated: DateTime.now(),
    );

    // Update sessions list
    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    _sessions[index] = updatedSession;
    _currentSession = updatedSession;

    _isLoading = false;
    notifyListeners();
    await _saveSessions();
  }

  String _generateAIResponse(String userMessage) {
    // Simple response generation (in a real app, this would call an API)
    if (userMessage.toLowerCase().contains('hello') ||
        userMessage.toLowerCase().contains('hi')) {
      return "Hello! How can I help you today?";
    } else if (userMessage.toLowerCase().contains('thank')) {
      return "You're welcome! Is there anything else I can help you with?";
    } else if (userMessage.toLowerCase().contains('bye')) {
      return "Goodbye! Feel free to chat again anytime.";
    } else if (userMessage.toLowerCase().contains('who are you')) {
      return "I'm your virtual assistant, designed to help with your questions and provide information.";
    } else if (userMessage.length < 10) {
      return "I see. Could you provide more details so I can assist you better?";
    } else {
      return "Thank you for sharing that. I'm here to assist with your journey of self-improvement and transformation. Is there something specific you'd like guidance on?";
    }
  }

  void clearCurrentChat() {
    if (_currentSession != null) {
      final clearedSession = _currentSession!.copyWith(
        messages: [],
        lastUpdated: DateTime.now(),
      );

      final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      _sessions[index] = clearedSession;
      _currentSession = clearedSession;

      _saveSessions();
      notifyListeners();
    }
  }
}
