import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class StudentRosterScreen extends StatefulWidget {
  const StudentRosterScreen({super.key});

  @override
  State<StudentRosterScreen> createState() => _StudentRosterScreenState();
}

class _StudentRosterScreenState extends State<StudentRosterScreen> {
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all' | 'absent' | 'fees' | 'attendance'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    final isSubjectTeacher = teacher?.designation == 'Subject Teacher';
    final studentsList = appState.students;

    if (isSubjectTeacher) {
      return Scaffold(
        body: Column(
          children: [
            // Header
            Container(
              color: AppColors.secondary,
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
                  Text(
                    appState.translate('students'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Warning layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Student records are managed by the Class Teacher',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Student records are accessible to the Class Teacher. Please contact your Class Teacher or School Admin for student information.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    appState.translate('goBackToDashboard'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Class Teacher Filter calculations
    final int allCount = studentsList.length;
    final int absentCount = studentsList.where((s) => s.absentToday).length;
    final int feesCount = studentsList.where((s) => s.feeDefaulter).length;
    final int attendanceCount = studentsList.where((s) => s.attendancePercentage < 75).length;

    final filteredStudents = studentsList.where((student) {
      final matchesSearch = student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.rollNo.contains(_searchQuery) ||
          student.enrollmentNo.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_activeFilter == 'absent') {
        return student.absentToday;
      }
      if (_activeFilter == 'fees') {
        return student.feeDefaulter;
      }
      if (_activeFilter == 'attendance') {
        return student.attendancePercentage < 75;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header & Search
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search
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
          
          // Squeezed filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', allCount),
                const SizedBox(width: 6),
                _buildFilterChip('Absent', 'absent', absentCount),
                const SizedBox(width: 6),
                _buildFilterChip('Fee Due', 'fees', feesCount),
                const SizedBox(width: 6),
                _buildFilterChip('Attn < 75%', 'attendance', attendanceCount),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: filteredStudents.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                                  // Roll avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s.rollNo,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${s.enrollmentNo} • ${s.gender}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                        
                                        // Specific Status badges
                                        if (s.absentToday || s.feeDefaulter || s.attendancePercentage < 75) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              if (s.absentToday)
                                                _buildStatusBadge('Absent Today', Colors.red.shade50, Colors.red.shade600),
                                              if (s.feeDefaulter)
                                                _buildStatusBadge('Fee Due', AppColors.secondary.withOpacity(0.1), AppColors.secondary),
                                              if (s.attendancePercentage < 75)
                                                _buildStatusBadge('Attn: ${s.attendancePercentage.toInt()}%', Colors.red.shade50, Colors.red.shade600),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.person, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          appState.translate('studentNotFound'),
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final bool isSelected = _activeFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.secondary : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 8,
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
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontSize: 8,
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
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          // Header & Student Card
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
                const SizedBox(height: 24),
                
                // Student Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        child: Text(
                          s.name.isNotEmpty ? s.name[0] : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll No: ${s.rollNo} • ${s.studentClass}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
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
          
          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Info block
                _buildSectionCard(
                  icon: Icons.person_outline,
                  title: appState.translate('studentDetails'),
                  items: [
                    {'label': appState.translate('enrollmentNo'), 'value': s.enrollmentNo},
                    {'label': appState.translate('dateOfBirth'), 'value': s.dateOfBirth},
                    {'label': appState.translate('gender'), 'value': s.gender},
                    {'label': appState.translate('bloodGroup'), 'value': s.bloodGroup},
                  ],
                ),
                const SizedBox(height: 16),
                
                // Parent block
                _buildSectionCard(
                  icon: Icons.phone_outlined,
                  title: appState.translate('parentName'),
                  items: [
                    {'label': appState.translate('name'), 'value': s.parentName},
                    {'label': appState.translate('mobile'), 'value': s.parentMobile, 'isPhone': true},
                    {'label': appState.translate('emergencyContact'), 'value': s.emergencyContact, 'isPhone': true},
                  ],
                ),
                const SizedBox(height: 16),
                
                // Address block
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
                        s.address,
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
              final bool isPhone = item['isPhone'] as bool? ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['label']}:',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    isPhone
                        ? Text(
                            item['value']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                              fontSize: 13,
                            ),
                          )
                        : Text(
                            item['value']!,
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
