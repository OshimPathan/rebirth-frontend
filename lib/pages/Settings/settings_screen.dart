import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/services/theme_service.dart';
import 'package:rebirth_draft_2/services/auth_service.dart';
import 'package:rebirth_draft_2/pages/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    });
  }

  Future<void> _saveSettings({
    bool? notifications,
    bool? sound,
    bool? haptic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (notifications != null) {
      await prefs.setBool('notifications_enabled', notifications);
      setState(() => _notificationsEnabled = notifications);
    }
    if (sound != null) {
      await prefs.setBool('sound_enabled', sound);
      setState(() => _soundEnabled = sound);
    }
    if (haptic != null) {
      await prefs.setBool('haptic_enabled', haptic);
      setState(() => _hapticEnabled = haptic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.textColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader(colors, 'Appearance'),
          const SizedBox(height: 8),
          _buildSettingsCard(colors, [_buildThemeTile(colors, themeService)]),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(colors, 'Notifications'),
          const SizedBox(height: 8),
          _buildSettingsCard(colors, [
            _buildSwitchTile(
              colors,
              'Push Notifications',
              'Receive reminders and updates',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) => _saveSettings(notifications: value),
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildSwitchTile(
              colors,
              'Sound',
              'Play sounds for messages',
              Icons.volume_up_outlined,
              _soundEnabled,
              (value) => _saveSettings(sound: value),
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildSwitchTile(
              colors,
              'Haptic Feedback',
              'Vibrate on interactions',
              Icons.vibration,
              _hapticEnabled,
              (value) => _saveSettings(haptic: value),
            ),
          ]),
          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader(colors, 'Privacy & Data'),
          const SizedBox(height: 8),
          _buildSettingsCard(colors, [
            _buildNavigationTile(
              colors,
              'Data Usage',
              'Manage your data and storage',
              Icons.data_usage,
              () => _showDataUsageDialog(colors),
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildNavigationTile(
              colors,
              'Export Data',
              'Download your chat history',
              Icons.download_outlined,
              () => _showExportDialog(colors),
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildNavigationTile(
              colors,
              'Clear Chat History',
              'Delete all conversations',
              Icons.delete_outline,
              () => _showClearHistoryDialog(colors),
              isDestructive: true,
            ),
          ]),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader(colors, 'Support'),
          const SizedBox(height: 8),
          _buildSettingsCard(colors, [
            _buildNavigationTile(
              colors,
              'Help & FAQ',
              'Get answers to common questions',
              Icons.help_outline,
              () {},
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildNavigationTile(
              colors,
              'Contact Support',
              'Reach out to our team',
              Icons.email_outlined,
              () {},
            ),
            Divider(color: colors.hintColor.withOpacity(0.2), height: 1),
            _buildNavigationTile(
              colors,
              'About',
              'Version 1.0.0',
              Icons.info_outline,
              () => _showAboutDialog(colors),
            ),
          ]),
          const SizedBox(height: 24),

          // Logout Button
          _buildSettingsCard(colors, [
            _buildNavigationTile(
              colors,
              'Log Out',
              'Sign out of your account',
              Icons.logout,
              () => _showLogoutDialog(colors),
              isDestructive: true,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeColors colors, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeTile(ThemeColors colors, ThemeService themeService) {
    return ListTile(
      leading: Icon(
        themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: colors.accentColor,
      ),
      title: Text('Theme', style: TextStyle(color: colors.textColor)),
      subtitle: Text(
        themeService.isDarkMode ? 'Dark Mode' : 'Light Mode',
        style: TextStyle(color: colors.hintColor, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: themeService.isDarkMode,
        onChanged: (value) {
          themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        },
        activeColor: colors.accentColor,
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeColors colors,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: colors.accentColor),
      title: Text(title, style: TextStyle(color: colors.textColor)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.hintColor, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: colors.accentColor,
      ),
    );
  }

  Widget _buildNavigationTile(
    ThemeColors colors,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final titleColor = isDestructive ? colors.errorColor : colors.textColor;
    final iconColor = isDestructive ? colors.errorColor : colors.accentColor;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.hintColor, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.hintColor),
      onTap: onTap,
    );
  }

  void _showDataUsageDialog(ThemeColors colors) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.surfaceColor,
            title: Text(
              'Data Usage',
              style: TextStyle(color: colors.textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUsageRow(colors, 'Chat History', '~2.5 MB'),
                const SizedBox(height: 8),
                _buildUsageRow(colors, 'Cached Data', '~1.2 MB'),
                const SizedBox(height: 8),
                _buildUsageRow(colors, 'Settings', '~0.1 MB'),
                const Divider(height: 24),
                _buildUsageRow(colors, 'Total', '~3.8 MB', isBold: true),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildUsageRow(
    ThemeColors colors,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.accentColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showExportDialog(ThemeColors colors) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.surfaceColor,
            title: Text(
              'Export Data',
              style: TextStyle(color: colors.textColor),
            ),
            content: Text(
              'Your data will be exported as a JSON file and saved to your device.',
              style: TextStyle(color: colors.hintColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export started...')),
                  );
                },
                child: const Text('Export'),
              ),
            ],
          ),
    );
  }

  void _showClearHistoryDialog(ThemeColors colors) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.surfaceColor,
            title: Text(
              'Clear Chat History',
              style: TextStyle(color: colors.errorColor),
            ),
            content: Text(
              'This will permanently delete all your conversations. This action cannot be undone.',
              style: TextStyle(color: colors.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.errorColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat history cleared')),
                  );
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(ThemeColors colors) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.surfaceColor,
            title: Text(
              'About Rebirth',
              style: TextStyle(color: colors.textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rebirth - Mental Health Support',
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: colors.hintColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'An intelligent mental health chatbot that uses BERT-based emotion detection and Google Gemini LLM to provide empathetic, context-aware support.',
                  style: TextStyle(color: colors.textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2026 Rebirth Team',
                  style: TextStyle(color: colors.hintColor, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(ThemeColors colors) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.surfaceColor,
            title: Text('Log Out', style: TextStyle(color: colors.textColor)),
            content: Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: colors.hintColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.errorColor,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
