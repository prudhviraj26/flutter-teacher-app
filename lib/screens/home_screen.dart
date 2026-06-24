import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../widgets/menu_card.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;
    
    if (teacher == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine unread messages count
    int unreadMessagesCount = appState.parentConversations
        .where((c) => c.unread || (c.messages.isNotEmpty && c.messages.last.failed))
        .length;

    final String schoolName = appState.language == 'mr'
        ? appState.schoolConfig.nameMarathi
        : appState.language == 'hi'
            ? appState.schoolConfig.nameHindi
            : appState.schoolConfig.name;

    final String designationText = teacher.designation == 'Class Teacher'
        ? appState.translate('classTeacher')
        : appState.translate('subjectTeacher');

    final String assignedClassText = teacher.assignedClass != null 
        ? ' • ${teacher.assignedClass}' 
        : '';

    return Scaffold(
      body: Column(
        children: [
          // Header Panel
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // School Logo / Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                // School Name & Teacher details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$designationText$assignedClassText',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Profile Avatar Button
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      backgroundImage: appState.profilePic != null
                          ? MemoryImage(base64Decode(appState.profilePic!))
                          : null,
                      child: appState.profilePic == null
                          ? Text(
                              teacher.name.isNotEmpty ? teacher.name[0] : 'T',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Grid & Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      // Announcement
                      MenuCard(
                        icon: Icons.campaign_outlined,
                        title: appState.translate('announcement'),
                        subtitle: teacher.designation == 'Class Teacher'
                            ? appState.translate('postUpdates')
                            : appState.translate('viewOnly'),
                        backgroundColor: AppColors.secondary,
                        onTap: () => Navigator.pushNamed(context, '/announcement'),
                      ),
                      // Class Update
                      MenuCard(
                        icon: Icons.menu_book_outlined,
                        title: appState.translate('classUpdate'),
                        subtitle: appState.translate('homeworkAndClasswork'),
                        backgroundColor: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, '/class-update'),
                      ),
                      // Attendance
                      MenuCard(
                        icon: Icons.assignment_turned_in_outlined,
                        title: appState.translate('attendance'),
                        subtitle: appState.translate('markDailyAttendance'),
                        backgroundColor: AppColors.primary,
                        onTap: () {
                          appState.initTempAttendance();
                          Navigator.pushNamed(context, '/attendance');
                        },
                      ),
                      // Students
                      MenuCard(
                        icon: Icons.people_outline,
                        title: appState.translate('students'),
                        subtitle: teacher.assignedClass ?? appState.translate('studentRoster'),
                        backgroundColor: AppColors.secondary,
                        onTap: () => Navigator.pushNamed(context, '/students'),
                      ),
                      // Parent Connect
                      MenuCard(
                        icon: Icons.chat_bubble_outline,
                        title: appState.translate('parentConnect'),
                        subtitle: appState.translate('messageParents'),
                        backgroundColor: AppColors.secondary,
                        badgeCount: unreadMessagesCount,
                        onTap: () => Navigator.pushNamed(context, '/parent-connect'),
                      ),
                      // School Notice
                      MenuCard(
                        icon: Icons.volume_up_outlined,
                        title: appState.language == 'mr'
                            ? 'शाळेच्या सूचना'
                            : appState.language == 'hi'
                                ? 'स्कूल नोटिस'
                                : 'School Notice',
                        subtitle: appState.language == 'mr'
                            ? 'शाळेचे परिपत्रक पहा'
                            : appState.language == 'hi'
                                ? 'स्कूल सर्कुलर देखें'
                                : 'View school circulars',
                        backgroundColor: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, '/school-notice'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // View All Section Button
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/all-sections'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appState.language == 'mr'
                              ? 'सर्व विभाग पहा'
                              : appState.language == 'hi'
                                  ? 'सभी अनुभाग देखें'
                                  : 'View All Section',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentRoute: '/home'),
    );
  }
}
