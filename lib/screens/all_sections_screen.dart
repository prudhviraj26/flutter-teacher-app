import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

class AllSectionsScreen extends StatelessWidget {
  const AllSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Section configs
    final sections = [
      {
        'title': appState.translate('schedule'),
        'features': [
          {
            'name': appState.translate('dutyDiary'),
            'subtitle': appState.translate('myDuties'),
            'icon': Icons.calendar_month_outlined,
            'route': '/duty-diary',
          },
          {
            'name': appState.translate('attendance'),
            'subtitle': appState.translate('markDailyAttendance'),
            'icon': Icons.assignment_turned_in_outlined,
            'route': '/attendance',
          },
          {
            'name': appState.translate('holidays'),
            'subtitle': appState.language == 'mr'
                ? 'शाळेच्या सुट्ट्या'
                : appState.language == 'hi'
                    ? 'स्कूल की छुट्टियां'
                    : 'School holidays',
            'icon': Icons.flight_takeoff_outlined,
            'route': '/holidays',
          },
          {
            'name': appState.translate('events'),
            'subtitle': appState.language == 'mr'
                ? 'आगामी कार्यक्रम'
                : appState.language == 'hi'
                    ? 'आगामी कार्यक्रम'
                    : 'Upcoming events',
            'icon': Icons.event_outlined,
            'route': '/events',
          },
        ],
      },
      {
        'title': appState.translate('communication'),
        'features': [
          {
            'name': appState.language == 'mr'
                ? 'कर्मचारी नोटीस'
                : appState.language == 'hi'
                    ? 'स्टाफ नोटिस'
                    : 'Staff Notice',
            'subtitle': appState.language == 'mr'
                ? 'कर्मचारी सूचना'
                : appState.language == 'hi'
                    ? 'कर्मचारी नोटिस'
                    : 'Staff circulars',
            'icon': Icons.notifications_none_outlined,
            'route': '/staff-notice',
          },
          {
            'name': appState.translate('schoolNotice'),
            'subtitle': appState.language == 'mr'
                ? 'शाळेच्या सूचना'
                : appState.language == 'hi'
                    ? 'स्कूल नोटिस'
                    : 'School circulars',
            'icon': Icons.campaign_outlined,
            'route': '/school-notice',
          },
          {
            'name': appState.translate('classUpdate'),
            'subtitle': appState.translate('homeworkAndClasswork'),
            'icon': Icons.menu_book_outlined,
            'route': '/class-update',
          },
          {
            'name': appState.translate('announcement'),
            'subtitle': appState.translate('postUpdates'),
            'icon': Icons.campaign_outlined,
            'route': '/announcement',
          },
        ],
      },
      {
        'title': appState.translate('schoolOnline'),
        'features': [
          {
            'name': appState.translate('students'),
            'subtitle': appState.translate('studentRoster'),
            'icon': Icons.people_outline,
            'route': '/students',
          },
          {
            'name': appState.translate('healthRecords'),
            'subtitle': appState.language == 'mr'
                ? 'आरोग्य नोंदी'
                : appState.language == 'hi'
                    ? 'स्वास्थ्य लॉग'
                    : 'Student health logs',
            'icon': Icons.favorite_border_outlined,
            'route': '/coming-soon/healthRecords',
          },
          {
            'name': appState.translate('examDetails'),
            'subtitle': appState.language == 'mr'
                ? 'परीक्षा वेळापत्रक'
                : appState.language == 'hi'
                    ? 'परीक्षा समय-सारणी'
                    : 'Exam schedules',
            'icon': Icons.description_outlined,
            'route': '/coming-soon/examDetails',
          },
          {
            'name': appState.translate('examResults'),
            'subtitle': appState.language == 'mr'
                ? 'परीक्षा निकाल'
                : appState.language == 'hi'
                    ? 'परीक्षा परिणाम'
                    : 'View results',
            'icon': Icons.description_outlined,
            'route': '/coming-soon/examResults',
          },
          {
            'name': appState.translate('gallery'),
            'subtitle': appState.language == 'mr'
                ? 'शाळेचे अल्बम'
                : appState.language == 'hi'
                    ? 'स्कूल एलबम'
                    : 'School albums',
            'icon': Icons.image_outlined,
            'route': '/gallery',
          },
        ],
      },
      {
        'title': appState.translate('learning'),
        'features': [
          {
            'name': appState.translate('learningDevelopment'),
            'subtitle': appState.language == 'mr'
                ? 'शैक्षणिक संसाधने'
                : appState.language == 'hi'
                    ? 'अध्ययन संसाधन'
                    : 'L&D resources',
            'icon': Icons.description_outlined,
            'route': '/coming-soon/learningDevelopment',
          },
          {
            'name': appState.translate('library'),
            'subtitle': appState.language == 'mr'
                ? 'पुस्तकांचे रेकॉर्ड'
                : appState.language == 'hi'
                    ? 'पुस्तक रिकॉर्ड'
                    : 'Book records',
            'icon': Icons.local_library_outlined,
            'route': '/coming-soon/library',
          },
        ],
      },
    ];

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
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  appState.translate('viewAllSections'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // List grouping
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final features = section['features'] as List<Map<String, dynamic>>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppColors.secondary, width: 4),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            section['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Grid child items
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: features.length,
                          itemBuilder: (context, fIdx) {
                            final f = features[fIdx];
                            final bg = _getFeatureColor(f['route'] as String);

                            return InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, f['route'] as String);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(f['icon'] as IconData, color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          f['name'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      f['subtitle'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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

  Color _getFeatureColor(String route) {
    if (route.contains('/announcement') ||
        route.contains('/students') ||
        route.contains('/parent-connect') ||
        route.contains('examResults') ||
        route.contains('gallery') ||
        route.contains('learningDevelopment') ||
        route.contains('feedback') ||
        route.contains('privacySecurity') ||
        route.contains('help') ||
        route.contains('duty-diary') ||
        route.contains('events') ||
        route.contains('staff-notice')) {
      return AppColors.secondary;
    }
    return AppColors.primary;
  }
}
