import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Color(0xFF4B5563), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                appState.translate('logout'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            appState.translate('areYouSure'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                appState.translate('cancel'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(context);
                appState.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: Text(
                appState.translate('confirm'),
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teacher = appState.teacher;

    if (teacher == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String designationText = teacher.designation == 'Class Teacher'
        ? appState.translate('classTeacher')
        : appState.translate('subjectTeacher');

    final String assignedClassText = teacher.assignedClass != null 
        ? ' • ${teacher.assignedClass}' 
        : '';

    final menuItems = [
      {
        'icon': Icons.person_outline,
        'label': appState.translate('teacherProfile'),
        'route': '/profile/edit',
      },
      {
        'icon': Icons.lock_outline,
        'label': appState.translate('changePassword'),
        'route': '/profile/change-password',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': appState.translate('feedback'),
        'route': '/profile/feedback',
      },
      {
        'icon': Icons.info_outline,
        'label': appState.translate('aboutUs'),
        'route': '/profile/about-us',
      },
      {
        'icon': Icons.help_outline,
        'label': appState.translate('help'),
        'route': '/profile/help',
      },
      {
        'icon': Icons.language_outlined,
        'label': appState.translate('language'),
        'route': '/profile/language',
      },
      {
        'icon': Icons.shield_outlined,
        'label': appState.translate('privacySecurity'),
        'route': '/profile/privacy',
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header & Info Card
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nav Bar
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
                      appState.translate('myProfile'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            backgroundImage: appState.profilePic != null
                                ? MemoryImage(const Base64Decoder().convert(appState.profilePic!))
                                : (teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty
                                    ? NetworkImage(teacher.photoUrl!)
                                    : null) as ImageProvider?,
                            child: (appState.profilePic == null && (teacher.photoUrl == null || teacher.photoUrl!.isEmpty))
                                ? Text(
                                    teacher.name.isNotEmpty ? teacher.name[0] : 'T',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$designationText$assignedClassText',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            offset: const Offset(0, 36),
                            onSelected: (value) {
                              if (value == 'logout') {
                                _handleLogout(context, appState);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Color(0xFF4B5563),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      appState.translate('logout'),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.primary),
                      ),
                      title: Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => Navigator.pushNamed(context, item['route'] as String),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentRoute: '/profile'),
    );
  }
}
