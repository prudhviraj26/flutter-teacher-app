import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

// 1. ROLL CALL SCREEN
class AttendanceRollCallScreen extends StatelessWidget {
  const AttendanceRollCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final students = appState.students;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
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
                  appState.translate('rollCall'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final status = appState.tempAttendance[student.id] ?? 'P';
                final isPresent = status == 'P';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll No: ${student.rollNo}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        
                        // Present/Absent buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => appState.updateTempAttendance(student.id, 'P'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPresent ? AppColors.primary : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  appState.translate('present'),
                                  style: TextStyle(
                                    color: isPresent ? Colors.white : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => appState.updateTempAttendance(student.id, 'A'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isPresent ? const Color(0xFFEF4444) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  appState.translate('absent'),
                                  style: TextStyle(
                                    color: !isPresent ? Colors.white : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Submit Button bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/attendance/confirm'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  appState.translate('submit'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. CONFIRMATION SCREEN
class AttendanceConfirmationScreen extends StatelessWidget {
  const AttendanceConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final total = appState.students.length;
    final absentIds = appState.tempAttendance.entries
        .where((e) => e.value == 'A')
        .map((e) => e.key)
        .toList();
    final absentCount = absentIds.length;
    final presentCount = total - absentCount;

    final absentStudents = appState.students
        .where((s) => absentIds.contains(s.id))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
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
                  appState.translate('confirmAttendance'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Stats Card
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
                    children: [
                      Text(
                        appState.translate('attendanceSummary'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Total', '$total', Colors.blue),
                          _buildStatColumn('Present', '$presentCount', AppColors.primary),
                          _buildStatColumn('Absent', '$absentCount', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Absent list header
                Text(
                  '${appState.translate('absent')} ($absentCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                if (absentStudents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No students absent today.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: absentStudents.length,
                    itemBuilder: (context, index) {
                      final s = absentStudents[index];
                      return Card(
                        color: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            radius: 14,
                            child: Icon(Icons.close, size: 14),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          subtitle: Text(
                            'Roll No: ${s.rollNo}',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Submit Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  appState.submitAttendance(appState.teacher?.id ?? 'T001');
                  Navigator.pushReplacementNamed(context, '/attendance/submitted');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  appState.translate('confirm'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}

// 3. SUBMITTED SUCCESS SCREEN
class AttendanceSubmittedScreen extends StatelessWidget {
  const AttendanceSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final history = appState.attendanceHistory;
    final String currentClass = appState.teacher?.assignedClass ?? 'Grade 3-B';

    int total = appState.students.length;
    int absentCount = 0;
    if (history.isNotEmpty) {
      absentCount = history.first.records.where((r) => r.status == 'A').length;
    }
    int presentCount = total - absentCount;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark Circle
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                appState.translate('attendanceSubmitted'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              
              Text(
                '${appState.translate('attendanceSubmittedSuccess')} $currentClass.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Brief Summary Panel
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text('Present', style: TextStyle(color: Colors.grey, fontSize: 11)), const SizedBox(height: 2), Text('$presentCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    Column(children: [const Text('Absent', style: TextStyle(color: Colors.grey, fontSize: 11)), const SizedBox(height: 2), Text('$absentCount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Button 1: Go back to dashboard
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    appState.translate('goBackToDashboard'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Button 2: Correct Attendance
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Populate temp state with first history element
                    if (history.isNotEmpty) {
                      for (var r in history.first.records) {
                        appState.updateTempAttendance(r.studentId, r.status);
                      }
                    }
                    Navigator.pushReplacementNamed(context, '/attendance/correction');
                  },
                  child: Text(
                    appState.translate('correctAttendance'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. CORRECTION ROLL CALL SCREEN
class AttendanceCorrectionScreen extends StatelessWidget {
  const AttendanceCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final students = appState.students;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
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
                  appState.translate('correctAttendance'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final status = appState.tempAttendance[student.id] ?? 'P';
                final isPresent = status == 'P';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll No: ${student.rollNo}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        
                        // Present/Absent buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => appState.updateTempAttendance(student.id, 'P'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPresent ? AppColors.primary : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  appState.translate('present'),
                                  style: TextStyle(
                                    color: isPresent ? Colors.white : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => appState.updateTempAttendance(student.id, 'A'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isPresent ? const Color(0xFFEF4444) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  appState.translate('absent'),
                                  style: TextStyle(
                                    color: !isPresent ? Colors.white : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Save Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  appState.submitAttendance(appState.teacher?.id ?? 'T001');
                  // Trigger correction completed toast
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appState.translate('attendanceCorrected')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  appState.translate('save'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
