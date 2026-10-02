import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class DutyDiaryScreen extends StatefulWidget {
  const DutyDiaryScreen({super.key});

  @override
  State<DutyDiaryScreen> createState() => _DutyDiaryScreenState();
}

class _DutyDiaryScreenState extends State<DutyDiaryScreen> {
  late DateTime _selectedDate;

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForSelectedMonth();
    });
  }

  String get _monthKey =>
      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";

  String get _monthLabel =>
      "${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}";

  void _loadDataForSelectedMonth() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchMonthlyAttendance(_monthKey);
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _loadDataForSelectedMonth();
  }

  void _goToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _loadDataForSelectedMonth();
  }

  void _showDayDetailsModal(BuildContext context, TeacherDayAttendance day, String formattedDate) {
    String statusTitle = 'Not Marked';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isFuture = day.date.compareTo(todayStr) > 0;

    if (day.isHoliday) {
      statusTitle = day.holidayName ?? 'School Holiday';
      statusColor = const Color(0xFF026AA2);
      statusIcon = Icons.beach_access_rounded;
    } else if (!day.isWorkingDay) {
      statusTitle = 'Weekly Off / Non-Working Day';
      statusColor = const Color(0xFF667085);
      statusIcon = Icons.weekend_rounded;
    } else if (day.status == 'present') {
      statusTitle = 'Present';
      statusColor = const Color(0xFF00796B);
      statusIcon = Icons.check_circle_rounded;
    } else if (day.status == 'half_day') {
      statusTitle = 'Half Day';
      statusColor = const Color(0xFFEA580C);
      statusIcon = Icons.schedule_rounded;
    } else if (day.status == 'leave') {
      statusTitle = 'Leave';
      statusColor = const Color(0xFFFFA41B);
      statusIcon = Icons.event_busy_rounded;
    } else if (day.status == 'absent') {
      statusTitle = 'Absent';
      statusColor = const Color(0xFFC62828);
      statusIcon = Icons.cancel_rounded;
    } else if (isFuture) {
      statusTitle = 'Upcoming Working Day';
      statusColor = const Color(0xFF98A2B3);
      statusIcon = Icons.calendar_today_rounded;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 16),
              if (day.markedBy != null && day.markedBy!.isNotEmpty) ...[
                _buildModalInfoRow('Marked By', day.markedBy!),
                const SizedBox(height: 10),
              ],
              if (day.markedAt != null && day.markedAt!.isNotEmpty) ...[
                _buildModalInfoRow('Marked At', day.markedAt!),
                const SizedBox(height: 10),
              ],
              if (day.reason != null && day.reason!.isNotEmpty) ...[
                _buildModalInfoRow('Reason', day.reason!),
                const SizedBox(height: 10),
              ],
              if (day.notes != null && day.notes!.isNotEmpty) ...[
                _buildModalInfoRow('Notes', day.notes!),
                const SizedBox(height: 10),
              ],
              if (day.status == 'absent' || day.status == 'leave') ...[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If you believe this record is inaccurate, please contact the School Admin for correction.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final monthlyReport = appState.monthlyAttendance;
    final summary = monthlyReport?.summary;

    final int presentCount = summary?.daysPresent ?? 0;
    final int halfDayCount = summary?.daysHalfDay ?? 0;
    final int leaveCount = (summary?.daysLeave ?? 0) + (summary?.daysAbsent ?? 0);
    final int holidayCount = monthlyReport?.days.where((d) => d.isHoliday).length ?? 0;

    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final int startOffset = (firstDayOfMonth.weekday - 1) % 7; // Monday = 0

    return Scaffold(
      body: Column(
        children: [
          // Header & Month Selector
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              children: [
                // Top Navigation Bar
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
                      appState.translate('dutyDiary'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Month Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _goToPreviousMonth,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _monthLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _goToNextMonth,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: appState.isLoadingMonthlyAttendance
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: Column(
                      children: [
                        // 4 Stats Chips: PRESENT (Green), LEAVE (Rose), HALF DAY (Orange), HOLIDAYS (Grey)
                        Row(
                          children: [
                            _buildStatChip('Present', '$presentCount', const Color(0xFFE0F2F1), const Color(0xFF00796B), const Color(0xFFB2DFDB)),
                            const SizedBox(width: 8),
                            _buildStatChip('Leave', '$leaveCount', const Color(0xFFFFEBEE), const Color(0xFFE11D48), const Color(0xFFFFCDD2)),
                            const SizedBox(width: 8),
                            _buildStatChip('Half Day', '$halfDayCount', const Color(0xFFFFF3E0), const Color(0xFFEA580C), const Color(0xFFFFE0B2)),
                            const SizedBox(width: 8),
                            _buildStatChip('Holidays', '$holidayCount', const Color(0xFFECEFF1), const Color(0xFF455A64), const Color(0xFFCFD8DC)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Calendar Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E7EB).withOpacity(0.5)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Legend Strip
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    _buildLegendItem(const Color(0xFF00897B), 'Present'),
                                    _buildLegendItem(const Color(0xFFE11D48), 'Leave'),
                                    _buildLegendItem(const Color(0xFFEA580C), 'Half Day'),
                                    _buildLegendItem(const Color(0xFF455A64), 'Holiday'),
                                    _buildLegendItem(const Color(0xFFB0BEC5), 'Weekend'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Weekday Headers
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                                  return Expanded(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),

                              // Dynamic Calendar Grid
                              _buildDynamicCalendarGrid(
                                context,
                                startOffset,
                                monthlyReport?.days ?? [],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Summary & Progress Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F2F1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF00796B), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Present for $presentCount out of ${monthlyReport?.instructionalDays ?? 0} working days',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      summary?.attendancePercent != null
                                          ? 'Monthly attendance: ${summary!.attendancePercent}%'
                                          : 'Instructional days recorded this month',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contextual Alert or Perfect Attendance Card
                        if (leaveCount > 0 || halfDayCount > 0) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              border: Border.all(color: const Color(0xFFFFE0B2)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$leaveCount leave(s)${halfDayCount > 0 ? " and $halfDayCount half-day(s)" : ""} recorded. Contact School Admin for any discrepancies.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Full attendance maintained this month with zero leaves recorded.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color bg, Color text, Color border) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(color: text, fontSize: 8, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDynamicCalendarGrid(
    BuildContext context,
    int emptySlots,
    List<TeacherDayAttendance> days,
  ) {
    final List<Widget> cells = [];

    // Empty offset slots before 1st of month
    for (int i = 0; i < emptySlots; i++) {
      cells.add(const SizedBox(height: 48));
    }

    // Day cells
    for (var day in days) {
      cells.add(_buildDynamicCalendarCell(context, day));
    }

    // Split into rows of 7
    final List<Widget> rows = [];
    for (int i = 0; i < cells.length; i += 7) {
      final List<Widget> rowCells = [];
      for (int j = i; j < i + 7; j++) {
        if (j < cells.length) {
          rowCells.add(Expanded(child: cells[j]));
        } else {
          rowCells.add(const Expanded(child: SizedBox(height: 48)));
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowCells,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDynamicCalendarCell(BuildContext context, TeacherDayAttendance day) {
    final int dayNum = int.tryParse(day.date.split('-').last) ?? 1;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final bool isToday = (day.date == todayStr);
    final bool isFuture = day.date.compareTo(todayStr) > 0;

    Color bg = Colors.transparent;
    Color textColor = Colors.grey.shade400;
    Color borderColor = Colors.transparent;

    if (day.isHoliday) {
      bg = const Color(0xFFF0F9FF);
      textColor = const Color(0xFF026AA2);
      borderColor = const Color(0xFFB9E6FE);
    } else if (!day.isWorkingDay) {
      bg = const Color(0xFFF8FAFC);
      textColor = const Color(0xFF98A2B3);
      borderColor = Colors.transparent;
    } else if (day.status == 'present') {
      bg = const Color(0xFFE0F2F1);
      textColor = const Color(0xFF00796B);
      borderColor = const Color(0xFFB2DFDB);
    } else if (day.status == 'half_day') {
      bg = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFEA580C);
      borderColor = const Color(0xFFFFE0B2);
    } else if (day.status == 'leave' || day.status == 'absent') {
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFE11D48);
      borderColor = const Color(0xFFFFCDD2);
    } else if (isFuture) {
      bg = Colors.transparent;
      textColor = Colors.grey.shade400;
      borderColor = const Color(0xFFF3F4F6);
    } else {
      // Past day, not marked
      bg = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF6B7280);
      borderColor = const Color(0xFFE5E7EB);
    }

    return GestureDetector(
      onTap: () {
        _showDayDetailsModal(context, day, "${_monthNames[_selectedDate.month - 1]} $dayNum, ${_selectedDate.year}");
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: AppColors.secondary, width: 2)
              : borderColor != Colors.transparent
                  ? Border.all(color: borderColor, width: 1)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (day.isHoliday && day.holidayName != null)
              Text(
                day.holidayName!,
                style: const TextStyle(
                  fontSize: 7,
                  color: Color(0xFF026AA2),
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else if (day.status == 'present')
              const Text(
                'P',
                style: TextStyle(fontSize: 7, color: Color(0xFF00796B), fontWeight: FontWeight.w900),
              )
            else if (day.status == 'half_day')
              const Text(
                'H',
                style: TextStyle(fontSize: 7, color: Color(0xFFEA580C), fontWeight: FontWeight.w900),
              )
            else if (day.status == 'leave' || day.status == 'absent')
              const Text(
                'L',
                style: TextStyle(fontSize: 7, color: Color(0xFFE11D48), fontWeight: FontWeight.w900),
              ),
          ],
        ),
      ),
    );
  }
}
