import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';

// =============================================================================
// 1. HOLIDAY THEMES & HELPER
// =============================================================================

class HolidayTheme {
  final Color bg;
  final Color text;
  final Color border;

  const HolidayTheme({
    required this.bg,
    required this.text,
    required this.border,
  });
}

HolidayTheme getHolidayTheme(String name, String type) {
  final lower = name.toLowerCase();

  // 1. National Days (Emerald)
  if (lower.contains('republic') ||
      lower.contains('independence') ||
      lower.contains('gandhi')) {
    return const HolidayTheme(
      bg: Color(0xFFE8F5E9),
      text: Color(0xFF1B5E20),
      border: Color(0xFFA5D6A7),
    );
  }

  // 2. Joyous Festival of Lights & Colours (Warm Amber)
  if (lower.contains('diwali') ||
      lower.contains('deepavali') ||
      lower.contains('holi') ||
      lower.contains('dussehra') ||
      lower.contains('vijayadashami')) {
    return const HolidayTheme(
      bg: Color(0xFFFFF8E1),
      text: Color(0xFFB78103),
      border: Color(0xFFFFE082),
    );
  }

  // 3. Islamic Observances (Mint / Teal)
  if (lower.contains('eid') ||
      lower.contains('fitr') ||
      lower.contains('bakrid') ||
      lower.contains('muharram') ||
      lower.contains('milad')) {
    return const HolidayTheme(
      bg: Color(0xFFE0F2F1),
      text: Color(0xFF00695C),
      border: Color(0xFF80CBC4),
    );
  }

  // 4. Christian Observances (Soft Rose)
  if (lower.contains('christmas') ||
      lower.contains('good friday') ||
      lower.contains('easter')) {
    return const HolidayTheme(
      bg: Color(0xFFFFEBEE),
      text: Color(0xFFC2185B),
      border: Color(0xFFFFCDD2),
    );
  }

  // 5. Deities & Spiritual Gurus (Violet / Purple)
  if (lower.contains('janmashtami') ||
      lower.contains('ganesh') ||
      lower.contains('shivratri') ||
      lower.contains('mahavir') ||
      lower.contains('guru nanak') ||
      lower.contains('buddha')) {
    return const HolidayTheme(
      bg: Color(0xFFF3E5F5),
      text: Color(0xFF6A1B9A),
      border: Color(0xFFCE93D8),
    );
  }

  // 6. Social, Harvest, Sibling & Labour Festivals (Sky Blue)
  if (lower.contains('raksha') ||
      lower.contains('bhai') ||
      lower.contains('sankranti') ||
      lower.contains('pongal') ||
      lower.contains('ambedkar') ||
      lower.contains('labour') ||
      lower.contains('govardhan')) {
    return const HolidayTheme(
      bg: Color(0xFFE3F2FD),
      text: Color(0xFF1565C0),
      border: Color(0xFF90CAF9),
    );
  }

  // Fallbacks by holiday type
  final typeLower = type.toLowerCase();
  if (typeLower.contains('national')) {
    return const HolidayTheme(
      bg: Color(0xFFE8F5E9),
      text: Color(0xFF1B5E20),
      border: Color(0xFFA5D6A7),
    );
  }
  if (typeLower.contains('festival')) {
    return const HolidayTheme(
      bg: Color(0xFFFFF8E1),
      text: Color(0xFFB78103),
      border: Color(0xFFFFE082),
    );
  }
  if (typeLower.contains('bank')) {
    return const HolidayTheme(
      bg: Color(0xFFE3F2FD),
      text: Color(0xFF1565C0),
      border: Color(0xFF90CAF9),
    );
  }
  if (typeLower.contains('gazetted')) {
    return const HolidayTheme(
      bg: Color(0xFFE0F2F1),
      text: Color(0xFF00695C),
      border: Color(0xFF80CBC4),
    );
  }

  // Default Cool Slate
  return const HolidayTheme(
    bg: Color(0xFFF1F5F9),
    text: Color(0xFF475569),
    border: Color(0xFFCBD5E1),
  );
}

// =============================================================================
// 2. HOLIDAYS SCREEN (Exact parity with Parent App)
// =============================================================================

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  final Map<String, bool> _expandedMonths = {};
  bool _initialized = false;
  bool _showPastHolidays = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHolidays();
    });
  }

  void _loadHolidays() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchAcademicYearsAndHolidays(silent: false);
  }

  void _toggleAllMonths(List<String> monthKeys, bool expand) {
    setState(() {
      for (final key in monthKeys) {
        _expandedMonths[key] = expand;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final holidays = appState.holidays;
    final academicYears = appState.academicYears;
    final selectedYearId = appState.selectedAcademicYearId;
    final isLoading = appState.isHolidaysLoading;

    // Current active academic year item
    AcademicYearItem? selectedYear;
    if (academicYears.isNotEmpty) {
      selectedYear = academicYears.firstWhere(
        (y) => y.isCurrent,
        orElse: () => academicYears.first,
      );
    }

    // 1. Filter holidays strictly within the school's configured academic year start and end dates
    List<Holiday> activeHolidays = holidays;
    if (selectedYear != null) {
      final start = DateTime(
        selectedYear.startDate.year,
        selectedYear.startDate.month,
        selectedYear.startDate.day,
      );
      final end = DateTime(
        selectedYear.endDate.year,
        selectedYear.endDate.month,
        selectedYear.endDate.day,
        23,
        59,
        59,
      );
      activeHolidays = holidays.where((h) {
        return !h.fullDate.isBefore(start) && !h.fullDate.isAfter(end);
      }).toList();
    }

    // 2. Group active holidays by year-month (e.g. "2026-11", "2026-12")
    final Map<String, List<Holiday>> holidaysByMonth = {};
    for (final h in activeHolidays) {
      final key = DateFormat('yyyy-MM').format(h.fullDate);
      holidaysByMonth.putIfAbsent(key, () => []).add(h);
    }

    // 3. Sort holidays within each month chronologically
    for (final entry in holidaysByMonth.entries) {
      entry.value.sort((a, b) => a.fullDate.compareTo(b.fullDate));
    }

    // 4. Partition months based on current month:
    //    - Current month at top
    //    - Upcoming months sorted chronologically
    //    - Past months sorted chronologically
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    final currentMonthEntries = holidaysByMonth.entries
        .where((e) => e.key == currentMonthKey)
        .toList();

    final upcomingMonthEntries = holidaysByMonth.entries
        .where((e) => e.key.compareTo(currentMonthKey) > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final pastMonthEntries = holidaysByMonth.entries
        .where((e) => e.key.compareTo(currentMonthKey) < 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final activeMonthEntries = [
      ...currentMonthEntries,
      ...upcomingMonthEntries,
    ];

    final activeMonthKeys = activeMonthEntries.map((e) => e.key).toList();

    // 5. Initialize expansion states for active months (current & upcoming):
    if (!_initialized && activeMonthKeys.isNotEmpty) {
      for (final key in activeMonthKeys) {
        _expandedMonths.putIfAbsent(key, () => true);
      }
      _initialized = true;
    }

    final bool allExpanded = activeMonthKeys.isNotEmpty &&
        activeMonthKeys.every((k) => _expandedMonths[k] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appState.translate('holidays'),
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await appState.fetchAcademicYearsAndHolidays(
            yearId: selectedYearId,
            silent: false,
          );
        },
        color: AppColors.primaryTeal,
        child: Column(
          children: [
            // Top Toolbar: Academic Year selector + count badge + Expand/Collapse toggle
            _buildTopToolbar(
              context: context,
              appState: appState,
              academicYears: academicYears,
              selectedYear: selectedYear,
              selectedYearId: selectedYearId,
              holidayCount: activeHolidays.length,
              monthKeys: activeMonthKeys,
              allExpanded: allExpanded,
            ),

            // Content list
            Expanded(
              child: isLoading && holidays.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    )
                  : (activeMonthEntries.isEmpty && pastMonthEntries.isEmpty)
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: activeMonthEntries.length +
                              (pastMonthEntries.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, idx) {
                            if (idx == activeMonthEntries.length) {
                              return _buildPastHolidaysSection(pastMonthEntries);
                            }

                            final entry = activeMonthEntries[idx];
                            final monthKey = entry.key;
                            final monthHolidays = entry.value;
                            final isExpanded = _expandedMonths[monthKey] ?? true;
                            final isCurrentMonth = monthKey == currentMonthKey;

                            final displayMonthTitle = DateFormat('MMMM yyyy')
                                .format(monthHolidays.first.fullDate);

                            return _buildMonthAccordion(
                              monthKey: monthKey,
                              displayTitle: displayMonthTitle,
                              holidays: monthHolidays,
                              isExpanded: isExpanded,
                              isCurrentMonth: isCurrentMonth,
                              onToggle: () {
                                setState(() {
                                  _expandedMonths[monthKey] = !isExpanded;
                                });
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Toolbar
  Widget _buildTopToolbar({
    required BuildContext context,
    required AppState appState,
    required List<AcademicYearItem> academicYears,
    required AcademicYearItem? selectedYear,
    required String? selectedYearId,
    required int holidayCount,
    required List<String> monthKeys,
    required bool allExpanded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Academic Year Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'Year: ${selectedYear?.name ?? '2026-27'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Total Holidays badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Text(
              '$holidayCount ${holidayCount == 1 ? 'holiday' : 'holidays'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),

          const Spacer(),

          // Expand / Collapse All Toggle Button
          if (monthKeys.isNotEmpty)
            InkWell(
              onTap: () => _toggleAllMonths(monthKeys, !allExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allExpanded
                          ? LucideIcons.chevronsDownUp
                          : LucideIcons.chevronsUpDown,
                      size: 13,
                      color: const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      allExpanded ? 'Collapse All' : 'Expand All',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
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

  // Past Holidays Collapsible Section
  Widget _buildPastHolidaysSection(
    List<MapEntry<String, List<Holiday>>> pastMonthEntries,
  ) {
    final pastHolidaysCount = pastMonthEntries.fold<int>(
      0,
      (sum, e) => sum + e.value.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            setState(() {
              _showPastHolidays = !_showPastHolidays;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _showPastHolidays
                    ? AppColors.primaryTeal.withValues(alpha: 0.5)
                    : const Color(0xFFCBD5E1),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.history,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Past Holidays ($pastHolidaysCount)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _showPastHolidays ? 'Hide' : 'Show',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showPastHolidays ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showPastHolidays) ...[
          const SizedBox(height: 4),
          ...pastMonthEntries.map((entry) {
            final monthKey = entry.key;
            final monthHolidays = entry.value;
            final isExpanded = _expandedMonths[monthKey] ?? false;
            final displayMonthTitle = DateFormat('MMMM yyyy')
                .format(monthHolidays.first.fullDate);

            return _buildMonthAccordion(
              monthKey: monthKey,
              displayTitle: displayMonthTitle,
              holidays: monthHolidays,
              isExpanded: isExpanded,
              isCurrentMonth: false,
              onToggle: () {
                setState(() {
                  _expandedMonths[monthKey] = !isExpanded;
                });
              },
            );
          }),
        ],
      ],
    );
  }

  // Month Accordion
  Widget _buildMonthAccordion({
    required String monthKey,
    required String displayTitle,
    required List<Holiday> holidays,
    required bool isExpanded,
    required bool isCurrentMonth,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentMonth
              ? AppColors.primaryTeal.withValues(alpha: 0.5)
              : (isExpanded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
          width: isCurrentMonth ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accordion Header
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: isCurrentMonth
                  ? AppColors.primaryTeal.withValues(alpha: 0.04)
                  : (isExpanded ? const Color(0xFFF8FAFC) : Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Expand / Collapse Chevron icon with rotation
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? AppColors.primaryTeal.withValues(alpha: 0.15)
                                : (isExpanded
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: isCurrentMonth
                                ? AppColors.primaryTeal
                                : (isExpanded
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Month & Year title
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth
                              ? AppColors.primaryTeal
                              : const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(width: 8),

                      if (isCurrentMonth) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'THIS MONTH',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryTeal,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Month count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${holidays.length} ${holidays.length == 1 ? 'holiday' : 'holidays'}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Collapsed Preview Chips
                  if (!isExpanded && holidays.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: holidays.map((h) {
                          final theme = getHolidayTheme(h.title, h.type);
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.bg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.border, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${h.date} ${h.month}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.text,
                                  ),
                                ),
                                Text(
                                  ' - ${h.title}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: theme.text,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded Content: Holiday Cards list
          if (isExpanded) ...[
            Container(color: const Color(0xFFE2E8F0), height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: holidays.length,
              separatorBuilder: (context, i) => const Divider(
                color: Color(0xFFF1F5F9),
                height: 14,
                thickness: 1,
              ),
              itemBuilder: (context, idx) {
                final holiday = holidays[idx];
                final theme = getHolidayTheme(holiday.title, holiday.type);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calendar Date Badge Block
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.border, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            holiday.month.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            holiday.date,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title, Date info, Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holiday.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${holiday.date} ${holiday.month} ${holiday.fullDate.year} • ${holiday.day}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (holiday.description != null &&
                              holiday.description!.trim().isNotEmpty &&
                              holiday.description != holiday.title) ...[
                            const SizedBox(height: 2),
                            Text(
                              holiday.description!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Category Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.border, width: 0.8),
                      ),
                      child: Text(
                        holiday.type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                LucideIcons.calendarOff,
                size: 28,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No holidays scheduled',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No holidays have been published for this academic year yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. EVENTS SCREEN (Exact parity with Parent App)
// =============================================================================

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedCategory = 'ALL';
  bool? _isPastEventsExpanded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.refreshEvents();
    if (mounted) setState(() {});
  }

  Color _getCategoryBg(String cat) {
    switch (cat.toUpperCase()) {
      case 'CULTURAL':
        return const Color(0xFFF3E8FF);
      case 'ACADEMIC':
        return const Color(0xFFE0F2FE);
      case 'SPORTS':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFE0F2F1);
    }
  }

  Color _getCategoryText(String cat) {
    switch (cat.toUpperCase()) {
      case 'CULTURAL':
        return const Color(0xFF7E22CE);
      case 'ACADEMIC':
        return const Color(0xFF0369A1);
      case 'SPORTS':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF00695C);
    }
  }

  DateTime? _parseEventDate(Event event) {
    if (event.startDate.isNotEmpty) {
      final parsed = DateTime.tryParse(event.startDate);
      if (parsed != null) return parsed;
    }
    if (event.date.isNotEmpty) {
      final parsed = DateTime.tryParse(event.date);
      if (parsed != null) return parsed;
    }
    return null;
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool isCollapsible = false,
    bool isExpanded = true,
    VoidCallback? onToggle,
  }) {
    final content = Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (isCollapsible) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isExpanded ? 'Hide' : 'Show',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 13,
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (isCollapsible && onToggle != null) {
      return InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildEventCard(BuildContext context, Event event, {required bool isPast}) {
    final parsedDate = _parseEventDate(event);

    final monthLabel = parsedDate != null
        ? DateFormat('MMM').format(parsedDate).toUpperCase()
        : 'EVT';
    final dayLabel = parsedDate != null ? DateFormat('d').format(parsedDate) : '•';
    final weekDayLabel = parsedDate != null ? DateFormat('EEE').format(parsedDate) : '';

    final catBg = _getCategoryBg(event.category);
    final catColor = _getCategoryText(event.category);

    return Container(
      decoration: BoxDecoration(
        color: isPast ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPast ? const Color(0xFFE2E8F0) : AppColors.border,
          width: 1,
        ),
        boxShadow: isPast
            ? const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                )
              ]
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge Box (Green for Upcoming, Muted Slate for Past)
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isPast ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPast ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        monthLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isPast ? const Color(0xFF64748B) : const Color(0xFF15803D),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isPast ? const Color(0xFF334155) : const Color(0xFF166534),
                        ),
                      ),
                      if (weekDayLabel.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          weekDayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isPast ? const Color(0xFF94A3B8) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category, Scope & Completed Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPast ? const Color(0xFFF1F5F9) : catBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPast ? const Color(0xFF64748B) : catColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (isPast)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          if (event.scope.isNotEmpty && event.scope != 'SCHOOL')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.scope == 'CLASS' ? 'Class Event' : 'Section Event',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Event Title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPast ? const Color(0xFF334155) : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Time Row
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 13,
                            color: isPast ? const Color(0xFF94A3B8) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            event.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast ? const Color(0xFF94A3B8) : AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Location Row
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 13,
                            color: isPast ? const Color(0xFF94A3B8) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast ? const Color(0xFF94A3B8) : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: isPast ? const Color(0xFFCBD5E1) : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allEvents = appState.events;
    final teacher = appState.teacher;
    final profilePic = appState.profilePic;
    final isLoading = appState.isEventsLoading;

    // Filter events based on category
    final filteredEvents = _selectedCategory == 'ALL'
        ? allEvents
        : allEvents.where((e) => e.category.toUpperCase() == _selectedCategory).toList();

    // Split events into Upcoming (>= today, sorted ascending) and Past (< today, sorted descending)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    AcademicYearItem? currentYear;
    try {
      currentYear = appState.academicYears.firstWhere(
        (y) => y.isCurrent,
        orElse: () => appState.academicYears.isNotEmpty ? appState.academicYears.first : null as dynamic,
      );
    } catch (_) {}
    final currentYearStart = currentYear?.startDate;

    final upcomingEvents = filteredEvents.where((e) {
      final dt = _parseEventDate(e);
      return dt != null && !dt.isBefore(today);
    }).toList();

    final pastEvents = filteredEvents.where((e) {
      final dt = _parseEventDate(e);
      if (dt == null) return false;
      final isPast = dt.isBefore(today);
      final isWithinCurrentSession = currentYearStart == null || !dt.isBefore(currentYearStart);
      return isPast && isWithinCurrentSession;
    }).toList();

    // Sort upcoming ascending (nearest first)
    upcomingEvents.sort((a, b) {
      final dtA = _parseEventDate(a) ?? DateTime(2099);
      final dtB = _parseEventDate(b) ?? DateTime(2099);
      return dtA.compareTo(dtB);
    });

    // Sort past descending (most recent first)
    pastEvents.sort((a, b) {
      final dtA = _parseEventDate(a) ?? DateTime(1970);
      final dtB = _parseEventDate(b) ?? DateTime(1970);
      return dtB.compareTo(dtA);
    });

    final bool isPastExpanded = _isPastEventsExpanded ?? upcomingEvents.isEmpty;

    const categories = ['ALL', 'CULTURAL', 'ACADEMIC', 'SPORTS', 'GENERAL'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          appState.translate('events'),
          style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                  )
                : const Icon(LucideIcons.refreshCw, color: AppColors.textMain, size: 20),
            onPressed: isLoading ? null : _loadEvents,
            tooltip: 'Refresh Events',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Badge Header (matching Parent App structure)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryTeal,
                      ),
                      alignment: Alignment.center,
                      child: profilePic != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.memory(
                                base64Decode(profilePic),
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              teacher?.name.isNotEmpty == true
                                  ? teacher!.name.substring(0, 1).toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher?.name ?? 'Teacher',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            (teacher?.assignedClass != null && teacher!.assignedClass!.isNotEmpty)
                                ? '${teacher.designation} • ${teacher.assignedClass}'
                                : (teacher?.designation ?? 'Teacher'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${allEvents.length} Events',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          cat == 'ALL' ? 'All Events' : cat.substring(0, 1) + cat.substring(1).toLowerCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textMain,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primaryTeal,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryTeal : AppColors.border,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Events List
              if (isLoading && allEvents.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                ),
              ] else if (filteredEvents.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.calendar, size: 28, color: AppColors.primaryTeal),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Events Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedCategory == 'ALL'
                            ? 'There are no upcoming events or celebrations scheduled right now.'
                            : 'No events found under the selected category.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // --- SECTION 1: UPCOMING EVENTS ---
                _buildSectionHeader(
                  title: 'UPCOMING EVENTS',
                  count: upcomingEvents.length,
                  icon: LucideIcons.calendarClock,
                  color: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 10),
                if (upcomingEvents.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingEvents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) => _buildEventCard(context, upcomingEvents[idx], isPast: false),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.calendarCheck2, size: 20, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Upcoming Events',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'No planned events at the moment. Check back soon!',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF115E59),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // --- SECTION 2: PAST EVENTS ---
                if (pastEvents.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'PAST EVENTS',
                    count: pastEvents.length,
                    icon: LucideIcons.history,
                    color: const Color(0xFF64748B),
                    isCollapsible: true,
                    isExpanded: isPastExpanded,
                    onToggle: () {
                      setState(() {
                        _isPastEventsExpanded = !isPastExpanded;
                      });
                    },
                  ),
                  if (isPastExpanded) ...[
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pastEvents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) => _buildEventCard(context, pastEvents[idx], isPast: true),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. EVENT DETAIL SCREEN (Exact parity with Parent App)
// =============================================================================

class EventDetailScreen extends StatelessWidget {
  final Event? event;

  const EventDetailScreen({super.key, this.event});

  Color _getCategoryBg(String cat) {
    switch (cat.toUpperCase()) {
      case 'CULTURAL':
        return const Color(0xFFF3E8FF);
      case 'ACADEMIC':
        return const Color(0xFFE0F2FE);
      case 'SPORTS':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFE0F2F1);
    }
  }

  Color _getCategoryText(String cat) {
    switch (cat.toUpperCase()) {
      case 'CULTURAL':
        return const Color(0xFF7E22CE);
      case 'ACADEMIC':
        return const Color(0xFF0369A1);
      case 'SPORTS':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF00695C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = event ?? ModalRoute.of(context)?.settings.arguments as Event?;

    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final appState = Provider.of<AppState>(context);

    DateTime? parsedDate;
    if (e.startDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(e.startDate);
    }
    if (parsedDate == null && e.date.isNotEmpty) {
      parsedDate = DateTime.tryParse(e.date);
    }
    final fullDateStr = parsedDate != null
        ? DateFormat('EEEE, d MMMM yyyy').format(parsedDate)
        : e.date;

    final catBg = _getCategoryBg(e.category);
    final catColor = _getCategoryText(e.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          appState.translate('eventDetails'),
          style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e.scope == 'SCHOOL'
                              ? 'School Wide'
                              : (e.scope == 'CLASS' ? 'Class Event' : 'Section Event'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fullDateStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.clock, size: 18, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.time,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Venue / Location Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.mapPin, size: 18, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Venue / Location',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.location.isNotEmpty ? e.location : 'School Campus',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description Box
            if (e.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About This Event',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attendance Impact Box (if not regular)
            if (e.attendanceImpact.isNotEmpty && e.attendanceImpact != 'REGULAR_ATTENDANCE') ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attendance Impact: ${e.attendanceImpact.replaceAll('_', ' ')}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 5. GALLERY SCREEN & ALBUM DETAIL SCREEN (Preserved)
// =============================================================================

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final albums = appState.albums;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          appState.translate('gallery'),
          style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: albums.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, size: 28, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Photo Albums',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'School event photos and albums will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final a = albums[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3))
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailScreen(album: a),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(a.coverPhoto),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.photoCount} photos',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  final Album album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          album.title,
          style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: album.photos.isEmpty
          ? const Center(
              child: Text(
                'No photos in this album yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: album.photos.length,
              itemBuilder: (context, index) {
                final p = album.photos[index];

                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing image ${p.id} of ${album.title}')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(p.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
