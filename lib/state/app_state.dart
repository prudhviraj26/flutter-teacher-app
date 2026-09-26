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

  bool _isLoadingStudents = false;
  bool _isAttendanceSubmittedToday = false;
  bool _isSubmittingAttendance = false;

  // Getters
  String get language => _language;
  bool get loggedIn => _loggedIn;
  Teacher? get teacher => _teacher;
  String? get profilePic => _profilePic;
  String get currentSchoolName => _teacher?.schoolName ?? schoolConfig.name;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isAttendanceSubmittedToday => _isAttendanceSubmittedToday;
  bool get isSubmittingAttendance => _isSubmittingAttendance;

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

  // Constructor
  AppState() {
    _initPreferences();
    _initMockData();
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
    
    // Load profile pic
    if (_teacher != null) {
      _profilePic = _prefs?.getString('teacher_avatar_${_teacher!.employeeId}');
    }
    
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
          final String apiAssignedClass = userMap['assignedClass'] as String? ?? 'Class Teacher';
          final String? apiSectionId = userMap['sectionId'] as String?;
          final String apiEmployeeId = userMap['employeeId'] as String? ?? userMap['employeeCode'] as String? ?? 'EMP-2026-001';

          _teacher = Teacher(
            id: userMap['id'] ?? 'T001',
            name: fullName.isNotEmpty ? fullName : 'Teacher',
            employeeId: apiEmployeeId,
            mobile: userMap['mobile'] ?? (_teacher?.mobile ?? ''),
            email: userMap['email'] ?? '',
            designation: role == 'class_teacher' ? 'Class Teacher' : 'Subject Teacher',
            assignedClass: apiAssignedClass,
            sectionId: apiSectionId,
            subjects: userMap['subjects'] != null ? List<String>.from(userMap['subjects']) : ['General'],
            joiningDate: userMap['joiningDate'] ?? '01-06-2022',
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

      final liveAnnouncements = await TeacherDataService.fetchBroadcasts();
      _announcements = liveAnnouncements;

      // Clear mock lists from demo school for authenticated API session
      _parentConversations = [];
      _classUpdates = [];

      initTempAttendance();
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
        final String apiAssignedClass = userMap['assignedClass'] as String? ?? 'Class Teacher';
        final String? apiSectionId = userMap['sectionId'] as String?;
        final String apiEmployeeId = userMap['employeeId'] as String? ?? userMap['employeeCode'] as String? ?? 'EMP-2026-001';

        final loadedTeacher = Teacher(
          id: userMap['id'] ?? 'T001',
          name: fullName.isNotEmpty ? fullName : 'Teacher',
          employeeId: apiEmployeeId,
          mobile: userMap['mobile'] ?? mobile,
          email: userMap['email'] ?? '',
          designation: role == 'class_teacher' ? 'Class Teacher' : 'Subject Teacher',
          assignedClass: apiAssignedClass,
          sectionId: apiSectionId,
          subjects: userMap['subjects'] != null ? List<String>.from(userMap['subjects']) : ['General'],
          joiningDate: userMap['joiningDate'] ?? '01-06-2022',
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

  // Add Announcement
  void addAnnouncement(Announcement ann) {
    _announcements.insert(0, ann);
    notifyListeners();
  }

  // Delete Announcement
  void deleteAnnouncement(String id) {
    _announcements.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  // Add Class Update
  void addClassUpdate(ClassUpdate update) {
    _classUpdates.insert(0, update);
    notifyListeners();
  }

  // Delete Class Update
  void deleteClassUpdate(String id) {
    _classUpdates.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  // Active Attendance operations
  void initTempAttendance() {
    final validIds = _students.map((s) => s.id).toSet();
    _tempAttendance.removeWhere((key, value) => !validIds.contains(key));
    for (var s in _students) {
      if (!_tempAttendance.containsKey(s.id)) {
        _tempAttendance[s.id] = 'P';
      }
    }
  }

  void updateTempAttendance(String studentId, String status) {
    _tempAttendance[studentId] = status;
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
          final List<AttendanceRecord> records = [];

          for (var item in sessionStudents) {
            if (item is Map<String, dynamic>) {
              final studentId = item['studentId'] as String?;
              final currentRecord = item['currentRecord'] as Map<String, dynamic>?;
              final statusStr = currentRecord?['status'] as String?;

              if (studentId != null) {
                final isAbsent = statusStr == 'absent';
                final status = isAbsent ? 'A' : 'P';
                fetchedTemp[studentId] = status;

                final idx = _students.indexWhere((s) => s.id == studentId);
                if (idx != -1) {
                  _students[idx].absentToday = isAbsent;
                }
                records.add(AttendanceRecord(studentId: studentId, status: status));
              }
            }
          }

          if (fetchedTemp.isNotEmpty) {
            _tempAttendance = fetchedTemp;
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

  Future<bool> submitAttendance(String teacherId) async {
    _isSubmittingAttendance = true;
    notifyListeners();

    final String? sectionId = _teacher?.sectionId;
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, String>> apiRecords = [];
    final List<AttendanceRecord> localRecords = [];

    // Strictly build records from current section students list only
    for (var s in _students) {
      final status = _tempAttendance[s.id] ?? 'P';
      apiRecords.add({
        'studentId': s.id,
        'status': status == 'P' ? 'present' : 'absent',
      });
      localRecords.add(AttendanceRecord(studentId: s.id, status: status));
      s.absentToday = (status == 'A');
    }

    bool success = true;
    if (sectionId != null && sectionId.isNotEmpty) {
      success = await TeacherDataService.submitAttendance(
        sectionId: sectionId,
        date: dateStr,
        records: apiRecords,
      );
    }

    if (success) {
      _isAttendanceSubmittedToday = true;
      final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      _attendanceHistory.removeWhere((h) => h.date == dateStr);
      _attendanceHistory.insert(
        0,
        DailyAttendance(
          date: dateStr,
          classTarget: _teacher?.assignedClass ?? 'Nursery A',
          records: localRecords,
          submittedBy: teacherId,
          submittedAt: "$dateStr $timeStr",
        ),
      );
    }

    _isSubmittingAttendance = false;
    notifyListeners();
    return success;
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

  // Load static lists matching mockData.ts
  void _initMockData() {
    // 1. Students list (Grade 3-B)
    _students = [
      Student(id: 'S001', name: 'Aarav Sharma', rollNo: '1', enrollmentNo: 'VIS2021001', studentClass: 'Grade 3-B', dateOfBirth: '15-08-2017', gender: 'Male', parentName: 'Rajesh Sharma', parentMobile: '+91 98765 43210', address: 'Flat 302, Sunrise Apartments, Bandra West, Mumbai - 400050', bloodGroup: 'O+', emergencyContact: '+91 98765 99999', absentToday: false, feeDefaulter: false, attendancePercentage: 96),
      Student(id: 'S002', name: 'Aisha Khan', rollNo: '2', enrollmentNo: 'VIS2021002', studentClass: 'Grade 3-B', dateOfBirth: '22-03-2017', gender: 'Female', parentName: 'Imran Khan', parentMobile: '+91 98765 43211', address: 'B-104, Green Valley, Andheri East, Mumbai - 400069', bloodGroup: 'A+', emergencyContact: '+91 98765 99998', absentToday: false, feeDefaulter: true, attendancePercentage: 92),
      Student(id: 'S003', name: 'Aryan Patil', rollNo: '3', enrollmentNo: 'VIS2021003', studentClass: 'Grade 3-B', dateOfBirth: '10-11-2017', gender: 'Male', parentName: 'Suresh Patil', parentMobile: '+91 98765 43212', address: '15/A, Sai Krupa, Dadar West, Mumbai - 400028', bloodGroup: 'B+', emergencyContact: '+91 98765 99997', absentToday: true, feeDefaulter: false, attendancePercentage: 95),
      Student(id: 'S004', name: 'Diya Deshmukh', rollNo: '4', enrollmentNo: 'VIS2021004', studentClass: 'Grade 3-B', dateOfBirth: '05-07-2017', gender: 'Female', parentName: 'Pradeep Deshmukh', parentMobile: '+91 98765 43213', address: 'Plot 42, Shivaji Nagar, Pune - 411016', bloodGroup: 'AB+', emergencyContact: '+91 98765 99996', absentToday: false, feeDefaulter: false, attendancePercentage: 98),
      Student(id: 'S005', name: 'Ishaan Joshi', rollNo: '5', enrollmentNo: 'VIS2021005', studentClass: 'Grade 3-B', dateOfBirth: '18-01-2018', gender: 'Male', parentName: 'Amit Joshi', parentMobile: '+91 98765 43214', address: '7th Floor, Tower B, Orchid Heights, Powai, Mumbai - 400076', bloodGroup: 'O+', emergencyContact: '+91 98765 99995', absentToday: false, feeDefaulter: false, attendancePercentage: 72),
      Student(id: 'S006', name: 'Kavya Menon', rollNo: '6', enrollmentNo: 'VIS2021006', studentClass: 'Grade 3-B', dateOfBirth: '29-09-2017', gender: 'Female', parentName: 'Vinod Menon', parentMobile: '+91 98765 43215', address: 'C-201, Marina Heights, Juhu, Mumbai - 400049', bloodGroup: 'A+', emergencyContact: '+91 98765 99994', absentToday: false, feeDefaulter: false, attendancePercentage: 94),
      Student(id: 'S007', name: 'Lakshmi Nair', rollNo: '7', enrollmentNo: 'VIS2021007', studentClass: 'Grade 3-B', dateOfBirth: '12-04-2017', gender: 'Female', parentName: 'Ramesh Nair', parentMobile: '+91 98765 43216', address: 'House No. 88, Sector 7, Vashi, Navi Mumbai - 400703', bloodGroup: 'B+', emergencyContact: '+91 98765 99993', absentToday: true, feeDefaulter: false, attendancePercentage: 91),
      Student(id: 'S008', name: 'Rohan Kapoor', rollNo: '8', enrollmentNo: 'VIS2021008', studentClass: 'Grade 3-B', dateOfBirth: '03-06-2017', gender: 'Male', parentName: 'Sanjay Kapoor', parentMobile: '+91 98765 43217', address: '12-B, Shanti Niwas, Colaba, Mumbai - 400005', bloodGroup: 'O-', emergencyContact: '+91 98765 99992', absentToday: false, feeDefaulter: true, attendancePercentage: 93),
      Student(id: 'S009', name: 'Saanvi Reddy', rollNo: '9', enrollmentNo: 'VIS2021009', studentClass: 'Grade 3-B', dateOfBirth: '25-12-2017', gender: 'Female', parentName: 'Krishna Reddy', parentMobile: '+91 98765 43218', address: 'Flat 501, Lakeview Apartments, Banjara Hills, Hyderabad - 500034', bloodGroup: 'A-', emergencyContact: '+91 98765 99991', absentToday: false, feeDefaulter: false, attendancePercentage: 68),
      Student(id: 'S010', name: 'Vihaan Singh', rollNo: '10', enrollmentNo: 'VIS2021010', studentClass: 'Grade 3-B', dateOfBirth: '14-02-2018', gender: 'Male', parentName: 'Vikram Singh', parentMobile: '+91 98765 43219', address: 'Villa 23, Palm Grove Society, Thane West, Mumbai - 400601', bloodGroup: 'AB-', emergencyContact: '+91 98765 99990', absentToday: false, feeDefaulter: false, attendancePercentage: 97),
    ];

    // 2. Announcements list
    _announcements = [
      Announcement(id: 'A001', title: 'Parent-Teacher Meeting', message: 'Dear Parents, We are organizing a Parent-Teacher Meeting on May 15, 2026 at 10:00 AM for Grade 3-B. Please make sure to attend and discuss your child\'s progress.', author: 'Mrs. Priya Patel', authorId: 'T001', classScope: 'Grade 3-B', date: '2026-05-10', time: '09:00 AM', scope: 'Class'),
      Announcement(id: 'A002', title: 'Mathematics Quiz Next Week', message: 'Students should prepare for the Mathematics quiz on multiplication tables (2-10). The quiz will be held on May 18, 2026.', author: 'Mrs. Priya Patel', authorId: 'T001', classScope: 'Grade 3-B', date: '2026-05-08', time: '02:30 PM', scope: 'Class'),
      Announcement(id: 'A003', title: 'Annual Sports Day', message: 'Annual Sports Day will be held on May 20, 2026. All students are required to participate. Parents are cordially invited to attend.', author: 'Principal Office', authorId: 'ADMIN', date: '2026-05-05', time: '10:00 AM', scope: 'School'),
    ];

    // 3. Class Updates
    _classUpdates = [
      ClassUpdate(id: 'CU001', type: 'Homework', title: 'Multiplication Tables Practice', description: 'Complete exercises 1-10 from Chapter 5: Multiplication Tables. Show all working steps. Due on May 12, 2026.', subject: 'Mathematics', classTarget: 'Grade 3-B', teacherId: 'T001', teacherName: 'Mrs. Priya Patel', dueDate: '2026-05-12', attachments: ['worksheet_multiplication.pdf'], date: '2026-05-08'),
      ClassUpdate(id: 'CU002', type: 'Classwork', title: 'Parts of a Plant', description: 'Today we learned about different parts of a plant - roots, stem, leaves, flowers, and fruits. Students participated in a hands-on activity to identify plant parts.', subject: 'Science', classTarget: 'Grade 3-B', teacherId: 'T001', teacherName: 'Mrs. Priya Patel', date: '2026-05-07'),
      ClassUpdate(id: 'CU003', type: 'Homework', title: 'Essay Writing - My Family', description: 'Write a short essay (100 words) about your family. Include information about family members and what you like to do together.', subject: 'English', classTarget: 'Grade 3-B', teacherId: 'T002', teacherName: 'Mr. Arjun Desai', dueDate: '2026-05-10', date: '2026-05-06'),
    ];

    // 4. Attendance History
    _attendanceHistory = [
      DailyAttendance(
        date: '2026-05-16',
        classTarget: 'Grade 3-B',
        records: [
          AttendanceRecord(studentId: 'S001', status: 'P'),
          AttendanceRecord(studentId: 'S002', status: 'P'),
          AttendanceRecord(studentId: 'S003', status: 'A'),
          AttendanceRecord(studentId: 'S004', status: 'P'),
          AttendanceRecord(studentId: 'S005', status: 'P'),
          AttendanceRecord(studentId: 'S006', status: 'P'),
          AttendanceRecord(studentId: 'S007', status: 'P'),
          AttendanceRecord(studentId: 'S008', status: 'P'),
          AttendanceRecord(studentId: 'S009', status: 'P'),
          AttendanceRecord(studentId: 'S010', status: 'A'),
        ],
        submittedBy: 'T001',
        submittedAt: '2026-05-16 09:30 AM',
      ),
      DailyAttendance(
        date: '2026-05-15',
        classTarget: 'Grade 3-B',
        records: [
          AttendanceRecord(studentId: 'S001', status: 'P'),
          AttendanceRecord(studentId: 'S002', status: 'P'),
          AttendanceRecord(studentId: 'S003', status: 'P'),
          AttendanceRecord(studentId: 'S004', status: 'P'),
          AttendanceRecord(studentId: 'S005', status: 'A'),
          AttendanceRecord(studentId: 'S006', status: 'P'),
          AttendanceRecord(studentId: 'S007', status: 'P'),
          AttendanceRecord(studentId: 'S008', status: 'P'),
          AttendanceRecord(studentId: 'S009', status: 'P'),
          AttendanceRecord(studentId: 'S010', status: 'P'),
        ],
        submittedBy: 'T001',
        submittedAt: '2026-05-15 09:25 AM',
      ),
    ];

    // 5. Parent Conversations
    _parentConversations = [
      ParentConversation(
        parentId: 'P004',
        parentName: 'Mrs. Patil',
        studentName: 'Riya Patil',
        studentClass: 'Class 8A',
        mobile: '+91 98765 44001',
        lastMessage: 'Received, thank you!',
        timeLabel: '10 mins',
        unread: true,
        messages: [
          ParentMessage(id: 'M101', text: 'Good morning, can Riya get extra notes for the Maths chapter? She was unwell last week.', sender: 'parent', timestamp: '9:02 AM'),
          ParentMessage(id: 'M102', text: 'Good morning Mrs. Patil. Of course, I\'ll share the notes today.', sender: 'teacher', timestamp: '9:15 AM'),
          ParentMessage(id: 'M103', text: 'Thank you so much. Really appreciate it.', sender: 'parent', timestamp: '9:17 AM'),
          ParentMessage(id: 'M104', text: 'Notes attached below.', sender: 'teacher', timestamp: '9:45 AM'),
          ParentMessage(id: 'M105', text: 'Chapter4_notes.pdf', sender: 'teacher', timestamp: '9:45 AM', isAttachment: true, attachmentName: 'Chapter4_notes.pdf'),
          ParentMessage(id: 'M106', text: 'Received, thank you!', sender: 'parent', timestamp: '9:48 AM'),
          ParentMessage(id: 'M107', text: 'Please let me know if she needs help with Science as well.', sender: 'teacher', timestamp: '9:50 AM', failed: true),
        ],
      ),
      ParentConversation(parentId: 'P005', parentName: 'Mr. Kulkarni', studentName: 'Arjun Kulkarni', studentClass: 'Grade 3-B', mobile: '+91 98765 44002', lastMessage: 'Thank you for the update on his progress', timeLabel: 'Yesterday', unread: true, messages: [
        ParentMessage(id: 'M108', text: 'Thank you for the update on his progress', sender: 'parent', timestamp: 'Yesterday')
      ]),
      ParentConversation(parentId: 'P006', parentName: 'Mrs. Mehta', studentName: 'Sneha Mehta', studentClass: 'Grade 3-B', mobile: '+91 98765 44003', lastMessage: 'She will be absent tomorrow due to...', timeLabel: '2 days ago', unread: false, messages: [
        ParentMessage(id: 'M109', text: 'She will be absent tomorrow due to...', sender: 'parent', timestamp: '2 days ago')
      ]),
      ParentConversation(parentId: 'P007', parentName: 'Mr. Desai', studentName: 'Aarav Desai', studentClass: 'Grade 3-B', mobile: '+91 98765 44004', lastMessage: 'Please share the syllabus for term 2', timeLabel: '3 days ago', unread: false, messages: [
        ParentMessage(id: 'M110', text: 'Please share the syllabus for term 2', sender: 'parent', timestamp: '3 days ago')
      ]),
      ParentConversation(
        parentId: 'P001',
        parentName: 'Rajesh Sharma',
        studentName: 'Aarav Sharma',
        studentClass: 'Grade 3-B',
        mobile: '+91 98765 43210',
        lastMessage: 'Thank you for the update!',
        timeLabel: '4 days ago',
        unread: false,
        messages: [
          ParentMessage(id: 'M001', text: 'Good morning! Aarav has shown great improvement in Mathematics this month.', sender: 'teacher', timestamp: '10:30 AM'),
          ParentMessage(id: 'M002', text: 'That\'s wonderful to hear! Thank you for your guidance.', sender: 'parent', timestamp: '11:00 AM'),
          ParentMessage(id: 'M003', text: 'He scored 95% in the last test. Keep encouraging him to practice regularly.', sender: 'teacher', timestamp: '11:15 AM'),
          ParentMessage(id: 'M004', text: 'Thank you for the update!', sender: 'parent', timestamp: '11:30 AM'),
        ],
      ),
      ParentConversation(
        parentId: 'P002',
        parentName: 'Imran Khan',
        studentName: 'Aisha Khan',
        studentClass: 'Grade 3-B',
        mobile: '+91 98765 43211',
        lastMessage: 'Will make sure she completes it.',
        timeLabel: '5 days ago',
        unread: false,
        messages: [
          ParentMessage(id: 'M005', text: 'Hello, Aisha has not submitted her Science homework from last week.', sender: 'teacher', timestamp: '02:00 PM'),
          ParentMessage(id: 'M006', text: 'I\'m sorry about that. I will make sure she completes it today.', sender: 'parent', timestamp: '02:30 PM'),
          ParentMessage(id: 'M007', text: 'Thank you. Please submit it by tomorrow.', sender: 'teacher', timestamp: '03:00 PM'),
          ParentMessage(id: 'M008', text: 'Will make sure she completes it.', sender: 'parent', timestamp: '03:15 PM'),
        ],
      ),
      ParentConversation(
        parentId: 'P003',
        parentName: 'Suresh Patil',
        studentName: 'Aryan Patil',
        studentClass: 'Grade 3-B',
        mobile: '+91 98765 43212',
        lastMessage: 'Glad to hear that!',
        timeLabel: '6 days ago',
        unread: false,
        messages: [
          ParentMessage(id: 'M009', text: 'Aryan participated excellently in the class discussion today.', sender: 'teacher', timestamp: '04:00 PM'),
          ParentMessage(id: 'M010', text: 'Glad to hear that!', sender: 'parent', timestamp: '04:30 PM'),
        ],
      ),
    ];

    // 6. Duties list
    _duties = [
      Duty(id: 'D001', date: '2026-05-18', type: 'Morning Assembly', time: '7:45 AM - 8:15 AM', location: 'School Playground', notes: 'Supervise student assembly and ensure discipline'),
      Duty(id: 'D002', date: '2026-05-18', type: 'Recess Duty', time: '11:00 AM - 11:30 AM', location: 'Playground & Canteen Area', notes: 'Monitor students during break time'),
      Duty(id: 'D003', date: '2026-05-20', type: 'Sports Day Coordination', time: '8:00 AM - 4:00 PM', location: 'School Sports Ground', notes: 'Coordinate Grade 3 athletics events'),
      Duty(id: 'D004', date: '2026-05-25', type: 'Parent-Teacher Meeting', time: '10:00 AM - 2:00 PM', location: 'Classroom 3-B', notes: 'Meet parents and discuss student progress'),
    ];

    // 7. Staff Notices
    _staffNotices = [
      StaffNotice(id: 'SN001', title: 'General Staff Meeting Scheduled', message: 'Dear Teachers, There will be a mandatory General Staff Meeting in the main auditorium tomorrow at 3:00 PM. We will review curriculum timelines and coordinate the upcoming final exams. Please bring your class syllabus logs.', author: 'Principal Office', date: '2026-05-23', time: '10:30 AM', category: 'Meeting'),
      StaffNotice(id: 'SN002', title: 'Revision of Summer Vacation Schedule', message: 'Dear Staff Members, Please note that the Summer Vacation schedule for teachers has been updated due to calendar alignment. The new holiday period begins on June 1, 2026 and reopens on June 30, 2026.', author: 'School Management', date: '2026-05-21', time: '04:15 PM', category: 'Urgent'),
      StaffNotice(id: 'SN003', title: 'Guidelines for Invigilator Duty', message: 'All invigilators are requested to collect exam packets at least 20 minutes before schedule. No mobile phones are allowed inside the exam halls. Report any discrepancies directly to the exam control room.', author: 'Exam Coordinator', date: '2026-05-18', time: '09:00 AM', category: 'Duty'),
    ];

    // 8. Notices
    _notices = [
      Notice(
        id: '1',
        source: 'Principal Office',
        title: 'Parent-Teacher Meeting',
        date: '2026-05-15',
        time: '10:00 AM',
        body: 'Dear Parents, We are organizing a Parent-Teacher Meeting on May 15, 2026 at 10:00 AM. Please make sure to attend and discuss your child\'s progress with their teachers.',
        cta: NoticeCta(label: 'View Event', action: 'event'),
      ),
      Notice(
        id: '2',
        source: 'Accounts Department',
        title: 'Fee Payment Reminder',
        date: '2026-05-10',
        time: '09:00 AM',
        body: 'This is a reminder to pay the pending school fees before the due date. Late payment will attract a fine of ₹100 per day.',
        cta: NoticeCta(label: 'View Fees', action: 'fees'),
      ),
      Notice(
        id: '3',
        source: 'Sports Department',
        title: 'Annual Sports Day',
        date: '2026-05-20',
        time: '08:00 AM',
        body: 'Annual Sports Day will be held on May 20, 2026. All students are required to participate. Parents are cordially invited to attend.',
      ),
      Notice(
        id: '4',
        source: 'Administration',
        title: 'Summer Vacation Notice',
        date: '2026-05-25',
        time: '12:00 PM',
        body: 'School will be closed for summer vacation from June 1 to June 30, 2026. School will reopen on July 1, 2026.',
      ),
    ];

    // 9. Events
    _events = [
      Event(id: '1', title: 'Parent-Teacher Meeting', date: '2026-05-15', time: '10:00 AM - 2:00 PM', location: 'School Auditorium', description: 'Quarterly Parent-Teacher Meeting to discuss student progress and academic performance.'),
      Event(id: '2', title: 'Annual Sports Day', date: '2026-05-20', time: '8:00 AM - 4:00 PM', location: 'School Sports Ground', description: 'Annual Sports Day with various athletic events and competitions. All students to participate.'),
    ];

    // 10. Albums
    _albums = [
      Album(
        id: '1',
        title: 'Annual Day 2026',
        coverPhoto: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=500',
        photoCount: 24,
        photos: List.generate(24, (i) => Photo(id: '${i + 1}', url: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=500')),
      ),
      Album(
        id: '2',
        title: 'Sports Day 2025',
        coverPhoto: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
        photoCount: 18,
        photos: List.generate(18, (i) => Photo(id: '${i + 1}', url: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500')),
      ),
      Album(
        id: '3',
        title: 'Independence Day Celebration',
        coverPhoto: 'https://images.unsplash.com/photo-1532375810709-75b1da00537c?w=500',
        photoCount: 15,
        photos: List.generate(15, (i) => Photo(id: '${i + 1}', url: 'https://images.unsplash.com/photo-1532375810709-75b1da00537c?w=500')),
      ),
    ];

    // 11. Holidays
    _holidays = [
      Holiday(id: '1', date: '26', month: 'Jan', day: 'Monday', title: 'Republic Day', type: 'National'),
      Holiday(id: '2', date: '14', month: 'Mar', day: 'Friday', title: 'Holi', type: 'Festival'),
      Holiday(id: '3', date: '29', month: 'Mar', day: 'Saturday', title: 'Good Friday', type: 'National'),
      Holiday(id: '4', date: '14', month: 'Apr', day: 'Monday', title: 'Dr. Ambedkar Jayanti', type: 'National'),
      Holiday(id: '5', date: '01', month: 'May', day: 'Thursday', title: 'Maharashtra Day', type: 'National'),
      Holiday(id: '6', date: '23', month: 'May', day: 'Friday', title: 'Buddha Purnima', type: 'Festival'),
      Holiday(id: '7', date: '15', month: 'Aug', day: 'Friday', title: 'Independence Day', type: 'National'),
      Holiday(id: '8', date: '16', month: 'Aug', day: 'Saturday', title: 'Janmashtami', type: 'Festival'),
      Holiday(id: '9', date: '02', month: 'Oct', day: 'Thursday', title: 'Gandhi Jayanti', type: 'National'),
      Holiday(id: '10', date: '24', month: 'Oct', day: 'Friday', title: 'Dussehra', type: 'Festival'),
      Holiday(id: '11', date: '13', month: 'Nov', day: 'Thursday', title: 'Diwali', type: 'Festival'),
      Holiday(id: '12', date: '25', month: 'Dec', day: 'Thursday', title: 'Christmas', type: 'National'),
    ];

    // 12. Exam results
    _examResults = [];
  }
}
