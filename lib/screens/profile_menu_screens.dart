import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/device_info_service.dart';
import '../services/notification_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../widgets/veyho_logo.dart';

// Helper custom app bar widget to maintain style consistency
Widget _buildAppBar(BuildContext context, String title, Color color) {
  return Container(
    color: color,
    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// 1. TEACHER PROFILE DETAIL SCREEN
class TeacherProfileDetailScreen extends StatelessWidget {
  const TeacherProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final designationText = teacher?.designation ??
        ((teacher?.allClassTeacherDisplayNames.isNotEmpty == true)
            ? 'Class Teacher'
            : 'Subject Teacher');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('teacherProfile'), AppColors.primary),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Picture Avatar Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                          backgroundImage: appState.profilePic != null
                              ? MemoryImage(base64Decode(appState.profilePic!))
                              : (teacher != null && teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty
                                  ? NetworkImage(teacher.photoUrl!)
                                  : null) as ImageProvider?,
                          child: (appState.profilePic == null && (teacher?.photoUrl == null || teacher!.photoUrl!.isEmpty))
                              ? Text(
                                  teacher != null && teacher.name.isNotEmpty ? teacher.name[0] : 'T',
                                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          teacher?.name ?? 'Teacher',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$designationText • ${teacher?.employeeId ?? ""}',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Read-Only Profile Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Profile Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyRow('School', appState.currentSchoolName),
                        _buildReadOnlyRow(appState.translate('employeeId'), teacher?.employeeId ?? 'N/A'),
                        _buildReadOnlyRow('Full Name', teacher?.name ?? 'N/A'),
                        _buildReadOnlyRow('Designation', designationText),
                        _buildReadOnlyRow(appState.translate('email'), teacher?.email ?? 'N/A'),
                        _buildReadOnlyRow(appState.translate('mobile'), teacher?.mobile ?? 'N/A'),
                        ...() {
                          final ctClasses = teacher?.allClassTeacherDisplayNames ?? const <String>[];
                          final extraClasses = (teacher?.assignedClasses ?? const <String>[])
                              .where((c) => c.isNotEmpty && !ctClasses.contains(c))
                              .toList();
                          return [
                            if (ctClasses.length == 1)
                              _buildReadOnlyRow(appState.translate('assignedClass'), ctClasses.first)
                            else if (ctClasses.length > 1)
                              _buildReadOnlyRow(appState.translate('assignedClasses'), ctClasses.join(', ')),
                            if (extraClasses.isNotEmpty)
                              _buildReadOnlyRow(
                                ctClasses.isEmpty ? appState.translate('assignedClasses') : 'Subject Classes',
                                extraClasses.join(', '),
                              ),
                          ];
                        }(),
                        _buildReadOnlyRow(
                          appState.translate('subjects'),
                          teacher?.subjects.isNotEmpty == true ? teacher!.subjects.join(', ') : 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Administrative Verification Note
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB2DFDB)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Teacher profile details are verified and managed by school administration.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF004D40), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. CHANGE PASSWORD SCREEN
class ChangePasswordScreen extends StatefulWidget {
  final bool isFirstLogin;
  const ChangePasswordScreen({super.key, this.isFirstLogin = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _newController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _hasMinLength(String pwd) => pwd.length >= 8;
  bool _hasUppercase(String pwd) => pwd.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String pwd) => pwd.contains(RegExp(r'[a-z]'));
  bool _hasNumber(String pwd) => pwd.contains(RegExp(r'[0-9]'));
  bool _hasSymbol(String pwd) => pwd.contains(RegExp(r'[^A-Za-z0-9\s]'));

  int _calculateStrength(String pwd) {
    int score = 0;
    if (_hasMinLength(pwd)) score++;
    if (_hasUppercase(pwd)) score++;
    if (_hasLowercase(pwd)) score++;
    if (_hasNumber(pwd)) score++;
    if (_hasSymbol(pwd)) score++;
    return score;
  }

  Future<void> _changePassword(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;

    final currentPwd = _currentController.text.trim();
    final newPwd = _newController.text.trim();

    if (_calculateStrength(newPwd) < 5) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please satisfy all password security requirements.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentPwd == newPwd) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password cannot be the same as current password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await appState.changePassword(
      currentPassword: currentPwd,
      newPassword: newPwd,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (error == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isFirstLogin
                ? 'Permanent password set successfully! Welcome to Veyho.'
                : 'Password updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (widget.isFirstLogin) {
          NotificationNavigationService.requestPermissionAndRegister();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final newPwd = _newController.text;
    final strength = _calculateStrength(newPwd);

    Color strengthColor = Colors.red;
    String strengthText = 'Weak';
    if (strength == 5) {
      strengthColor = AppColors.success;
      strengthText = 'Strong';
    } else if (strength >= 3) {
      strengthColor = Colors.amber.shade700;
      strengthText = 'Moderate';
    }

    return PopScope(
      canPop: !widget.isFirstLogin,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            _buildCustomAppBar(
              context,
              widget.isFirstLogin ? 'Set Permanent Password' : appState.translate('changePassword'),
            AppColors.primary,
            showBack: !widget.isFirstLogin,
            onBack: () => Navigator.pop(context),
            onLogout: widget.isFirstLogin
                ? () async {
                    await appState.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                : null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isFirstLogin)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You are currently logged in with a temporary password. Please set your own secure password to proceed.",
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstLogin ? 'Current Temporary Password' : 'Current Password',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _currentController,
                            obscureText: _obscureCurrent,
                            validator: (val) => val == null || val.isEmpty
                                ? (widget.isFirstLogin ? 'Enter temporary password' : 'Enter current password')
                                : null,
                            decoration: InputDecoration(
                              hintText: widget.isFirstLogin ? 'Enter Temporary Password' : 'Enter Current Password',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _newController,
                            obscureText: _obscureNew,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter new password';
                              if (val.length < 8) return 'Password must be at least 8 characters';
                              if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must include at least 1 uppercase letter';
                              if (!RegExp(r'[a-z]').hasMatch(val)) return 'Must include at least 1 lowercase letter';
                              if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must include at least 1 number';
                              if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(val)) return 'Must include at least 1 special character';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter New Password',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),

                          // Password requirement helper (clean 1-line format like Parent App)
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final isValid = strength == 5;
                              final color = isValid ? AppColors.success : (newPwd.isNotEmpty ? Colors.grey.shade700 : Colors.grey);
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    isValid ? Icons.check_circle : Icons.info_outline,
                                    size: 14,
                                    color: color,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isValid
                                          ? 'Strong password requirements met'
                                          : 'Min 8 chars with uppercase, lowercase, number & special char',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          // Strength Meter
                          if (newPwd.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Password Strength:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(strengthText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strengthColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength / 5.0,
                                minHeight: 4,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please re-enter new password';
                              if (val != _newController.text) return 'Passwords do not match';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Re-enter New Password',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _changePassword(appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              widget.isFirstLogin ? 'Set Password & Continue' : 'Update Password',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCustomAppBar(
    BuildContext context,
    String title,
    Color bg, {
    bool showBack = true,
    VoidCallback? onBack,
    VoidCallback? onLogout,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (onLogout != null)
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.white70, size: 16),
              label: const Text('Logout', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// 3. FEEDBACK SCREEN
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  String _selectedCategory = 'FEATURE_REQUEST';
  int _rating = 0; // 0 = unselected
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = const [
    {'key': 'FEATURE_REQUEST', 'label': 'featureRequest', 'icon': Icons.lightbulb_outline},
    {'key': 'BUG_REPORT', 'label': 'bugReport', 'icon': Icons.bug_report_outlined},
    {'key': 'SUGGESTION', 'label': 'suggestion', 'icon': Icons.chat_bubble_outline},
    {'key': 'OTHER', 'label': 'other', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _ratingCaption(int r, AppState state) {
    switch (r) {
      case 1:
        return state.translate('ratingPoor');
      case 2:
        return state.translate('ratingFair');
      case 3:
        return state.translate('ratingGood');
      case 4:
        return state.translate('ratingVeryGood');
      case 5:
        return state.translate('ratingExcellent');
      default:
        return '';
    }
  }

  Future<void> _launchStoreReview() async {
    const androidPackage = 'com.veyho.teacher';
    const appleAppId = '0000000000';

    final Uri storeUri;
    final Uri fallbackUri;

    if (Platform.isIOS) {
      storeUri = Uri.parse('itms-apps://itms-apps/app/id$appleAppId?action=write-review');
      fallbackUri = Uri.parse('https://apps.apple.com/app/id$appleAppId');
    } else {
      storeUri = Uri.parse('market://details?id=$androidPackage');
      fallbackUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackage');
    }

    try {
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch store URL: $e');
    }
  }

  Future<void> _submitFeedback() async {
    final text = _commentController.text.trim();
    final appState = Provider.of<AppState>(context, listen: false);

    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.translate('minFeedbackLength')),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final telemetry = await DeviceInfoService.getDeviceTelemetry();
      final body = {
        'category': _selectedCategory,
        if (_rating > 0) 'rating': _rating,
        'message': text,
        'userName': appState.teacher?.name,
        'userContact': appState.teacher?.mobile ?? appState.teacher?.email,
        'appVersion': telemetry.appVersion,
        'platform': telemetry.platform,
        'deviceModel': telemetry.deviceModel,
        'osVersion': telemetry.osVersion,
      };

      await ApiService.post('/feedback', body);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final isHappyUser = _rating >= 4 && _selectedCategory != 'BUG_REPORT';

      if (isHappyUser) {
        // Smart store redirection dialog
        final storePrompt = Platform.isIOS
            ? appState.translate('rateOnAppStore')
            : appState.translate('rateOnGooglePlay');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.secondary, size: 24),
                const SizedBox(width: 8),
                Text(appState.translate('lovingApp'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(storePrompt, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(appState.translate('later'), style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  _launchStoreReview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(appState.translate('rateApp'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        // Standard confirmation dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 8),
                Text(appState.translate('feedbackReceived'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(appState.translate('feedbackThankYou'), style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(appState.translate('ok'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('feedback'), AppColors.primary),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Compact 2-line advisory banner (~50dp)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appState.translate('feedbackBannerTitle'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appState.translate('feedbackAdvisoryNote'),
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), height: 1.25),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector Chips
                          Text(
                            appState.translate('selectCategory'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['key'];
                              return ChoiceChip(
                                avatar: Icon(
                                  cat['icon'] as IconData,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                                label: Text(
                                  appState.translate(cat['label'] as String),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF374151),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.secondary,
                                backgroundColor: const Color(0xFFF9FAFB),
                                side: BorderSide(
                                  color: isSelected ? AppColors.secondary : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedCategory = cat['key'] as String);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Rating Stars
                          Text(
                            appState.translate('rateYourExperience'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () => setState(() => _rating = index + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                  ),
                                );
                              }),
                              if (_rating > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _ratingCaption(_rating, appState),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Detailed Feedback Text Area
                          Text(
                            appState.translate('feedbackDetails'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _commentController,
                            maxLines: 5,
                            maxLength: 1000,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: appState.translate('typeFeedbackHere'),
                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                              fillColor: const Color(0xFFF9FAFB),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(appState.translate('submitFeedback'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. ABOUT US SCREEN
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchExternalUrl(
    BuildContext context,
    String urlString, {
    required String copyFallbackText,
    required AppState appState,
  }) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: copyFallbackText));
        if (context.mounted) {
          final msg = appState.translate('aboutUs_copied').replaceAll('{text}', copyFallbackText);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: copyFallbackText));
      if (context.mounted) {
        final msg = appState.translate('aboutUs_copied').replaceAll('{text}', copyFallbackText);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openLegalDocument(
    BuildContext context,
    String title,
    String assetPath,
    String docTypeKey,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    String content = '';

    final activeDocs = appState.activeLegalDocs;
    if (activeDocs != null && activeDocs[docTypeKey] != null) {
      final doc = activeDocs[docTypeKey] as Map<String, dynamic>;
      if (doc['contentMarkdown'] != null && doc['contentMarkdown'].toString().trim().isNotEmpty) {
        content = doc['contentMarkdown'].toString();
      }
    }

    if (content.isEmpty) {
      try {
        content = await rootBundle.loadString(assetPath);
      } catch (e) {
        content = 'Failed to load document.';
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF4B5563)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('aboutUs'), AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Identity & Version Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        const VeyhoLogo(fontSize: 38),
                        const SizedBox(height: 12),
                        Text(
                          appState.translate('aboutUs_teacher_title'),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            appState.translate('aboutUs_version'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Mission & Purpose Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.translate('aboutUs_heading'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.translate('aboutUs_tagline'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appState.translate('aboutUs_mission'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appState.translate('aboutUs_teacher_role'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Connect & Support Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.translate('aboutUs_connect'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _launchExternalUrl(
                            context,
                            'https://www.veyho.com',
                            copyFallbackText: 'https://www.veyho.com',
                            appState: appState,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.language, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.translate('aboutUs_website'),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const Text(
                                        'www.veyho.com',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => _launchExternalUrl(
                            context,
                            'mailto:support@veyho.com?subject=Veyho%20Teacher%20App%20Inquiry',
                            copyFallbackText: 'support@veyho.com',
                            appState: appState,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.mail_outline, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.translate('aboutUs_email'),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const Text(
                                        'support@veyho.com',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appState.translate('aboutUs_location'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Legal & Compliance Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.translate('aboutUs_legal'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _openLegalDocument(
                            context,
                            appState.translate('aboutUs_terms'),
                            'assets/legal/terms_v1.md',
                            'terms',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    appState.translate('aboutUs_terms'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => _openLegalDocument(
                            context,
                            appState.translate('aboutUs_privacy'),
                            'assets/legal/privacy_v1.md',
                            'privacy',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    appState.translate('aboutUs_privacy'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Copyright
                  Center(
                    child: Text(
                      appState.translate('aboutUs_copyright'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. HELP SCREEN
class HelpFAQScreen extends StatefulWidget {
  const HelpFAQScreen({super.key});

  @override
  State<HelpFAQScreen> createState() => _HelpFAQScreenState();
}

class _HelpFAQScreenState extends State<HelpFAQScreen> {
  final _searchController = TextEditingController();
  bool _showAll = false;

  // 10 Module-focused FAQs (Top 5 Critical upfront, 5 Non-critical under Show More)
  final List<Map<String, dynamic>> _faqs = const [
    // 5 Critical FAQs
    {'qKey': 'faq_t1_q', 'aKey': 'faq_t1_a', 'isCritical': true},
    {'qKey': 'faq_t2_q', 'aKey': 'faq_t2_a', 'isCritical': true},
    {'qKey': 'faq_t3_q', 'aKey': 'faq_t3_a', 'isCritical': true},
    {'qKey': 'faq_t4_q', 'aKey': 'faq_t4_a', 'isCritical': true},
    {'qKey': 'faq_t7_q', 'aKey': 'faq_t7_a', 'isCritical': true},
    // 5 Non-Critical FAQs
    {'qKey': 'faq_t5_q', 'aKey': 'faq_t5_a', 'isCritical': false},
    {'qKey': 'faq_t6_q', 'aKey': 'faq_t6_a', 'isCritical': false},
    {'qKey': 'faq_t8_q', 'aKey': 'faq_t8_a', 'isCritical': false},
    {'qKey': 'faq_t9_q', 'aKey': 'faq_t9_a', 'isCritical': false},
    {'qKey': 'faq_t10_q', 'aKey': 'faq_t10_a', 'isCritical': false},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final query = _searchController.text.trim().toLowerCase();

    // When searching, filter across ALL 10 FAQs
    // When not searching, respect _showAll (5 critical vs all 10)
    final filteredFaqs = _faqs.where((faq) {
      if (query.isEmpty) {
        return _showAll ? true : (faq['isCritical'] == true);
      }
      final q = appState.translate(faq['qKey'] as String).toLowerCase();
      final a = appState.translate(faq['aKey'] as String).toLowerCase();
      return q.contains(query) || a.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('help'), AppColors.primary),
          
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: appState.translate('searchFaqsHint'),
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // FAQ Expansion Tiles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (filteredFaqs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        appState.translate('noFaqsFound'),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...filteredFaqs.map((faq) {
                    final qText = appState.translate(faq['qKey'] as String);
                    final aText = appState.translate(faq['aKey'] as String);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            qText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                aText,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // Need More Help / Support Card (ONLY visible when user clicks "Show More FAQs" and expands full list)
                if (_showAll) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.translate('needMoreHelp'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appState.translate('contactSchoolOffice'),
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // "Show More FAQs" / "Show Fewer FAQs" Toggle Button (Only when search is empty)
                if (query.isEmpty) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      icon: Icon(
                        _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      label: Text(
                        _showAll
                            ? appState.translate('showFewerFaqs')
                            : appState.translate('showMoreFaqs').replaceAll('{count}', '5'),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 6. PRIVACY & SECURITY SCREEN
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _biometricLock = true;
  bool _usageData = true;
  bool _offlineCache = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('privacySecurity'), AppColors.secondary),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Section 1: Notifications Settings
                _buildHeaderSection('Alert Notification Settings'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _pushNotifications,
                        title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Get instant alerts for parent messages', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      SwitchListTile(
                        value: _emailAlerts,
                        title: const Text('Email Summaries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Receive end-of-day homework posts reports', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _emailAlerts = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Security Lock Preferences
                _buildHeaderSection('Access Settings'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _biometricLock,
                        title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Protect login portal using Face ID / Touch ID', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _biometricLock = val),
                      ),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      SwitchListTile(
                        value: _offlineCache,
                        title: const Text('Local Data Caching', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Encrypt and cache files locally for offline use', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _offlineCache = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Diagnostic Preferences
                _buildHeaderSection('Privacy Consents'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    value: _usageData,
                    title: const Text('Anonymous Analytics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Share usage statistics to help us optimize UI speeds', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    activeThumbColor: AppColors.secondary,
                    onChanged: (val) => setState(() => _usageData = val),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your privacy is critical to us. Veyho complies with state guidelines for educational data protection.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.1),
      ),
    );
  }
}
