import 'package:flutter/material.dart';

/// Shared header dropdown for switching between assigned classes+sections
/// across Students, Attendance, Class Announcement, and Class Update screens.
class ClassSelectorDropdown extends StatelessWidget {
  final List<String> classes;
  final String selectedClass;
  final ValueChanged<String> onChanged;
  final Color accentColor;
  final Map<String, int>? unreadCounts;
  final bool hideWhenSingle;

  const ClassSelectorDropdown({
    super.key,
    required this.classes,
    required this.selectedClass,
    required this.onChanged,
    required this.accentColor,
    this.unreadCounts,
    this.hideWhenSingle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty || (hideWhenSingle && classes.length <= 1)) {
      return const SizedBox.shrink();
    }

    final effectiveValue = classes.contains(selectedClass) ? selectedClass : classes.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      constraints: const BoxConstraints(maxWidth: 160),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isDense: true,
          dropdownColor: accentColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          selectedItemBuilder: (context) => classes.map((c) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                c,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          items: classes.map((c) {
            final unread = unreadCounts?[c] ?? 0;
            return DropdownMenuItem<String>(
              value: c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      c,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$unread',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

