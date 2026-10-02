import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../constants/translations.dart';
import '../services/auth_service.dart';
import '../services/teacher_data_service.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Language & Session
  String _language = 'en';
  bool _loggedIn = false;
  Teacher? _teacher;
  String? _profilePic;

  // Mock Data lists
  List<Student> _students = [];
  List<Announcement> _announcements = [];
  List<ClassUpdate> _classUpdates = [];
  List<DailyAttendance> _attendanceHistory = [];
  List<ParentConversation> _parentConversations = [];
  List<Duty> _duties = [];
  List<StaffNotice> _staffNotices = [];
  List<Notice> _notices = [];
  List<Event> _events = [];
  List<Album> _albums = [];
  List<Holiday> _holidays = [];
  List<ExamResult> _examResults = [];

  // Active Attendance Marking Session
  Map<String, String> _tempAttendance = {}; // studentId -> status ('P' | 'A')
  Map<String, String> _tempAttendanceReasons = {}; // studentId -> absent reason

  bool _isLoadingStudents = false;
  bool _isAttendanceSubmittedToday = false;
  bool _isSubmittingAttendance = false;

  // Teacher Own Monthly Attendance & Calendar
  TeacherMonthlyAttendance? _monthlyAttendance;
  bool _isLoadingMonthlyAttendance = false;

  // Getters
  String get language => _language;
  bool get loggedIn => _loggedIn;
  Teacher? get teacher => _teacher;
  String? get profilePic => _profilePic;
  String get currentSchoolName => _teacher?.schoolName ?? schoolConfig.name;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isAttendanceSubmittedToday => _isAttendanceSubmittedToday;
  bool get isSubmittingAttendance => _isSubmittingAttendance;
  TeacherMonthlyAttendance? get monthlyAttendance => _monthlyAttendance;
  bool get isLoadingMonthlyAttendance => _isLoadingMonthlyAttendance;

  final SchoolConfig schoolConfig = SchoolConfig(
    name: 'Demo International School',
    nameMarathi: 'डेमो आंतरराष्ट्रीय शाळा',
    nameHindi: 'डेमो इंटरनेशनल स्कूल',
  );

  List<Student> get students => _students;
  List<Announcement> get announcements => _announcements;
  List<ClassUpdate> get classUpdates => _classUpdates;
  List<DailyAttendance> get attendanceHistory => _attendanceHistory;
  List<ParentConversation> get parentConversations => _parentConversations;
  List<Duty> get duties => _duties;
  List<StaffNotice> get staffNotices => _staffNotices;
  List<Notice> get notices => _notices;
  List<Event> get events => _events;
  List<Album> get albums => _albums;
  List<Holiday> get holidays => _holidays;
  List<ExamResult> get examResults => _examResults;

  Map<String, String> get tempAttendance => _tempAttendance;
  Map<String, String> get tempAttendanceReasons => _tempAttendanceReasons;

  // Constructor
  AppState() {
    _initPreferences();
  }

  // Init Shared Preferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load language
    _language = _prefs?.getString('veyho_language') ?? 'en';
    
    // Load session user
    final userJson = _prefs?.getString('veyho_teacher_user');
    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = json.decode(userJson);
        _loggedIn = userData['loggedIn'] as bool? ?? false;
        if (userData['teacher'] != null) {
          _teacher = Teacher.fromJson(userData['teacher']);
        }
      } catch (e) {
        // clear corrupted data
        _prefs?.remove('veyho_teacher_user');
      }
    }
    
    // Load cached notices and class updates immediately on startup
    await _loadCachedNotices();
    await _loadClassUpdates();

    notifyListeners();

    if (_loggedIn) {
      loadLiveData();
    }
  }

  // Load Live Data from NestJS API
  Future<void> loadLiveData() async {
    if (!_loggedIn) return;

    _isLoadingStudents = true;
    notifyListeners();

    try {
      // Refresh current teacher details from /auth/me if available
      try {
        final meResponse = await AuthService.getMe();
        final userMap = meResponse['user'] as Map<String, dynamic>?;
        if (userMap != null) {
          final String firstName = userMap['firstName'] ?? '';
          final String lastName = userMap['lastName'] ?? '';
          final String fullName = "$firstName $lastName".trim();
          final String role = userMap['role'] ?? 'class_teacher';

          final String apiSchoolName = userMap['schoolName'] as String? ?? 'Demo International School';
          final String? apiAssignedClass = userMap['assignedClass'] as String?;
          final String? apiSectionId = userMap['sectionId'] as String?;
          final String apiEmployeeId = userMap['employeeId'] as String? ?? userMap['employeeCode'] as String? ?? 'EMP-2026-001';

          List<String> parsedSubjects = [];
          if (userMap['subjects'] != null && userMap['subjects'] is List) {
            parsedSubjects = (userMap['subjects'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          }
          if (parsedSubjects.isEmpty) {
            parsedSubjects = ['General'];
          }

          List<String>? parsedAssignedClasses;
          if (userMap['assignedClasses'] != null && userMap['assignedClasses'] is List) {
            parsedAssignedClasses = (userMap['assignedClasses'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          }

          final String designation = (role == 'class_teacher' || (userMap['roles'] is List && (userMap['roles'] as List).contains('class_teacher')))
              ? 'Class Teacher'
              : 'Subject Teacher';

          final String joiningDate = userMap['joiningDate'] as String? ?? userMap['dateOfJoining'] as String? ?? '01-06-2022';

          _teacher = Teacher(
            id: userMap['id'] ?? 'T001',
            name: fullName.isNotEmpty ? fullName : 'Teacher',
            employeeId: apiEmployeeId,
            mobile: userMap['mobile'] ?? (_teacher?.mobile ?? ''),
            email: userMap['email'] ?? '',
            designation: designation,
            assignedClass: apiAssignedClass,
            sectionId: apiSectionId,
            assignedClasses: parsedAssignedClasses,
            subjects: parsedSubjects,
            joiningDate: joiningDate,
            schoolName: apiSchoolName,
          );
        }
      } catch (e) {
        debugPrint("AuthService.getMe error during loadLiveData: $e");
      }

      final String? teacherSectionId = _teacher?.sectionId;
      var liveStudents = await TeacherDataService.fetchStudents(sectionId: teacherSectionId);
      if (liveStudents.isEmpty && teacherSectionId != null) {
        // Fallback to fetch all students in school if section filter returns empty
        liveStudents = await TeacherDataService.fetchStudents();
      }
      _students = liveStudents;

      // Fetch live attendance percentages for academic year from attendance reporting
      try {
        final attPercentages = await TeacherDataService.fetchStudentAttendancePercentages(
          sectionId: teacherSectionId,
        );
        if (attPercentages.isNotEmpty) {
          _students = _students.map((s) {
            if (attPercentages.containsKey(s.id)) {
              return s.copyWith(attendancePercentage: attPercentages[s.id]);
            }
            return s;
          }).toList();
        }
      } catch (attErr) {
        debugPrint("Error fetching student attendance percentages: $attErr");
      }

      // Check today's attendance session from backend
      await fetchTodayAttendanceSession();

      // Fetch live subject assignments if current subjects are empty or default to General
      if (_teacher != null && (_teacher!.subjects.isEmpty || _teacher!.subjects.contains('General'))) {
        try {
          final liveSubjects = await TeacherDataService.fetchSubjectAssignments(_teacher!.id);
          if (liveSubjects.isNotEmpty) {
            _teacher = Teacher(
              id: _teacher!.id,
              name: _teacher!.name,
              employeeId: _teacher!.employeeId,
              mobile: _teacher!.mobile,
              email: _teacher!.email,
              designation: _teacher!.designation,
              assignedClass: _teacher!.assignedClass,
              sectionId: _teacher!.sectionId,
              assignedClasses: _teacher!.assignedClasses,
              subjects: liveSubjects,
              joiningDate: _teacher!.joiningDate,
              schoolName: _teacher!.schoolName,
            );
          }
        } catch (e) {
          debugPrint("Error fetching live subject assignments: $e");
        }
      }

      // Persist updated teacher data into preferences
      if (_teacher != null) {
        final userData = {
          'loggedIn': true,
          'teacher': _teacher!.toJson(),
        };
        await _prefs?.setString('veyho_teacher_user', json.encode(userData));
      }

      await refreshBroadcasts();
      await _loadClassUpdates();
      initTempAttendance();

      // Fetch school holidays from web admin portal
      try {
        final liveHolidays = await TeacherDataService.fetchSchoolHolidays();
        if (liveHolidays.isNotEmpty) {
          _holidays = liveHolidays;
        }
      } catch (hErr) {
        debugPrint("Error fetching live holidays: $hErr");
      }

      // Fetch teacher's monthly attendance for the current month
      final now = DateTime.now();
      final curMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      fetchMonthlyAttendance(curMonth);
    } catch (e) {
      debugPrint("Error loading live data from backend: $e");
    } finally {
      _isLoadingStudents = false;
      notifyListeners();
    }
  }

  // i18n Translate Helper
  String translate(String key) {
    Map<String, String> dict;
    if (_language == 'mr') {
      dict = AppTranslations.mr;
    } else if (_language == 'hi') {
      dict = AppTranslations.hi;
    } else {
      dict = AppTranslations.en;
    }
    return dict[key] ?? key;
  }

  // Update Language
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs?.setString('veyho_language', lang);
    notifyListeners();
  }

  // Update Profile Picture
  Future<void> updateProfilePic(String? picBase64) async {
    if (_teacher == null) return;
    _profilePic = picBase64;
    if (picBase64 != null) {
      await _prefs?.setString('teacher_avatar_${_teacher!.employeeId}', picBase64);
    } else {
      await _prefs?.remove('teacher_avatar_${_teacher!.employeeId}');
    }
    notifyListeners();
  }

  // Login Logic
  Future<bool> login(String mobile, String password) async {
    if (mobile.isEmpty || password.isEmpty) return false;

    try {
      final response = await AuthService.login(
        emailOrMobile: mobile,
        password: password,
      );

      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final String firstName = userMap['firstName'] ?? '';
        final String lastName = userMap['lastName'] ?? '';
        final String fullName = "$firstName $lastName".trim();
        final String role = userMap['role'] ?? 'class_teacher';

        final String apiSchoolName = userMap['schoolName'] as String? ?? 'Demo International School';
        final String? apiAssignedClass = userMap['assignedClass'] as String?;
        final String? apiSectionId = userMap['sectionId'] as String?;
        final String apiEmployeeId = userMap['employeeId'] as String? ?? userMap['employeeCode'] as String? ?? 'EMP-2026-001';

        List<String> parsedSubjects = [];
        if (userMap['subjects'] != null && userMap['subjects'] is List) {
          parsedSubjects = (userMap['subjects'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        }
        if (parsedSubjects.isEmpty) {
          parsedSubjects = ['General'];
        }

        List<String>? parsedAssignedClasses;
        if (userMap['assignedClasses'] != null && userMap['assignedClasses'] is List) {
          parsedAssignedClasses = (userMap['assignedClasses'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        }

        final String designation = (role == 'class_teacher' || (userMap['roles'] is List && (userMap['roles'] as List).contains('class_teacher')))
            ? 'Class Teacher'
            : 'Subject Teacher';

        final String joiningDate = userMap['joiningDate'] as String? ?? userMap['dateOfJoining'] as String? ?? '01-06-2022';

        final loadedTeacher = Teacher(
          id: userMap['id'] ?? 'T001',
          name: fullName.isNotEmpty ? fullName : 'Teacher',
          employeeId: apiEmployeeId,
          mobile: userMap['mobile'] ?? mobile,
          email: userMap['email'] ?? '',
          designation: designation,
          assignedClass: apiAssignedClass,
          sectionId: apiSectionId,
          assignedClasses: parsedAssignedClasses,
          subjects: parsedSubjects,
          joiningDate: joiningDate,
          schoolName: apiSchoolName,
        );

        _loggedIn = true;
        _teacher = loadedTeacher;

        final userData = {
          'loggedIn': true,
          'teacher': loadedTeacher.toJson(),
        };
        await _prefs?.setString('veyho_teacher_user', json.encode(userData));
        _profilePic = _prefs?.getString('teacher_avatar_${loadedTeacher.employeeId}');
        await loadLiveData();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("API login failed, checking demo fallback: $e");
    }

    // Standard school accounts mapping from mockData.ts
    // Mobile 9999999999 = Class Teacher (Mrs. Priya Patel)
    // Mobile 1111111111 = Subject Teacher (Mr. Arjun Desai)
    bool isClass = mobile == '9999999999';
    bool isSubject = mobile == '1111111111';

    if (!isClass && !isSubject) return false;

    Teacher loadedTeacher;
    if (isClass) {
      loadedTeacher = Teacher(
        id: 'T001',
        name: 'Mrs. Priya Patel',
        employeeId: 'EMP-2020-042',
        mobile: '+91 99999 99999',
        email: 'priya.patel@school.com',
        designation: 'Class Teacher',
        assignedClass: 'Grade 3-B',
        subjects: ['Mathematics', 'Science'],
        joiningDate: '01-06-2020',
        schoolName: 'Demo International School',
      );
    } else {
      loadedTeacher = Teacher(
        id: 'T002',
        name: 'Mr. Arjun Desai',
        employeeId: 'EMP-2019-028',
        mobile: '+91 11111 11111',
        email: 'arjun.desai@school.com',
        designation: 'Subject Teacher',
        assignedClasses: ['Grade 3-A', 'Grade 3-B', 'Grade 4-A', 'Grade 4-B'],
        subjects: ['English'],
        joiningDate: '15-07-2019',
        schoolName: 'Demo International School',
      );
    }

    _loggedIn = true;
    _teacher = loadedTeacher;
    
    // Save session
    final userData = {
      'loggedIn': true,
      'teacher': loadedTeacher.toJson(),
    };
    await _prefs?.setString('veyho_teacher_user', json.encode(userData));

    // Load custom profile pic if any
    _profilePic = _prefs?.getString('teacher_avatar_${loadedTeacher.employeeId}');
    
    notifyListeners();
    return true;
  }

  // Logout Logic
  Future<void> logout() async {
    await AuthService.logout();
    _loggedIn = false;
    _teacher = null;
    _profilePic = null;
    await _prefs?.remove('veyho_teacher_user');
    notifyListeners();
  }

  // Academic Year Check Helper (2026-04-01 to 2027-03-31)
  bool _isWithinCurrentAcademicYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return true;
    try {
      final dt = DateTime.parse(dateStr);
      final ayStart = DateTime(2026, 4, 1);
      final ayEnd = DateTime(2027, 3, 31, 23, 59, 59);
      return dt.isAfter(ayStart.subtract(const Duration(seconds: 1))) &&
             dt.isBefore(ayEnd.add(const Duration(seconds: 1)));
    } catch (_) {
      return true;
    }
  }

  // Refresh and sort all broadcasts by timestamp within Academic Year
  Future<void> _loadCachedNotices() async {
    final teacherId = _teacher?.id ?? 'default';
    try {
      final staffStored = _prefs?.getString('veyho_teacher_staff_notices_$teacherId');
      if (staffStored != null && staffStored.isNotEmpty) {
        final List<dynamic> list = json.decode(staffStored);
        _staffNotices = list.map((item) => StaffNotice.fromJson(item as Map<String, dynamic>)).toList();
      }
      final schoolStored = _prefs?.getString('veyho_teacher_school_notices_$teacherId');
      if (schoolStored != null && schoolStored.isNotEmpty) {
        final List<dynamic> list = json.decode(schoolStored);
        _notices = list.map((item) => Notice.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("Error loading cached notices: $e");
    }
  }

  Future<void> _saveCachedNotices() async {
    final teacherId = _teacher?.id ?? 'default';
    try {
      final staffJson = _staffNotices.map((n) => n.toJson()).toList();
      await _prefs?.setString('veyho_teacher_staff_notices_$teacherId', json.encode(staffJson));

      final schoolJson = _notices.map((n) => n.toJson()).toList();
      await _prefs?.setString('veyho_teacher_school_notices_$teacherId', json.encode(schoolJson));
    } catch (e) {
      debugPrint("Error saving cached notices: $e");
    }
  }

  // Refresh and sort all broadcasts by timestamp within Academic Year
  Future<void> refreshBroadcasts() async {
    try {
      final liveAnnouncements = await TeacherDataService.fetchBroadcasts();
      if (liveAnnouncements.isEmpty) {
        // Keep existing cached notices if API returned empty/failed
        return;
      }

      final ayAnnouncements = liveAnnouncements
          .where((a) => _isWithinCurrentAcademicYear(a.fullDate ?? a.date))
          .toList();

      // Sort newest first by fullDate/date
      ayAnnouncements.sort((a, b) {
        final aDt = a.fullDate ?? a.date;
        final bDt = b.fullDate ?? b.date;
        return bDt.compareTo(aDt);
      });

      // 1. Staff Notices: Strictly broadcasts with scope == 'Staff' (staff_only)
      final staffList = ayAnnouncements.where((a) => a.scope == 'Staff').toList();
      _staffNotices = staffList.map((a) => StaffNotice(
        id: a.id,
        title: a.title,
        message: a.message,
        author: a.author,
        date: a.date,
        time: a.time,
        fullDate: a.fullDate,
        category: 'Meeting',
      )).toList();

      // 2. School Notices: Strictly official school-wide broadcasts (school)
      final schoolList = ayAnnouncements.where((a) => a.scope == 'School').toList();
      _notices = schoolList.map((a) => Notice(
        id: a.id,
        source: a.author,
        title: a.title,
        body: a.message,
        date: a.date,
        time: a.time,
        fullDate: a.fullDate,
      )).toList();

      // 3. Class Announcements:
      // Filter out any communications sent via Class Update module (Classwork and Homework)
      // and only include:
      // - Announcements composed by the teacher himself/herself
      // - Announcements sent by the Admin via webadmin portal targeted to this teacher's class/section
      final classList = ayAnnouncements.where((a) {
        // Exclude staff and school wide general notices
        if (a.scope == 'Staff' || a.scope == 'School') {
          return false;
        }

        final titleLower = a.title.toLowerCase().trim();
        // Strict exclusion of Classwork and Homework
        if (titleLower.startsWith('[classwork]') ||
            titleLower.startsWith('[homework]') ||
            titleLower.startsWith('classwork:') ||
            titleLower.startsWith('homework:')) {
          return false;
        }

        // Check if composed by this teacher
        final isAuthoredByTeacher = (_teacher?.id != null && a.authorId == _teacher!.id) ||
            (_teacher?.name != null && a.author.toLowerCase() == _teacher!.name.toLowerCase());

        if (isAuthoredByTeacher) {
          return true;
        }

        // Check if sent by Admin / School targeted to this teacher's class/section
        if (a.scope == 'Class' || a.scope == 'Direct') {
          final teacherClasses = <String>[];
          if (_teacher?.assignedClass != null && _teacher!.assignedClass!.isNotEmpty) {
            teacherClasses.add(_teacher!.assignedClass!.toLowerCase());
          }
          if (_teacher?.assignedClasses != null) {
            for (var c in _teacher!.assignedClasses!) {
              if (c.isNotEmpty) teacherClasses.add(c.toLowerCase());
            }
          }

          if (teacherClasses.isEmpty || a.classScope == null || a.classScope!.isEmpty) {
            return true;
          }

          final targetClassLower = a.classScope!.toLowerCase();
          final isMatch = teacherClasses.any((tc) =>
              targetClassLower.contains(tc) ||
              tc.contains(targetClassLower) ||
              targetClassLower.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').contains(tc.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')) ||
              tc.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').contains(targetClassLower.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')) ||
              targetClassLower == 'class notice');
          return isMatch;
        }

        return false;
      }).toList();
      _announcements = classList;

      await _saveCachedNotices();
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing broadcasts: $e");
    }
  }

  // Add Class Announcement with live API Sync to Web Admin Sent Items
  Future<void> addAnnouncement(Announcement ann) async {
    _announcements.insert(0, ann);
    notifyListeners();

    if (_loggedIn) {
      try {
        final hasSection = _teacher?.sectionId != null && _teacher!.sectionId!.isNotEmpty;
        await TeacherDataService.createBroadcast(
          title: ann.title,
          message: ann.message,
          targetType: hasSection ? 'section' : 'school',
          targetSectionId: hasSection ? _teacher!.sectionId : null,
          attachments: ann.attachments,
        );
        refreshBroadcasts();
      } catch (e) {
        debugPrint("Error syncing announcement to API: $e");
      }
    }
  }

  // Delete Announcement
  void deleteAnnouncement(String id) {
    _announcements.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  // Class Updates Storage Helpers
  Future<void> refreshClassUpdates() async {
    await _loadClassUpdates();
    notifyListeners();
  }

  // Refresh Holidays from API
  Future<void> refreshHolidays() async {
    try {
      final liveHolidays = await TeacherDataService.fetchSchoolHolidays();
      if (liveHolidays.isNotEmpty) {
        _holidays = liveHolidays;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing holidays: $e");
    }
  }

  Future<void> _loadClassUpdates() async {
    final teacherId = _teacher?.id ?? 'default';
    final stored = _prefs?.getString('veyho_teacher_class_updates_$teacherId');
    if (stored != null && stored.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(stored);
        final parsed = list.map((item) => ClassUpdate.fromJson(item as Map<String, dynamic>)).toList();
        _classUpdates = parsed.where((u) => _isWithinCurrentAcademicYear(u.date)).toList();
        // Sort newest first
        _classUpdates.sort((a, b) => b.date.compareTo(a.date));
        return;
      } catch (e) {
        debugPrint("Error loading class updates from storage: $e");
      }
    }
    _classUpdates = [];
  }

  Future<void> _saveClassUpdates() async {
    final teacherId = _teacher?.id ?? 'default';
    try {
      final jsonList = _classUpdates.map((u) => u.toJson()).toList();
      await _prefs?.setString('veyho_teacher_class_updates_$teacherId', json.encode(jsonList));
    } catch (e) {
      debugPrint("Error saving class updates to storage: $e");
    }
  }

  // Add Class Update with live API Sync to Web Admin Sent Items
  Future<void> addClassUpdate(ClassUpdate update) async {
    _classUpdates.insert(0, update);
    _saveClassUpdates();
    notifyListeners();

    if (_loggedIn) {
      try {
        final broadcastTitle = "[${update.type}] ${update.subject}: ${update.title}";
        final broadcastBody = "${update.description}${update.dueDate != null ? '\n\nDue Date: ${update.dueDate}' : ''}";
        final hasSection = _teacher?.sectionId != null && _teacher!.sectionId!.isNotEmpty;
        await TeacherDataService.createBroadcast(
          title: broadcastTitle,
          message: broadcastBody,
          targetType: hasSection ? 'section' : 'school',
          targetSectionId: hasSection ? _teacher!.sectionId : null,
          attachments: update.attachments,
        );
      } catch (e) {
        debugPrint("Error syncing class update to API: $e");
      }
    }
  }

  // Delete Class Update
  void deleteClassUpdate(String id) {
    _classUpdates.removeWhere((element) => element.id == id);
    _saveClassUpdates();
    notifyListeners();
  }

  // Teacher Own Monthly Attendance & Duty Diary Operations
  Future<void> fetchMonthlyAttendance(String month) async {
    _isLoadingMonthlyAttendance = true;
    notifyListeners();

    try {
      if (_loggedIn) {
        final result = await TeacherDataService.fetchMyMonthlyAttendance(month);
        if (result != null) {
          _monthlyAttendance = result;
          _isLoadingMonthlyAttendance = false;
          notifyListeners();
          return;
        }
      }

      // Fallback mock generator for offline/demo mode
      _monthlyAttendance = _generateMockMonthlyAttendance(month);
    } catch (e) {
      debugPrint("Error in fetchMonthlyAttendance: $e");
      _monthlyAttendance = _generateMockMonthlyAttendance(month);
    } finally {
      _isLoadingMonthlyAttendance = false;
      notifyListeners();
    }
  }

  TeacherMonthlyAttendance _generateMockMonthlyAttendance(String month) {
    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? DateTime.now().month) : DateTime.now().month;
    final totalDays = DateUtils.getDaysInMonth(year, m);

    final List<TeacherDayAttendance> days = [];
    int present = 0, absent = 0, halfDay = 0, leave = 0, notMarked = 0, instructional = 0;

    for (int d = 1; d <= totalDays; d++) {
      final dt = DateTime(year, m, d);
      final isSunday = (dt.weekday == DateTime.sunday);
      final isWorking = !isSunday;
      final dateStr = "$year-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
      final dayOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][dt.weekday - 1];

      bool isHoliday = false;
      String? holidayName;
      String? status;

      if (d == 1 && m == 5) {
        isHoliday = true;
        holidayName = 'Maharashtra Day';
      } else if (d == 15 && m == 8) {
        isHoliday = true;
        holidayName = 'Independence Day';
      } else if (d == 2 && m == 10) {
        isHoliday = true;
        holidayName = 'Gandhi Jayanti';
      } else if (isWorking) {
        instructional++;
        if (d <= DateTime.now().day && dt.isBefore(DateTime.now())) {
          if (d == 7) {
            status = 'absent';
            absent++;
          } else if (d == 9) {
            status = 'leave';
            leave++;
          } else {
            status = 'present';
            present++;
          }
        } else {
          notMarked++;
        }
      }

      days.add(TeacherDayAttendance(
        date: dateStr,
        dayOfWeek: dayOfWeek,
        isWorkingDay: isWorking,
        isHoliday: isHoliday,
        holidayName: holidayName,
        status: status,
      ));
    }

    final double? pct = instructional > 0 ? ((present + 0.5 * halfDay) / instructional) * 100 : null;

    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthLabel = "${monthNames[m - 1]} $year";

    return TeacherMonthlyAttendance(
      month: month,
      monthLabel: monthLabel,
      instructionalDays: instructional,
      summary: TeacherAttendanceSummary(
        daysPresent: present,
        daysAbsent: absent,
        daysHalfDay: halfDay,
        daysLeave: leave,
        daysNotMarked: notMarked,
        attendancePercent: pct != null ? (pct * 10).round() / 10 : null,
      ),
      days: days,
    );
  }

  // Active Attendance operations
  void initTempAttendance() {
    final validIds = _students.map((s) => s.id).toSet();
    _tempAttendance.removeWhere((key, value) => !validIds.contains(key));
    _tempAttendanceReasons.removeWhere((key, value) => !validIds.contains(key));
    for (var s in _students) {
      if (!_tempAttendance.containsKey(s.id)) {
        _tempAttendance[s.id] = 'P';
      }
    }
  }

  void updateTempAttendance(String studentId, String status) {
    _tempAttendance[studentId] = status;
    if (status == 'P') {
      _tempAttendanceReasons.remove(studentId);
    }
    notifyListeners();
  }

  void updateTempAttendanceReason(String studentId, String reason) {
    _tempAttendanceReasons[studentId] = reason;
    notifyListeners();
  }

  Future<void> fetchTodayAttendanceSession() async {
    final String? sectionId = _teacher?.sectionId;
    if (sectionId == null || sectionId.isEmpty) return;

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      final sessionData = await TeacherDataService.fetchAttendanceSession(sectionId, dateStr);
      if (sessionData != null && sessionData['session'] != null) {
        _isAttendanceSubmittedToday = true;
        final List? sessionStudents = sessionData['students'] as List?;
        if (sessionStudents != null) {
          final Map<String, String> fetchedTemp = {};
          final Map<String, String> fetchedReasons = {};
          final List<AttendanceRecord> records = [];

          for (var item in sessionStudents) {
            if (item is Map<String, dynamic>) {
              final studentId = item['studentId'] as String?;
              final currentRecord = item['currentRecord'] as Map<String, dynamic>?;
              final statusStr = currentRecord?['status'] as String?;
              final reasonStr = currentRecord?['reason'] as String?;

              if (studentId != null) {
                final isAbsent = statusStr?.toLowerCase() == 'absent';
                final status = isAbsent ? 'A' : 'P';
                fetchedTemp[studentId] = status;

                if (isAbsent && reasonStr != null && reasonStr.isNotEmpty) {
                  fetchedReasons[studentId] = reasonStr;
                }

                final idx = _students.indexWhere((s) => s.id == studentId);
                if (idx != -1) {
                  _students[idx].absentToday = isAbsent;
                }
                records.add(AttendanceRecord(studentId: studentId, status: status, reason: isAbsent ? reasonStr : null));
              }
            }
          }

          if (fetchedTemp.isNotEmpty) {
            _tempAttendance = fetchedTemp;
            _tempAttendanceReasons = fetchedReasons;
          }

          final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
          _attendanceHistory = [
            DailyAttendance(
              date: dateStr,
              classTarget: _teacher?.assignedClass ?? 'Nursery A',
              records: records,
              submittedBy: _teacher?.id ?? 'T001',
              submittedAt: "$dateStr $timeStr",
            )
          ];
        }
      } else {
        _isAttendanceSubmittedToday = false;
        initTempAttendance();
      }
    } catch (e) {
      debugPrint("Error fetching today's attendance session: $e");
    }
    notifyListeners();
  }

  String? _lastAttendanceError;
  String? get lastAttendanceError => _lastAttendanceError;

  Future<bool> submitAttendance(String teacherId) async {
    _isSubmittingAttendance = true;
    _lastAttendanceError = null;
    notifyListeners();

    final String? sectionId = _teacher?.sectionId;
    if (sectionId == null || sectionId.isEmpty) {
      _lastAttendanceError = 'No assigned section found for your teacher profile.';
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }

    if (_students.isEmpty) {
      _lastAttendanceError = 'No students found in your section roster.';
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, String>> apiRecords = [];
    final List<AttendanceRecord> localRecords = [];

    // Strictly build records from current section students list only
    for (var s in _students) {
      final status = _tempAttendance[s.id] ?? 'P';
      final reason = (_tempAttendanceReasons[s.id] ?? '').trim();
      final Map<String, String> recordMap = {
        'studentId': s.id,
        'status': status == 'P' ? 'present' : 'absent',
      };
      if (status == 'A' && reason.isNotEmpty) {
        recordMap['reason'] = reason;
      }
      apiRecords.add(recordMap);
      localRecords.add(AttendanceRecord(
        studentId: s.id,
        status: status,
        reason: status == 'A' && reason.isNotEmpty ? reason : null,
      ));
      s.absentToday = (status == 'A');
    }

    final String? error = await TeacherDataService.submitAttendance(
      sectionId: sectionId,
      date: dateStr,
      records: apiRecords,
    );

    if (error == null) {
      _isAttendanceSubmittedToday = true;
      final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      _attendanceHistory.removeWhere((h) => h.date == dateStr);
      _attendanceHistory.insert(
        0,
        DailyAttendance(
          date: dateStr,
          classTarget: _teacher?.assignedClass ?? 'Grade 10 A',
          records: localRecords,
          submittedBy: teacherId,
          submittedAt: "$dateStr $timeStr",
        ),
      );
      _isSubmittingAttendance = false;
      notifyListeners();
      return true;
    } else {
      _lastAttendanceError = error;
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }
  }

  // Parent chats operations
  void addParentMessage(String parentId, String text, String sender) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      
      final newMessage = ParentMessage(
        id: "M${now.millisecondsSinceEpoch}",
        text: text,
        sender: sender,
        timestamp: timeStr,
      );

      _parentConversations[idx].messages.add(newMessage);
      _parentConversations[idx].lastMessage = text;
      _parentConversations[idx].timeLabel = 'Just now';
      if (sender == 'parent') {
        _parentConversations[idx].unread = true;
      }
      notifyListeners();
    }
  }

  void markChatAsRead(String parentId) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId);
    if (idx != -1 && _parentConversations[idx].unread) {
      _parentConversations[idx].unread = false;
      notifyListeners();
    }
  }

  void startNewConversation(ParentConversation newConv) {
    _parentConversations.insert(0, newConv);
    notifyListeners();
  }

  void addParentMessageObject(String parentId, ParentMessage message) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId);
    if (idx != -1) {
      _parentConversations[idx].messages.add(message);
      _parentConversations[idx].lastMessage = message.text;
      notifyListeners();
    }
  }

  void markMessageAsSent(String parentId, String messageId) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId);
    if (idx != -1) {
      final msgIdx = _parentConversations[idx].messages.indexWhere((m) => m.id == messageId);
      if (msgIdx != -1) {
        _parentConversations[idx].messages[msgIdx].failed = false;
        _parentConversations[idx].lastMessage = _parentConversations[idx].messages[msgIdx].text;
        notifyListeners();
      }
    }
  }

  // Check if today is a registered holiday or weekend
  Holiday? getTodayHoliday() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final curMonth = months[now.month - 1];
    final curDay = now.day.toString().padLeft(2, '0');
    final curDayInt = now.day.toString();

    for (var h in _holidays) {
      if (h.fullDate != null && h.fullDate == todayStr) {
        return h;
      }
      if (h.month.toLowerCase() == curMonth.toLowerCase() &&
          (h.date == curDay || h.date == curDayInt)) {
        return h;
      }
    }
    return null;
  }

  bool get isTodaySunday => DateTime.now().weekday == DateTime.sunday;
  bool get isTodayHoliday => getTodayHoliday() != null || isTodaySunday;
}
