import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

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
              color: Colors.white.withOpacity(0.2),
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
class TeacherProfileDetailScreen extends StatefulWidget {
  const TeacherProfileDetailScreen({super.key});

  @override
  State<TeacherProfileDetailScreen> createState() => _TeacherProfileDetailScreenState();
}

class _TeacherProfileDetailScreenState extends State<TeacherProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late String _designation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final teacher = appState.teacher;
    _nameController = TextEditingController(text: teacher?.name ?? '');
    _emailController = TextEditingController(text: teacher?.email ?? '');
    _mobileController = TextEditingController(text: teacher?.mobile ?? '');
    _designation = teacher?.designation ?? 'Class Teacher';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile details updated successfully (Demo Mode)'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('teacherProfile'), AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  teacher?.name.isNotEmpty == true ? teacher!.name[0] : 'T',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.secondary,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Camera capture mock triggered')),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            teacher?.employeeId ?? '',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs Card
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
                          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            validator: (val) => val?.isEmpty == true ? 'Please enter name' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter Full Name',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _designation,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'Class Teacher', child: Text('Class Teacher')),
                                  DropdownMenuItem(value: 'Subject Teacher', child: Text('Subject Teacher')),
                                ],
                                onChanged: (val) => setState(() => _designation = val ?? 'Class Teacher'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val?.contains('@') == false ? 'Please enter valid email' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter Email',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            validator: (val) => val?.isEmpty == true ? 'Please enter phone' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter Mobile Phone',
                              fillColor: const Color(0xFFF5F7FA),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

// 2. CHANGE PASSWORD SCREEN
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

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
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password updated successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('changePassword'), AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          const Text('Current Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _currentController,
                            obscureText: _obscureCurrent,
                            validator: (val) => val == null || val.length < 4 ? 'Enter valid password' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter Current Password',
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
                            validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
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
                          const SizedBox(height: 16),

                          const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            validator: (val) => val != _newController.text ? 'Passwords do not match' : null,
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
                      onPressed: _isSaving ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

// 3. FEEDBACK SCREEN
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  String _category = 'Feature Request';
  int _rating = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter comments before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text('Feedback Sent'),
              ],
            ),
            content: const Text('Thank you! Your feedback has been sent to our developer team successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context); // Pop screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('feedback'), AppColors.secondary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        const Text('Rate this Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _rating = index + 1),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        const Text('Feedback Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _category,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                                DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                                DropdownMenuItem(value: 'Suggestion', child: Text('General Suggestion')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) => setState(() => _category = val ?? 'Feature Request'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text('Detailed Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _commentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Share your suggestions or describe the issue you encountered...',
                            fillColor: const Color(0xFFF5F7FA),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Intro Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Veyho School Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Version 2.4.1 (Stable Build)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),
                        const Text(
                          'Veyho School Portal empowers administrators and educators with tools to record attendance, broadcast class bulletins, manage student lists, and maintain seamless relationships with parents.',
                          style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technical specifications
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
                        const Text('Release Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        _buildReleaseLogItem('v2.4.1', 'Fixed translation rendering in Marathi context.'),
                        _buildReleaseLogItem('v2.4.0', 'Introduced dynamic multi-class support for Subject Teachers.'),
                        _buildReleaseLogItem('v2.3.0', 'Implemented chat backup and local offline database cache.'),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 16),
                        const Text('Support Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text('For assistance, email us at tech-support@veyho.com or raise a ticket inside the Help Desk.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '© 2026 Veyho Technologies. All rights reserved.',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseLogItem(String version, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$version — ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
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
  final List<Map<String, String>> _allFaqs = [
    {
      'q': 'How do I change application language?',
      'a': 'Go to Profile > Language. Select English, Hindi, or Marathi to change the language settings instantly.'
    },
    {
      'q': 'How do I mark daily attendance?',
      'a': 'From the Homepage, click the "Attendance" card. Select Present/Absent for each student, click "Submit", verify the details on the summary page, and tap "Confirm".'
    },
    {
      'q': 'What is the difference between Class Teacher and Subject Teacher?',
      'a': 'Class Teachers are assigned to one grade (e.g. Grade 3-B) and can submit attendance and announcements. Subject Teachers instruct across multiple classes and can submit homework and homework reviews.'
    },
    {
      'q': 'How do I send homework details to parents?',
      'a': 'Click "Class Update" on the dashboard, toggle the switch to "Homework", enter details, select the target class and subject, attach documents if any, and tap "Post Update".'
    },
    {
      'q': 'How do I edit submitted attendance?',
      'a': 'After submitting attendance, you can edit it by opening the dashboard, clicking "Attendance", and then clicking "Correct Attendance" to re-record individual student states.'
    },
    {
      'q': 'How do I upload my profile picture?',
      'a': 'Go to Profile > Teacher Profile. Tap the camera icon overlaying your avatar to upload a profile picture from camera or gallery.'
    },
  ];
  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = List.from(_allFaqs);
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = _allFaqs.where((f) {
        return f['q']!.toLowerCase().contains(query) || f['a']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildAppBar(context, appState.translate('help'), AppColors.secondary),
          
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
                    : null,
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // FAQ Expansion Tiles
          Expanded(
            child: _filteredFaqs.isEmpty
                ? const Center(child: Text('No FAQs found matching your query.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: const Icon(Icons.help_outline, color: AppColors.secondary),
                            title: Text(
                              faq['q']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                child: Text(
                                  faq['a']!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
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
                        activeColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      SwitchListTile(
                        value: _emailAlerts,
                        title: const Text('Email Summaries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Receive end-of-day homework posts reports', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeColor: AppColors.secondary,
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
                        activeColor: AppColors.secondary,
                        onChanged: (val) => setState(() => _biometricLock = val),
                      ),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      SwitchListTile(
                        value: _offlineCache,
                        title: const Text('Local Data Caching', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: const Text('Encrypt and cache files locally for offline use', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeColor: AppColors.secondary,
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
                    activeColor: AppColors.secondary,
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
