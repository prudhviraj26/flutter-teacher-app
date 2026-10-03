import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

void showAbsentReasonModal({
  required BuildContext context,
  required Student student,
  required AppState appState,
  VoidCallback? onSaved,
}) {
  final initialReason = appState.tempAttendanceReasons[student.id] ?? '';
  final TextEditingController textController = TextEditingController(text: initialReason);
  String selectedPreset = initialReason;

  final List<String> presetReasons = [
    'Sick / Medical',
    'Family Function',
    'Out of Town / Vacation',
    'Transport Issue',
    'Uninformed Absence',
    'Personal / Other',
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_late_outlined, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason for Absence',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          Text(
                            '${student.name} • ${student.rollNo.isNotEmpty && student.rollNo != "1" ? "Roll ${student.rollNo}" : student.studentClass}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Select a reason (Required):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 10),

              // Preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetReasons.map((preset) {
                  final isSelected = selectedPreset == preset || textController.text.trim() == preset;
                  return ChoiceChip(
                    label: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFF3F4F6),
                    onSelected: (val) {
                      setModalState(() {
                        selectedPreset = preset;
                        textController.text = preset;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Custom text input
              TextField(
                controller: textController,
                onChanged: (val) {
                  setModalState(() {
                    selectedPreset = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Or enter custom reason...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: textController.text.trim().isEmpty
                      ? null
                      : () {
                          final chosenReason = textController.text.trim();
                          appState.updateTempAttendance(student.id, 'A');
                          appState.updateTempAttendanceReason(student.id, chosenReason);
                          Navigator.pop(context);
                          if (onSaved != null) onSaved();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Reason & Mark Absent',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// 1. ROLL CALL SCREEN
class AttendanceRollCallScreen extends StatefulWidget {
  const AttendanceRollCallScreen({super.key});

  @override
  State<AttendanceRollCallScreen> createState() => _AttendanceRollCallScreenState();
}

class _AttendanceRollCallScreenState extends State<AttendanceRollCallScreen> {
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
    final students = appState.students;
    final teacher = appState.teacher;

    // Class & Section details
    final String currentClass = teacher?.assignedClass ??
        (students.isNotEmpty ? students.first.studentClass : 'Grade 10 A');

    // Formatted Today's Date
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final formattedDate = "${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} ${now.year}";

    // Holiday detection
    final todayHoliday = appState.getTodayHoliday();
    final bool isSunday = appState.isTodaySunday;
    final bool isHolidayToday = todayHoliday != null || isSunday;
    final String holidayTitle = todayHoliday?.title ?? (isSunday ? 'Sunday (Weekend)' : 'School Holiday');

    return Scaffold(
      body: Column(
        children: [
          // Header & Info Panel
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                              appState.translate('rollCall'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              appState.currentSchoolName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Class & Section Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        currentClass,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date & Attendance Policy Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isHolidayToday
                              ? const Color(0xFFFDE68A)
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isHolidayToday ? 'School Holiday' : 'Today Only',
                          style: TextStyle(
                            color: isHolidayToday ? const Color(0xFF92400E) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // HOLIDAY STATE
          if (isHolidayToday)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Holiday Umbrella Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.beach_access_rounded,
                            color: Color(0xFF0284C7),
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Attendance Expected Today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Today is $holidayTitle.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Color(0xFF16A34A)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Attendance is not required on non-instructional days and holidays.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // REGULAR WORKING DAY STATE
            if (appState.isAttendanceSubmittedToday)
              Container(
                color: const Color(0xFFECFDF5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attendance already submitted for today. You can edit and re-submit changes below.',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Notice that date is locked to today
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: const Color(0xFFF9FAFB),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Attendance locked to today ($formattedDate) • $currentClass',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => appState.loadLiveData(),
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            Expanded(
                              child: Column(
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
                                  if (student.rollNo.isNotEmpty && student.rollNo != '1') ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Roll No: ${student.rollNo}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                  if (!isPresent) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => showAbsentReasonModal(
                                        context: context,
                                        student: student,
                                        appState: appState,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (appState.tempAttendanceReasons[student.id] ?? '').isNotEmpty
                                              ? const Color(0xFFFEE2E2)
                                              : const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (appState.tempAttendanceReasons[student.id] ?? '').isNotEmpty
                                                ? const Color(0xFFFECACA)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              (appState.tempAttendanceReasons[student.id] ?? '').isNotEmpty
                                                  ? Icons.edit_note
                                                  : Icons.error_outline,
                                              size: 13,
                                              color: const Color(0xFFDC2626),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                (appState.tempAttendanceReasons[student.id] ?? '').isNotEmpty
                                                    ? 'Reason: ${appState.tempAttendanceReasons[student.id]}'
                                                    : 'Reason required • Tap to select',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFDC2626),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
                                  onTap: () {
                                    appState.updateTempAttendance(student.id, 'A');
                                    showAbsentReasonModal(
                                      context: context,
                                      student: student,
                                      appState: appState,
                                    );
                                  },
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
                  onPressed: () {
                    final absentWithoutReason = appState.students.where((s) {
                      final isAbsent = (appState.tempAttendance[s.id] ?? 'P') == 'A';
                      final reason = (appState.tempAttendanceReasons[s.id] ?? '').trim();
                      return isAbsent && reason.isEmpty;
                    }).toList();

                    if (absentWithoutReason.isNotEmpty) {
                      final first = absentWithoutReason.first;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please provide an absent reason for ${first.name}${absentWithoutReason.length > 1 ? " and ${absentWithoutReason.length - 1} more" : ""}.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      showAbsentReasonModal(
                        context: context,
                        student: first,
                        appState: appState,
                      );
                      return;
                    }

                    Navigator.pushNamed(context, '/attendance/confirm');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    appState.isAttendanceSubmittedToday ? 'Review & Submit Changes' : appState.translate('submit'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
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

    final teacher = appState.teacher;
    final String currentClass = teacher?.assignedClass ??
        (appState.students.isNotEmpty ? appState.students.first.studentClass : 'Grade 10 A');

    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final formattedDate = "${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} ${now.year}";

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        currentClass,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appState.translate('attendanceSummary'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentClass,
                              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
                      final reason = (appState.tempAttendanceReasons[s.id] ?? '').trim();

                      return Card(
                        color: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: reason.isNotEmpty ? Colors.red.shade100 : Colors.red.shade300,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            radius: 16,
                            child: Icon(Icons.close, size: 16),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.rollNo.isNotEmpty && s.rollNo != '1') ...[
                                Text(
                                  'Roll No: ${s.rollNo}',
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                              ],
                              GestureDetector(
                                onTap: () => showAbsentReasonModal(
                                  context: context,
                                  student: s,
                                  appState: appState,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: reason.isNotEmpty ? Colors.white : const Color(0xFFFFCDD2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: reason.isNotEmpty ? Colors.red.shade200 : Colors.red,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        reason.isNotEmpty ? Icons.edit_note : Icons.warning_amber_rounded,
                                        size: 13,
                                        color: Colors.red.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          reason.isNotEmpty ? 'Reason: $reason' : 'Reason required • Tap to add',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.red, size: 18),
                            onPressed: () => showAbsentReasonModal(
                              context: context,
                              student: s,
                              appState: appState,
                            ),
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
                onPressed: appState.isSubmittingAttendance
                    ? null
                    : () async {
                        final absentWithoutReason = absentStudents.where((s) {
                          final reason = (appState.tempAttendanceReasons[s.id] ?? '').trim();
                          return reason.isEmpty;
                        }).toList();

                        if (absentWithoutReason.isNotEmpty) {
                          final first = absentWithoutReason.first;
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please provide an absent reason for ${first.name}.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          showAbsentReasonModal(
                            context: context,
                            student: first,
                            appState: appState,
                          );
                          return;
                        }

                        final success = await appState.submitAttendance(appState.teacher?.id ?? 'T001');
                        if (context.mounted) {
                          if (success) {
                            Navigator.pushReplacementNamed(context, '/attendance/submitted');
                          } else {
                            final err = appState.lastAttendanceError ?? 'Failed to submit attendance. Please try again.';
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: appState.isSubmittingAttendance
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
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
                        if (r.status == 'A' && r.reason != null && r.reason!.isNotEmpty) {
                          appState.updateTempAttendanceReason(r.studentId, r.reason!);
                        }
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

    final teacher = appState.teacher;
    final String currentClass = teacher?.assignedClass ??
        (students.isNotEmpty ? students.first.studentClass : 'Grade 10 A');

    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final formattedDate = "${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} ${now.year}";

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        currentClass,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
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
                final reason = (appState.tempAttendanceReasons[student.id] ?? '').trim();
                
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
                        Expanded(
                          child: Column(
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
                              if (student.rollNo.isNotEmpty && student.rollNo != '1') ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Roll No: ${student.rollNo}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                              if (!isPresent) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => showAbsentReasonModal(
                                    context: context,
                                    student: student,
                                    appState: appState,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: reason.isNotEmpty ? const Color(0xFFFEE2E2) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: reason.isNotEmpty ? const Color(0xFFFECACA) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          reason.isNotEmpty ? Icons.edit_note : Icons.error_outline,
                                          size: 13,
                                          color: const Color(0xFFDC2626),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            reason.isNotEmpty ? 'Reason: $reason' : 'Reason required • Tap to select',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFDC2626),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                              onTap: () {
                                appState.updateTempAttendance(student.id, 'A');
                                showAbsentReasonModal(
                                  context: context,
                                  student: student,
                                  appState: appState,
                                );
                              },
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
                onPressed: appState.isSubmittingAttendance
                    ? null
                    : () async {
                        final absentWithoutReason = students.where((s) {
                          final isAbsent = (appState.tempAttendance[s.id] ?? 'P') == 'A';
                          final reason = (appState.tempAttendanceReasons[s.id] ?? '').trim();
                          return isAbsent && reason.isEmpty;
                        }).toList();

                        if (absentWithoutReason.isNotEmpty) {
                          final first = absentWithoutReason.first;
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please provide an absent reason for ${first.name}.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          showAbsentReasonModal(
                            context: context,
                            student: first,
                            appState: appState,
                          );
                          return;
                        }

                        final success = await appState.submitAttendance(appState.teacher?.id ?? 'T001');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(appState.translate('attendanceCorrected')),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            final err = appState.lastAttendanceError ?? 'Failed to update attendance';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: appState.isSubmittingAttendance
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
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
