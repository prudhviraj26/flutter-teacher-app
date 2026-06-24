import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'constants/colors.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/language_screen.dart';
import 'screens/announcement_screen.dart';
import 'screens/class_update_screen.dart';
import 'screens/attendance_screens.dart';
import 'screens/parent_connect_screen.dart';
import 'screens/student_roster_screen.dart';
import 'screens/duty_diary_screen.dart';
import 'screens/staff_notice_screen.dart';
import 'screens/school_notice_screen.dart';
import 'screens/all_sections_screen.dart';
import 'screens/holiday_event_screens.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/profile_menu_screens.dart';

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'School Teacher App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              background: AppColors.background,
            ),
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text),
              bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
              bodyMedium: TextStyle(fontSize: 14, color: AppColors.text),
              labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
            ),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/profile/language': (context) => const LanguageScreen(),
            '/announcement': (context) => const AnnouncementScreen(),
            '/class-update': (context) => const ClassUpdateScreen(),
            '/attendance': (context) => const AttendanceRollCallScreen(),
            '/attendance/confirm': (context) => const AttendanceConfirmationScreen(),
            '/attendance/submitted': (context) => const AttendanceSubmittedScreen(),
            '/attendance/correction': (context) => const AttendanceCorrectionScreen(),
            '/parent-connect': (context) => const ParentConnectScreen(),
            '/students': (context) => const StudentRosterScreen(),
            '/duty-diary': (context) => const DutyDiaryScreen(),
            '/staff-notice': (context) => const StaffNoticeScreen(),
            '/school-notice': (context) => const SchoolNoticeScreen(),
            '/all-sections': (context) => const AllSectionsScreen(),
            '/holidays': (context) => const HolidaysScreen(),
            '/events': (context) => const EventsScreen(),
            '/gallery': (context) => const GalleryScreen(),
            '/profile/edit': (context) => const TeacherProfileDetailScreen(),
            '/profile/change-password': (context) => const ChangePasswordScreen(),
            '/profile/feedback': (context) => const FeedbackScreen(),
            '/profile/about-us': (context) => const AboutUsScreen(),
            '/profile/help': (context) => const HelpFAQScreen(),
            '/profile/privacy': (context) => const PrivacySecurityScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle dynamic routes with arguments (e.g. Chat detail, Student profile, Notice detail)
            if (settings.name != null && settings.name!.startsWith('/parent-connect/chat/')) {
              final parentId = settings.name!.substring('/parent-connect/chat/'.length);
              return MaterialPageRoute(
                builder: (context) => ParentChatScreen(parentId: parentId),
                settings: settings,
              );
            }
            if (settings.name != null && settings.name!.startsWith('/students/profile/')) {
              final studentId = settings.name!.substring('/students/profile/'.length);
              return MaterialPageRoute(
                builder: (context) => StudentProfileScreen(studentId: studentId),
                settings: settings,
              );
            }
            if (settings.name != null && settings.name!.startsWith('/coming-soon/')) {
              final feature = settings.name!.substring('/coming-soon/'.length);
              return MaterialPageRoute(
                builder: (context) => ComingSoonScreen(featureKey: feature),
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}
