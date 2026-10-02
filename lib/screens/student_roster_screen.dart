import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import 'attendance_screens.dart';

class StudentRosterScreen extends StatefulWidget {
  const StudentRosterScreen({super.key});

  @override
  State<StudentRosterScreen> createState() => _StudentRosterScreenState();
}

class _StudentRosterScreenState extends State<StudentRosterScreen> {
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all' | 'absent' | 'fees' | 'attendance'
  String _selectedClass = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.loadLiveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final allStudents = appState.students;

    // Determine available classes from teacher assignments & student records
    final List<String> availableClasses = [];
    if (teacher != null) {
      if (teacher.assignedClasses != null && teacher.assignedClasses!.isNotEmpty) {
        for (var c in teacher.assignedClasses!) {
          if (!availableClasses.contains(c)) availableClasses.add(c);
        }
      }
      if (teacher.assignedClass != null && teacher.assignedClass!.isNotEmpty && !availableClasses.contains(teacher.assignedClass)) {
        availableClasses.add(teacher.assignedClass!);
      }
    }
    for (var s in allStudents) {
      if (s.studentClass.isNotEmpty && !availableClasses.contains(s.studentClass)) {
        availableClasses.add(s.studentClass);
      }
    }
    if (availableClasses.isEmpty) {
      availableClasses.add('Grade 10 A');
    }

    // Default selected class if not set or invalid
    if (_selectedClass.isEmpty || (!availableClasses.contains(_selectedClass) && _selectedClass != 'All Classes')) {
      _selectedClass = availableClasses.first;
    }

    String normalizeClassName(String raw) {
      return raw.toLowerCase()
          .replaceAll('grade', '')
          .replaceAll('class', '')
          .replaceAll('-', '')
          .replaceAll(' ', '')
          .trim();
    }

    // Filter students by selected class
    List<Student> classStudents = allStudents.where((s) {
      if (_selectedClass == 'All Classes' || availableClasses.length <= 1) {
        return true;
      }
      final sNorm = normalizeClassName(s.studentClass);
      final targetNorm = normalizeClassName(_selectedClass);
      return sNorm.isEmpty || sNorm == targetNorm || s.studentClass == _selectedClass;
    }).toList();

    if (classStudents.isEmpty && allStudents.isNotEmpty) {
      classStudents = allStudents;
    }

    // Sync live today's attendance status from active marking session
    for (var s in classStudents) {
      if (appState.tempAttendance.containsKey(s.id)) {
        s.absentToday = (appState.tempAttendance[s.id] == 'A');
      }
    }

    // Dynamic Filter counts
    final int allCount = classStudents.length;
    final int absentCount = appState.isAttendanceSubmittedToday
        ? classStudents.where((s) => s.absentToday).length
        : 0;
    final int feesCount = 0;
    final int attendanceCount = classStudents.where((s) => s.attendancePercentage < 75).length;

    // Filtered list matching active tab & search query
    final filteredStudents = classStudents.where((student) {
      final matchesSearch = student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.rollNo.contains(_searchQuery) ||
          student.enrollmentNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.parentName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_activeFilter == 'absent') {
        if (!appState.isAttendanceSubmittedToday) return false;
        return student.absentToday;
      }
      if (_activeFilter == 'fees') {
        return false;
      }
      if (_activeFilter == 'attendance') {
        return student.attendancePercentage < 75;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header & Class Switcher
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Nav Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.translate('students'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$allCount ${appState.translate("totalStudents")}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Class Dropdown Selector
                    if (availableClasses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableClasses.contains(_selectedClass) ? _selectedClass : availableClasses.first,
                            dropdownColor: AppColors.secondary,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            items: availableClasses.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedClass = val);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: appState.translate('search'),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Squeezed 4 Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', allCount, AppColors.secondary),
                const SizedBox(width: 6),
                _buildFilterChip('Absent', 'absent', absentCount, const Color(0xFFE11D48)),
                const SizedBox(width: 6),
                _buildFilterChip('Fee Due', 'fees', feesCount, const Color(0xFFEA580C)),
                const SizedBox(width: 6),
                _buildFilterChip('Attn < 75%', 'attendance', attendanceCount, const Color(0xFFC62828)),
              ],
            ),
          ),

          // Student List / Directory / Tab States
          Expanded(
            child: appState.isLoadingStudents
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => appState.loadLiveData(),
                    color: AppColors.secondary,
                    child: _activeFilter == 'fees'
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFFEDD5)),
                                        ),
                                        child: const Icon(Icons.account_balance_wallet_outlined, size: 32, color: Color(0xFFEA580C)),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Fee Management In Development',
                                        style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fee dues, concession structures, and receipt tracking are currently being set up on the web admin portal and will be available soon.',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _activeFilter == 'absent' && !appState.isAttendanceSubmittedToday
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                                  Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                            ),
                                            child: const Icon(Icons.pending_actions_outlined, size: 32, color: Color(0xFFD97706)),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "Today's attendance is pending to be marked.",
                                            style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Attendance for $_selectedClass has not been marked today. Mark attendance to view today's absent list.",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const AttendanceRollCallScreen()),
                                              ).then((_) {
                                                if (mounted) appState.loadLiveData();
                                              });
                                            },
                                            icon: const Icon(Icons.how_to_reg, color: Colors.white, size: 18),
                                            label: const Text('Mark Attendance Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.secondary,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : filteredStudents.isNotEmpty
                                ? ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    itemCount: filteredStudents.length,
                                    itemBuilder: (context, index) {
                                      final s = filteredStudents[index];
                                      final isLowAttn = s.attendancePercentage < 75;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: const [
                                              BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
                                            ],
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => StudentProfileScreen(studentId: s.id),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  // Roll / Initials Avatar
                                                  Container(
                                                    width: 46,
                                                    height: 46,
                                                    decoration: BoxDecoration(
                                                      color: s.absentToday
                                                          ? const Color(0xFFFFEBEE)
                                                          : AppColors.secondary.withOpacity(0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      (s.rollNo.isNotEmpty && s.rollNo != '1')
                                                          ? s.rollNo
                                                          : (s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S'),
                                                      style: TextStyle(
                                                        color: s.absentToday ? const Color(0xFFC62828) : AppColors.secondary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),

                                                  // Student Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                s.name,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                  color: Color(0xFF1F2937),
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            // Attendance percentage chip
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: isLowAttn ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                '${s.attendancePercentage.toInt()}%',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: isLowAttn ? const Color(0xFFC62828) : const Color(0xFF00796B),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${s.studentClass} • GR: ${s.enrollmentNo}',
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                                        ),
                                                        const SizedBox(height: 6),

                                                        // Status tags row
                                                        Row(
                                                          children: [
                                                            if (appState.isAttendanceSubmittedToday && s.absentToday)
                                                              _buildStatusBadge('Absent Today', const Color(0xFFFFEBEE), const Color(0xFFC62828))
                                                            else if (appState.isAttendanceSubmittedToday)
                                                              _buildStatusBadge('Present Today', const Color(0xFFE0F2F1), const Color(0xFF00796B))
                                                            else
                                                              _buildStatusBadge('Attendance Pending', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                                                            const SizedBox(width: 6),
                                                            if (s.parentName.isNotEmpty)
                                                              Expanded(
                                                                child: Text(
                                                                  'Parent: ${s.parentName}',
                                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _activeFilter == 'attendance' ? Icons.verified_outlined : Icons.person_outline,
                                                size: 32,
                                                color: _activeFilter == 'attendance' ? const Color(0xFF16A34A) : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              _activeFilter == 'absent'
                                                  ? 'All students are present today!'
                                                  : _activeFilter == 'attendance'
                                                      ? 'No attendance defaulters'
                                                      : 'No students found for this class',
                                              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _activeFilter == 'absent'
                                                  ? '100% attendance recorded for $_selectedClass today.'
                                                  : _activeFilter == 'attendance'
                                                      ? 'All students in this class have maintained 75%+ attendance.'
                                                      : 'Try switching classes or adjusting search keywords.',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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

  Widget _buildFilterChip(String label, String value, int count, Color activeColor) {
    final bool isSelected = _activeFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? activeColor : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white24 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bg, Color textC) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: textC, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class StudentProfileScreen extends StatelessWidget {
  final String studentId;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final s = appState.students.firstWhere(
      (student) => student.id == studentId,
      orElse: () => Student(id: '', name: 'Unknown', rollNo: '', enrollmentNo: '', studentClass: '', dateOfBirth: '', gender: '', parentName: '', parentMobile: '', address: '', bloodGroup: '', emergencyContact: ''),
    );

    if (s.id.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(appState.translate('studentNotFound')),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header & Student Banner
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              children: [
                Row(
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
                    Text(
                      appState.translate('studentProfile'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Student Profile Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        child: Text(
                          s.name.isNotEmpty ? s.name[0] : '?',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (s.rollNo.isNotEmpty && s.rollNo != '1')
                                  ? 'Roll No: ${s.rollNo} • ${s.studentClass}'
                                  : s.studentClass,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.absentToday ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.absentToday ? 'ABSENT TODAY' : 'PRESENT TODAY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: s.absentToday ? const Color(0xFFC62828) : const Color(0xFF00796B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.attendancePercentage < 75 ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${s.attendancePercentage.toInt()}% Overall',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: s.attendancePercentage < 75 ? const Color(0xFFC62828) : const Color(0xFF00796B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Academic Info Card
                _buildSectionCard(
                  icon: Icons.school_outlined,
                  title: 'Academic Details',
                  items: [
                    {'label': 'Class & Section', 'value': s.studentClass},
                    {'label': appState.translate('enrollmentNo'), 'value': s.enrollmentNo},
                    {'label': 'Roll Number', 'value': s.rollNo.isNotEmpty ? s.rollNo : 'N/A'},
                    {'label': 'Attendance Rate', 'value': '${s.attendancePercentage.toInt()}%'},
                  ],
                ),
                const SizedBox(height: 16),

                // Personal Info Card
                _buildSectionCard(
                  icon: Icons.person_outline,
                  title: appState.translate('studentDetails'),
                  items: [
                    {'label': appState.translate('dateOfBirth'), 'value': s.dateOfBirth},
                    {'label': appState.translate('gender'), 'value': s.gender},
                    {'label': appState.translate('bloodGroup'), 'value': s.bloodGroup},
                  ],
                ),
                const SizedBox(height: 16),

                // Parent / Guardian Card with Call & Message actions
                _buildParentSectionCard(context, s),
                const SizedBox(height: 16),

                // Address Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            appState.translate('address'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.address.isNotEmpty ? s.address : 'School Address on Record',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSectionCard(BuildContext context, Student s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.family_restroom_outlined, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Parent & Guardian',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
              if (s.parentMobile.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.secondary, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling parent: ${s.parentMobile}'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Parent Name', s.parentName),
          const SizedBox(height: 8),
          _buildInfoRow('Primary Mobile', s.parentMobile),
          if (s.emergencyContact.isNotEmpty && s.emergencyContact != s.parentMobile) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Emergency Contact', s.emergencyContact),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['label']}:',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      item['value'] != null && item['value'].toString().isNotEmpty ? item['value'].toString() : 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
