import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final allStudents = appState.students;

    // Check if user is a Class Teacher or has any assigned class-teacher section
    final bool isClassTeacher = teacher != null &&
        (teacher.designation == 'Class Teacher' ||
            teacher.allClassTeacherDisplayNames.isNotEmpty);

    // 1. SUBJECT TEACHER: Restricted Access View
    if (!isClassTeacher) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    appState.translate('healthRecords'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Restricted Body
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        appState.translate('healthTeacherAccessRestricted'),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appState.translate('healthTeacherAccessNote'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
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

    // 2. CLASS TEACHER: Student List View across all assigned class-teacher sections
    final assignedSectionIds = teacher.allClassTeacherSectionIds;
    final assignedClassNames = teacher.allClassTeacherDisplayNames;
    final assignedNormTokens = assignedClassNames.map(_normalize).where((t) => t.isNotEmpty).toSet();
    final String assignedClassesText = teacher.formatAssignedClasses(maxInline: 2);

    final classStudents = allStudents.where((s) {
      if (assignedSectionIds.isEmpty && assignedNormTokens.isEmpty) return true;
      if (s.sectionId != null && s.sectionId!.isNotEmpty && assignedSectionIds.contains(s.sectionId)) {
        return true;
      }
      final sNorm = _normalize(s.studentClass);
      return assignedNormTokens.contains(sNorm) ||
          assignedClassNames.any((c) => c.trim().toLowerCase() == s.studentClass.trim().toLowerCase());
    }).toList();

    // Filter students by search term (supports name, roll, GR, blood group, and class name)
    final filteredStudents = classStudents.where((s) {
      if (_searchTerm.trim().isEmpty) return true;
      final q = _searchTerm.toLowerCase().trim();
      final qNorm = _normalize(q);
      return s.name.toLowerCase().contains(q) ||
          s.rollNo.toLowerCase().contains(q) ||
          s.enrollmentNo.toLowerCase().contains(q) ||
          s.bloodGroup.toLowerCase().contains(q) ||
          s.studentClass.toLowerCase().contains(q) ||
          (qNorm.isNotEmpty && _normalize(s.studentClass).contains(qNorm));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // App Bar Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appState.translate('healthRecords'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (assignedClassesText.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          assignedClassesText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => appState.loadLiveData(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchTerm = val),
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: appState.translate('searchStudents'),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () {
                            setState(() {
                              _searchTerm = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ),

          // Total count chip row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filteredStudents.length} ${filteredStudents.length == 1 ? 'student' : 'students'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                const Icon(LucideIcons.heartPulse, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                const Text(
                  'Medical Profiles',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchTerm.isNotEmpty
                                ? 'No students found matching "$_searchTerm"'
                                : 'No students found in ${assignedClassesText.isNotEmpty ? assignedClassesText : 'assigned classes'}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentHealthDetailScreen(student: student),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      student.name.isNotEmpty
                                          ? student.name.substring(0, 1).toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name and details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if (student.studentClass.isNotEmpty) ...[
                                              Text(
                                                student.studentClass,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                            ],
                                            if (student.rollNo.isNotEmpty) ...[
                                              Text(
                                                'Roll: ${student.rollNo}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                            ],
                                            Text(
                                              'GR: ${student.enrollmentNo}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
                                ],
                              ),
                            ),
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

/// Detailed Health Record Screen replicating the Parent Mobile App layout
/// styled according to the Teacher Mobile App design system.
class StudentHealthDetailScreen extends StatefulWidget {
  final Student student;

  const StudentHealthDetailScreen({super.key, required this.student});

  @override
  State<StudentHealthDetailScreen> createState() => _StudentHealthDetailScreenState();
}

class _StudentHealthDetailScreenState extends State<StudentHealthDetailScreen> {
  late Future<HealthRecord> _healthFuture;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _healthFuture = appState.fetchStudentHealthRecord(widget.student);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final student = widget.student;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appState.translate('healthRecords'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _healthFuture = appState.fetchStudentHealthRecord(student, forceRefresh: true);
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<HealthRecord>(
              future: _healthFuture,
              builder: (context, snapshot) {
                final record = snapshot.data ??
                    appState.getCachedStudentHealth(student.id) ??
                    HealthRecord.empty(
                      student.id,
                      fullName: student.name,
                      bloodGroup: student.bloodGroup,
                      parentName: student.parentName,
                      parentMobile: student.parentMobile,
                    );

                final bool isLoading = snapshot.connectionState == ConnectionState.waiting && snapshot.data == null;

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final updated = await appState.fetchStudentHealthRecord(student, forceRefresh: true);
                    setState(() {
                      _healthFuture = Future.value(updated);
                    });
                  },
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Student Header Card
                          _buildStudentHeader(student, record.bloodGroup),
                          const SizedBox(height: 16),

                          // Section Title: Health Overview
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.heartPulse,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appState.translate('healthOverview'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 2. Health Overview Cards (2x2 Grid)
                          GridView.count(
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                            children: [
                            // Blood Group Card
                            _buildOverviewCard(
                              icon: LucideIcons.droplet,
                              iconColor: const Color(0xFFD92D20),
                              iconBgColor: const Color(0xFFFEE4E2),
                              label: appState.translate('bloodGroup'),
                              value: record.bloodGroup,
                              subtext: appState.translate('emergencyReference'),
                            ),
                            // Allergies Card
                            _buildOverviewCard(
                              icon: LucideIcons.shieldAlert,
                              iconColor: const Color(0xFF079455),
                              iconBgColor: const Color(0xFFECFDF3),
                              label: appState.translate('allergies'),
                              value: record.allergies,
                              subtext: appState.translate('foodDrugEnv'),
                            ),
                            // Medical Conditions Card
                            _buildOverviewCard(
                              icon: LucideIcons.heart,
                              iconColor: const Color(0xFFE11D48),
                              iconBgColor: const Color(0xFFFFF1F3),
                              label: appState.translate('medicalConditions'),
                              value: record.chronicConditions,
                              subtext: appState.translate('longTermConditions'),
                            ),
                            // Ongoing Medications Card
                            _buildOverviewCard(
                              icon: LucideIcons.pill,
                              iconColor: const Color(0xFF6941C6),
                              iconBgColor: const Color(0xFFF4F3FF),
                              label: appState.translate('ongoingMedications'),
                              value: record.ongoingMedications,
                              subtext: appState.translate('regularPrescriptions'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. Emergency Contact Card
                        _buildEmergencyContactCard(appState, record),
                        const SizedBox(height: 14),

                        // 4. Family Doctor Card
                        _buildDoctorCard(appState, record),
                        const SizedBox(height: 14),

                        // 5. Special Medical Notes Card (if present)
                        if (record.notes.isNotEmpty && record.notes != 'NA') ...[
                          _buildNotesCard(appState, record.notes),
                          const SizedBox(height: 14),
                        ],

                        // 6. Safety Info Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFB2DDFF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.info,
                                size: 18,
                                color: Color(0xFF175CD3),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appState.translate('healthInfoNotice'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF175CD3),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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

  Widget _buildStudentHeader(Student student, String bloodGroup) {
    final bool hasBloodGroup = bloodGroup.isNotEmpty &&
        bloodGroup != 'NA' &&
        bloodGroup.toLowerCase() != 'not specified';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF006D63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${student.studentClass}  •  GR: ${student.enrollmentNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasBloodGroup ? const Color(0xFFFEE4E2) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasBloodGroup ? const Color(0xFFFDA29B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.droplet,
                  size: 13,
                  color: hasBloodGroup ? const Color(0xFFD92D20) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  hasBloodGroup ? bloodGroup : 'NA',
                  style: TextStyle(
                    color: hasBloodGroup ? const Color(0xFFB42318) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required String subtext,
  }) {
    final bool isNA = value == 'NA';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isNA ? 15 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: isNA ? const Color(0xFF94A3B8) : const Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(AppState appState, HealthRecord record) {
    final hasPhone = record.emergencyContactPhone != 'NA' && record.emergencyContactPhone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.phoneCall,
                  size: 18,
                  color: Color(0xFF175CD3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.translate('emergencyContact'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appState.translate('primaryUrgentContact'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // 3 Columns: Person, Relation, Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildDetailField(
                  label: appState.translate('contactPerson'),
                  value: record.emergencyContactName,
                ),
              ),
              Expanded(
                flex: 3,
                child: _buildDetailField(
                  label: appState.translate('relationship'),
                  value: record.emergencyContactRelation,
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      appState.translate('emergencyPhone'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    if (hasPhone)
                      InkWell(
                        onTap: () => _makePhoneCall(record.emergencyContactPhone),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              LucideIcons.phone,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                record.emergencyContactPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        record.emergencyContactPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AppState appState, HealthRecord record) {
    final hasPhone = record.doctorPhone != 'NA' && record.doctorPhone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.stethoscope,
                  size: 18,
                  color: Color(0xFF079455),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.translate('familyDoctor'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appState.translate('routineDoctorReference'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // 2 Columns: Doctor Name, Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _buildDetailField(
                  label: appState.translate('doctorClinicName'),
                  value: record.doctorName,
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      appState.translate('doctorPhone'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    if (hasPhone)
                      InkWell(
                        onTap: () => _makePhoneCall(record.doctorPhone),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              LucideIcons.phone,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                record.doctorPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        record.doctorPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(AppState appState, String notes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  size: 18,
                  color: Color(0xFFB42318),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                appState.translate('specialMedicalNotes'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475467),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

