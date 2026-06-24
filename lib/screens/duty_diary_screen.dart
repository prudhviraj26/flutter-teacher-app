import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

class DutyDiaryScreen extends StatefulWidget {
  const DutyDiaryScreen({super.key});

  @override
  State<DutyDiaryScreen> createState() => _DutyDiaryScreenState();
}

class _DutyDiaryScreenState extends State<DutyDiaryScreen> {
  String _currentMonth = 'May 2025';

  void _showNavigationToast(String month) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $month (Demo mode)'),
        duration: const Duration(seconds: 1),
      ),
    );
    setState(() {
      _currentMonth = month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // May 2025 Days generation
    final List<Map<String, dynamic>> days = [];
    for (int d = 1; d <= 31; d++) {
      final int dayOfWeek = (d + 2) % 7; // May 1st is Thursday (3 blank spots before it if Monday = 0)
      
      String status = 'present';
      String? holidayName;
      bool isToday = false;

      if (d == 1) {
        status = 'holiday';
        holidayName = 'Holiday';
      } else if (d == 7) {
        status = 'absent';
      } else if (d == 9) {
        status = 'leave';
      } else if (dayOfWeek == 5 || dayOfWeek == 6) {
        status = 'weekend';
      } else if (d == 12) {
        status = 'present';
        isToday = true;
      } else if (d > 12) {
        status = 'future';
      }

      days.add({
        'dayNum': d,
        'status': status,
        'holidayName': holidayName,
        'isToday': isToday,
      });
    }

    // empty slots representation for Monday, Tuesday, Wednesday (3 slots)
    final int emptySlots = 3;

    return Scaffold(
      body: Column(
        children: [
          // Header & Month Selector
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              children: [
                // Top Nav
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
                
                // Month Selector Strip
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _showNavigationToast('April 2025'),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                      ),
                      Text(
                        _currentMonth,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showNavigationToast('June 2025'),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
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
          
          // Stats Row & Scrollable Calendar
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                children: [
                  // 4 Stats Chips
                  Row(
                    children: [
                      _buildStatChip('Present', '18', const Color(0xFFE0F2F1), const Color(0xFF00796B), const Color(0xFFB2DFDB)),
                      const SizedBox(width: 10),
                      _buildStatChip('Absent', '1', const Color(0xFFFFEBEE), const Color(0xFFC62828), const Color(0xFFFFCDD2)),
                      const SizedBox(width: 10),
                      _buildStatChip('Leave', '1', const Color(0xFFFFF3E0), const Color(0xFFFFA41B), const Color(0xFFFFE0B2)),
                      const SizedBox(width: 10),
                      _buildStatChip('Holidays', '2', const Color(0xFFECEFF1), const Color(0xFF455A64), const Color(0xFFCFD8DC)),
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
                        // Legend Wrap
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
                              _buildLegendItem(const Color(0xFFC62828), 'Absent'),
                              _buildLegendItem(const Color(0xFFFFA41B), 'Leave'),
                              _buildLegendItem(const Color(0xFF455A64), 'Holiday'),
                              _buildLegendItem(const Color(0xFFB0BEC5), 'Weekend'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Calendar Weekdays
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
                        const SizedBox(height: 8),
                        
                        // Grid layout (using Table or GridView logic manually mapped to Rows)
                        _buildCalendarGrid(emptySlots, days),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Cards
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
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF00796B)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'You have been present for 18 out of 19 working days this month.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA41B), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '1 absence recorded. Contact School Admin for any discrepancies.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
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

  Widget _buildCalendarGrid(int emptySlots, List<Map<String, dynamic>> days) {
    // Flatten lists of widgets representing cells
    final List<Widget> cells = [];
    
    // Empty boxes
    for (int i = 0; i < emptySlots; i++) {
      cells.add(const SizedBox(height: 48));
    }
    
    // Active cells
    for (var day in days) {
      cells.add(_buildCalendarCell(day));
    }
    
    // Split cells into rows of 7
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

  Widget _buildCalendarCell(Map<String, dynamic> day) {
    final int dayNum = day['dayNum'] as int;
    final String status = day['status'] as String;
    final String? holidayName = day['holidayName'] as String?;
    final bool isToday = day['isToday'] as bool;

    Color bg = Colors.transparent;
    Color textColor = Colors.grey.shade300;
    Color borderColor = Colors.transparent;

    if (isToday) {
      borderColor = AppColors.secondary;
    }

    switch (status) {
      case 'present':
        bg = const Color(0xFFE0F2F1);
        textColor = const Color(0xFF00796B);
        borderColor = isToday ? AppColors.secondary : const Color(0xFFB2DFDB).withOpacity(0.8);
        break;
      case 'absent':
        bg = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        borderColor = isToday ? AppColors.secondary : const Color(0xFFFFCDD2).withOpacity(0.8);
        break;
      case 'leave':
        bg = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFFA41B);
        borderColor = isToday ? AppColors.secondary : const Color(0xFFFFE0B2).withOpacity(0.8);
        break;
      case 'holiday':
        bg = const Color(0xFFECEFF1);
        textColor = const Color(0xFF455A64);
        borderColor = isToday ? AppColors.secondary : const Color(0xFFCFD8DC).withOpacity(0.8);
        break;
      case 'weekend':
        bg = const Color(0xFFF8F9FA);
        textColor = const Color(0xFFB0BEC5);
        borderColor = Colors.transparent;
        break;
      case 'future':
      default:
        bg = Colors.transparent;
        textColor = Colors.grey.shade400;
        borderColor = const Color(0xFFF3F4F6);
        break;
    }

    return GestureDetector(
      onTap: () {
        if (status != 'future' && status != 'weekend') {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Day $dayNum: ${status.toUpperCase()} ${holidayName != null ? "($holidayName)" : ""}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: borderColor, width: 2)
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
            if (holidayName != null)
              Text(
                holidayName,
                style: const TextStyle(
                  fontSize: 7,
                  color: Color(0xFF455A64),
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
