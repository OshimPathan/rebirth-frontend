import 'package:flutter/material.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/services/auth_service.dart';
import 'package:rebirth_draft_2/services/onboarding_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:rebirth_draft_2/pages/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final OnboardingService _onboardingService = OnboardingService();
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _saving = false;
  File? _selectedImageFile;
  List<dynamic> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (_authService.user != null) {
        setState(() {
          _user = _authService.user;
          _loading = false;
        });
        _syncOnboardingFromUser();
        _loadGoals();
        return;
      }

      final result = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = result['success'] ? result['user'] : null;
          _loading = false;
        });
        _syncOnboardingFromUser();
        _loadGoals();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadGoals() async {
    final goals = await _authService.getGoals();
    if (mounted) setState(() => _goals = goals);
  }

  void _syncOnboardingFromUser() {
    final onboarding = _user?['onboarding'] as Map<String, dynamic>?;
    if (onboarding == null) return;
    final personal = onboarding['personalInfo'] as Map<String, dynamic>? ?? {};
    final transformation =
        onboarding['transformation'] as Map<String, dynamic>? ?? {};
    _onboardingService.updateBasicInfo(
      age: (personal['age'] ?? '').toString(),
      gender: (personal['gender'] ?? '').toString(),
      occupation: (personal['occupation'] ?? '').toString(),
      location: (personal['location'] ?? '').toString(),
    );
    if (transformation['idealSelfDescription'] != null) {
      _onboardingService.updateIdealSelf(
        transformation['idealSelfDescription'],
      );
    }
    if (transformation['qualitiesToBuild'] != null &&
        (transformation['qualitiesToBuild'] as List).isNotEmpty) {
      _onboardingService.updateQualitiesToBuild(
        (transformation['qualitiesToBuild'] as List).join(', '),
      );
    }
    if (transformation['negativeHabits'] != null &&
        (transformation['negativeHabits'] as List).isNotEmpty) {
      _onboardingService.updateNegativeHabits(
        (transformation['negativeHabits'] as List).join(', '),
      );
    }
    if (transformation['thingsToRemove'] != null &&
        (transformation['thingsToRemove'] as List).isNotEmpty) {
      _onboardingService.updateAntiVision(
        (transformation['thingsToRemove'] as List).join(', '),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
      });
      // In this example we do not upload binary to backend; we could upload to storage and save URL.
      // As a placeholder, we store a local file path (not ideal for multi-device). Adjust as needed.
    }
  }

  Future<void> _saveProfile({String? name}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String? pictureUrl;
      if (_selectedImageFile != null) {
        // TODO: Upload to your storage and obtain a URL. For now, leave as null or local path.
        pictureUrl = _selectedImageFile!.path;
      }
      final res = await _authService.updateProfile(
        name: name,
        profilePicture: pictureUrl,
      );
      if (mounted) {
        setState(() {
          _user = res['success'] ? res['user'] : _user;
          _saving = false;
        });
        if (!(res['success'] == true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to update profile'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentColor,
                                      borderRadius: BorderRadius.circular(40),
                                      image:
                                          (_user?['profilePicture'] != null &&
                                                  (_user?['profilePicture']
                                                          as String)
                                                      .isNotEmpty)
                                              ? DecorationImage(
                                                image:
                                                    (_user!['profilePicture']
                                                            .toString()
                                                            .startsWith('http')
                                                        ? NetworkImage(
                                                          _user!['profilePicture'],
                                                        )
                                                        : FileImage(
                                                              File(
                                                                _user!['profilePicture'],
                                                              ),
                                                            )
                                                            as ImageProvider),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                    child:
                                        (_user?['profilePicture'] == null ||
                                                (_user?['profilePicture']
                                                        as String)
                                                    .isEmpty)
                                            ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 40,
                                            )
                                            : null,
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: InkWell(
                                      onTap: _pickProfileImage,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceColor,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: AppColors.textColor
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color: AppColors.textColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_user?['name'] ?? 'User').toString(),
                                      style: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_user?['email'] ?? 'user@example.com')
                                          .toString(),
                                      style: TextStyle(
                                        color: AppColors.textColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Basic Info',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoRow('Name', (_user?['name'] ?? '').toString()),
                          _infoRow(
                            'Email',
                            (_user?['email'] ?? '-').toString(),
                          ),
                          _infoRow(
                            'Joined',
                            _formatJoinedDate(_user?['createdAt']),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'Onboarding',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Personal Info
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Age',
                                  style: TextStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _onboardingService.currentData.age,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: AppColors.textColor),
                                  onChanged:
                                      (v) => _onboardingService.updateBasicInfo(
                                        age: v,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Gender',
                                  style: TextStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue:
                                      _onboardingService
                                              .currentData
                                              .gender
                                              .isEmpty
                                          ? null
                                          : _onboardingService
                                              .currentData
                                              .gender,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'non-binary',
                                      child: Text('Non-binary'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'prefer_not_to_say',
                                      child: Text('Prefer not to say'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged:
                                      (v) => _onboardingService.updateBasicInfo(
                                        gender: v ?? '',
                                      ),
                                  dropdownColor: AppColors.backgroundColor,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Occupation',
                                  style: TextStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _onboardingService.currentData.occupation,
                                  style: TextStyle(color: AppColors.textColor),
                                  onChanged:
                                      (v) => _onboardingService.updateBasicInfo(
                                        occupation: v,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Location',
                                  style: TextStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _onboardingService.currentData.location,
                                  style: TextStyle(color: AppColors.textColor),
                                  onChanged:
                                      (v) => _onboardingService.updateBasicInfo(
                                        location: v,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _editableMultiline(
                            'Ideal Self',
                            _onboardingService.currentData.idealSelf,
                            (v) {
                              _onboardingService.updateIdealSelf(v);
                            },
                          ),
                          _editableMultiline(
                            'Qualities to Build',
                            _onboardingService.currentData.qualitiesToBuild,
                            (v) {
                              _onboardingService.updateQualitiesToBuild(v);
                            },
                          ),
                          _editableMultiline(
                            'Negative Habits',
                            _onboardingService.currentData.negativeHabits,
                            (v) {
                              _onboardingService.updateNegativeHabits(v);
                            },
                          ),
                          _editableMultiline(
                            'Things to Remove',
                            _onboardingService.currentData.antiVision,
                            (v) {
                              _onboardingService.updateAntiVision(v);
                            },
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final res =
                                      await _onboardingService.saveToBackend();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['success'] == true
                                            ? 'Onboarding saved'
                                            : (res['message'] ??
                                                'Failed to save onboarding'),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Save Onboarding'),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'Goals',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._goals.map((g) {
                            final Map<String, dynamic> goal =
                                Map<String, dynamic>.from(g);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                goal['title']?.toString() ?? '-',
                                style: TextStyle(color: AppColors.textColor),
                              ),
                              subtitle: Text(
                                (goal['category']?.toString() ?? 'other') +
                                    (goal['status'] != null
                                        ? ' • ${goal['status']}'
                                        : ''),
                                style: TextStyle(
                                  color: AppColors.textColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColors.textColor,
                                    ),
                                    onPressed: () => _editGoal(goal),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed:
                                        () => _deleteGoal(
                                          goal['_id']?.toString() ?? '',
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _addGoal,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Goal'),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'AI Insights',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if ((_user?['aiInsights'] as List?) != null &&
                              (_user!['aiInsights'] as List).isNotEmpty)
                            Column(
                              children:
                                  (List<Map<String, dynamic>>.from(
                                    _user!['aiInsights'] as List,
                                  )).map((ins) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        ins['insight']?.toString() ?? '',
                                        style: TextStyle(
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${ins['category']} • ${(ins['confidence'] ?? 0) * 100}%',
                                        style: TextStyle(
                                          color: AppColors.textColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            )
                          else
                            Text(
                              _onboardingService.aiGeneratedSummary.isNotEmpty
                                  ? _onboardingService.aiGeneratedSummary
                                  : 'No insights generated yet.',
                              style: TextStyle(color: AppColors.textColor),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () async {
                                final res =
                                    await _onboardingService.sendToGemini();
                                if (!mounted) return;
                                if (res['success'] == true) {
                                  setState(() {});
                                }
                              },
                              child: const Text('Generate Insights'),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'Actions',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed:
                                    _saving ? null : () => _saveProfile(),
                                child:
                                    _saving
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text('Save Profile'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () async {
                                  await _authService.logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textColor)),
          ),
        ],
      ),
    );
  }

  String _formatJoinedDate(dynamic createdAt) {
    if (createdAt == null) return '-';
    try {
      final dt =
          createdAt is DateTime
              ? createdAt
              : DateTime.tryParse(createdAt.toString());
      if (dt == null) return '-';
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return createdAt.toString();
    }
  }

  Widget _editableMultiline(
    String label,
    String initial,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initial,
              maxLines: null,
              style: TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color: AppColors.textColor.withValues(alpha: 0.5),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGoal() async {
    final titleController = TextEditingController();
    String category = 'other';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text('New Goal', style: TextStyle(color: AppColors.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: AppColors.textColor),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: AppColors.backgroundColor,
                style: TextStyle(color: AppColors.textColor),
                items: const [
                  DropdownMenuItem(
                    value: 'mental_health',
                    child: Text('Mental Health'),
                  ),
                  DropdownMenuItem(
                    value: 'personal_growth',
                    child: Text('Personal Growth'),
                  ),
                  DropdownMenuItem(
                    value: 'relationships',
                    child: Text('Relationships'),
                  ),
                  DropdownMenuItem(value: 'career', child: Text('Career')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => category = v ?? 'other',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final created = await _authService.createGoal(
        title: titleController.text.trim(),
        category: category,
      );
      if (created != null && mounted) {
        setState(() => _goals.add(created));
      }
    }
  }

  Future<void> _editGoal(Map<String, dynamic> goal) async {
    final titleController = TextEditingController(
      text: goal['title']?.toString() ?? '',
    );
    String category = (goal['category']?.toString() ?? 'other');
    String status = (goal['status']?.toString() ?? 'active');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Edit Goal',
            style: TextStyle(color: AppColors.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: AppColors.textColor),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: AppColors.backgroundColor,
                style: TextStyle(color: AppColors.textColor),
                items: const [
                  DropdownMenuItem(
                    value: 'mental_health',
                    child: Text('Mental Health'),
                  ),
                  DropdownMenuItem(
                    value: 'personal_growth',
                    child: Text('Personal Growth'),
                  ),
                  DropdownMenuItem(
                    value: 'relationships',
                    child: Text('Relationships'),
                  ),
                  DropdownMenuItem(value: 'career', child: Text('Career')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: AppColors.backgroundColor,
                style: TextStyle(color: AppColors.textColor),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(value: 'paused', child: Text('Paused')),
                ],
                onChanged: (v) => status = v ?? status,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final updated = await _authService.updateGoal(
        goal['_id']?.toString() ?? '',
        {
          'title': titleController.text.trim(),
          'category': category,
          'status': status,
        },
      );
      if (updated != null && mounted) {
        setState(() {
          final idx = _goals.indexWhere((g) => g['_id'] == goal['_id']);
          if (idx >= 0) _goals[idx] = updated;
        });
      }
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    if (goalId.isEmpty) return;
    final ok = await _authService.deleteGoal(goalId);
    if (ok && mounted)
      setState(() => _goals.removeWhere((g) => g['_id'] == goalId));
  }
}
