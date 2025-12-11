import 'package:auto_hide_keyboard/auto_hide_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
// import 'package:rebirth_draft_2/services/onboarding_service.dart';
import 'package:rebirth_draft_2/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:rebirth_draft_2/pages/Profile/profile_screen.dart';
import 'package:rebirth_draft_2/pages/auth/login_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? _sessionId;
  bool _isTyping = false;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Backend-only: all AI calls happen on server

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadExistingSession();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await _authService.getCurrentUser();
      if (result['success']) {
        setState(() {
          _userData = result['user'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Moved context building to backend

  // Function to parse and format text with **bold** markers
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

  Future<Map<String, dynamic>> _fetchAIFromBackend(String userMessage) async {
    try {
      final uri = Uri.parse('${_authService.baseUrl}/chat/message');
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}'
      };
      final body = jsonEncode({'message': userMessage, if (_sessionId != null) 'sessionId': _sessionId});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['sessionId'] != null) {
          _sessionId = data['sessionId'];
        }
        return data;
      } else {
        debugPrint('Backend chat error: ${response.statusCode} ${response.body}');
        return {'text': 'Oops, something went wrong. Please try again later.', 'spans': null};
      }
    } catch (e) {
      debugPrint('Backend chat exception: $e');
      return {'text': 'Failed to get response. Please check your connection.', 'spans': null};
    }
  }

  Future<void> _loadExistingSession() async {
    try {
      final uri = Uri.parse('${_authService.baseUrl}/chat/sessions/today');
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}'
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final session = data['session'];
        if (session != null && session['_id'] != null) {
          _sessionId = session['_id'];
        }
        final List msgs = (data['messages'] as List?) ?? [];
        setState(() {
          _messages.clear();
          for (final m in msgs) {
            final isUser = (m['role'] ?? '') == 'user';
            _messages.add({
              'text': m['text'] ?? '',
              'spans': m['spans'],
              'isUser': isUser,
              'timestamp': DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Load session error: $e');
    }
  }

  Future<void> _loadMessagesForSession(String sessionId) async {
    try {
      final uri = Uri.parse('${_authService.baseUrl}/chat/sessions/$sessionId/messages?limit=100');
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}'
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List msgs = (data['messages'] as List?) ?? [];
        setState(() {
          _messages.clear();
          for (final m in msgs) {
            final isUser = (m['role'] ?? '') == 'user';
            _messages.add({
              'text': m['text'] ?? '',
              'spans': m['spans'],
              'isUser': isUser,
              'timestamp': DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Load messages error: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String userText = _messageController.text.trim();

    setState(() {
      _messages.add({
        'text': userText,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();

    // Fetch AI response from backend
    final Map<String, dynamic> aiReply = await _fetchAIFromBackend(userText);

    if (!mounted) return;

    setState(() {
      _messages.add({
        'text': aiReply['text'] ?? '',
        'spans': aiReply['spans'],
        'isUser': false,
        'timestamp': DateTime.now(),
      });
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isUser
            ? Text(
                message['text'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              )
            : _buildAssistantMessage(message),
      ),
    );
  }

  Widget _buildAssistantMessage(Map<String, dynamic> message) {
    final spans = message['spans'];
    if (spans is List) {
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

    // Fallback to local formatter if spans not provided
    return RichText(text: _formatText(message['text'] ?? ''));
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(30),
                    color: AppColors.accentColor,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userData?['name'] ?? 'User',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData?['email'] ?? 'user@example.com',
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.today_outlined,
                  title: 'Today\'s Chat',
                  onTap: () async {
                    Navigator.pop(context);
                    await _loadExistingSession();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat History',
                  onTap: () {
                    Navigator.pop(context);
                    _openChatHistory();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.track_changes_outlined,
                  title: 'Progress Tracking',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to progress tracking
                    _showComingSoon('Progress Tracking');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.psychology_outlined,
                  title: 'Personal Goals',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to goals
                    _showComingSoon('Personal Goals');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.auto_graph_outlined,
                  title: 'Insights & Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to analytics
                    _showComingSoon('Insights & Analytics');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                    _showComingSoon('Settings');
                  },
                ),
                const Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                    _showComingSoon('Help & Support');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _openChatHistory() async {
    try {
      final uri = Uri.parse('${_authService.baseUrl}/chat/sessions');
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}'
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List sessions = (data['sessions'] as List?) ?? [];
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.backgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                final dateFormatter = DateFormat('MMM d, yyyy', 'en_US');
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.textColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                'Chat History',
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: sessions.length,
                            itemBuilder: (ctx, idx) {
                              final s = sessions[idx] as Map<String, dynamic>;
                              final DateTime dt = DateTime.tryParse((s['updatedAt'] ?? s['createdAt'] ?? '').toString()) ?? DateTime.now();
                              final String dateLabel = dateFormatter.format(dt);
                              final String rawTitle = (s['title'] ?? '').toString().trim();
                              final String displayTitle = (rawTitle.isEmpty || rawTitle == 'New Chat') ? dateLabel : rawTitle;

                              return ListTile(
                                title: Text(
                                  displayTitle,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                                subtitle: Text(
                                  dateLabel,
                                  style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.textColor.withValues(alpha: 0.8)),
                                  onPressed: () async {
                                    final controller = TextEditingController(text: displayTitle);
                                    final newTitle = await showDialog<String>(
                                      context: context,
                                      builder: (dCtx) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.backgroundColor,
                                          title: Text('Rename Chat', style: TextStyle(color: AppColors.textColor)),
                                          content: TextField(
                                            controller: controller,
                                            style: TextStyle(color: AppColors.textColor),
                                            decoration: InputDecoration(
                                              hintText: 'Enter a name',
                                              hintStyle: TextStyle(color: AppColors.textColor.withValues(alpha: 0.5)),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx),
                                              child: Text('Cancel', style: TextStyle(color: AppColors.textColor)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx, controller.text.trim()),
                                              child: Text('Save', style: TextStyle(color: AppColors.accentColor)),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (newTitle != null && newTitle.isNotEmpty) {
                                      try {
                                        final uri = Uri.parse('${_authService.baseUrl}/chat/sessions/${s['_id']}');
                                        final headers = {
                                          'Content-Type': 'application/json',
                                          if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}'
                                        };
                                        final body = jsonEncode({'title': newTitle});
                                        final resp = await http.patch(uri, headers: headers, body: body);
                                        if (resp.statusCode == 200) {
                                          setModalState(() {
                                            s['title'] = newTitle;
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Chat renamed'),
                                                backgroundColor: AppColors.accentColor,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Rename failed: ${resp.statusCode}')),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Rename error: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  _sessionId = s['_id'];
                                  await _loadMessagesForSession(_sessionId!);
                                },
                              );
                            },
                            separatorBuilder: (_, __) => const Divider(height: 1),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Open chat history error: $e');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundColor,
            title: Text(
              'About Rebirth',
              style: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Rebirth is your personal transformation companion, helping you build better habits, achieve your goals, and become the best version of yourself through AI-powered conversations.',
              style: TextStyle(color: AppColors.textColor, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: AppColors.accentColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundColor,
            title: Text(
              'Logout',
              style: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: AppColors.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Menu Icon
                  GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.menu,
                        color: AppColors.textColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // App Title
                  Text(
                    'Rebirth',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Profile Icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.textColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages Area
            Expanded(
              child:
                  _messages.isEmpty
                      ? Container()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index]);
                          } else {
                            // Typing indicator
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.accentColor,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Typing...',
                                      style: TextStyle(
                                        color: AppColors.textColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
            ),

            // Chat Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: AppColors.textColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Text Input Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: AutoHideKeyboard(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle: TextStyle(
                              color: AppColors.textColor.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: AppColors.accentColor,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
