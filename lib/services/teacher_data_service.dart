import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/models.dart';

class TeacherDataService {
  // Fetch Students for current school / section
  static Future<List<Student>> fetchStudents({String? sectionId}) async {
    try {
      final String queryParam = (sectionId != null && sectionId.isNotEmpty) ? '?sectionId=$sectionId' : '';
      final response = await ApiService.get('/students$queryParam');

      List? list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        if (response['items'] is List) {
          list = response['items'];
        } else if (response['data'] is List) {
          list = response['data'];
        }
      }

      if (list != null) {
        final List<Student> students = [];
        for (var item in list) {
          try {
            if (item is Map<String, dynamic>) {
              students.add(_mapApiStudentToModel(item));
            }
          } catch (itemErr) {
            debugPrint('Error mapping student item: $itemErr');
          }
        }
        return students;
      }
      return [];
    } catch (e) {
      debugPrint('TeacherDataService.fetchStudents error: $e');
      return [];
    }
  }

  // Fetch Attendance Session for section and date
  static Future<Map<String, dynamic>?> fetchAttendanceSession(String sectionId, String date) async {
    try {
      final response = await ApiService.get('/attendance/sessions/$sectionId/$date');
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchAttendanceSession error: $e');
    }
    return null;
  }

  // Submit/Upsert Attendance Session
  static Future<String?> submitAttendance({
    required String sectionId,
    required String date,
    required List<Map<String, String>> records,
  }) async {
    try {
      await ApiService.post('/attendance/sessions', {
        'sectionId': sectionId,
        'date': date,
        'records': records,
      });
      return null; // null represents success
    } catch (e) {
      debugPrint('TeacherDataService.submitAttendance error: $e');
      final errStr = e.toString().replaceAll('Exception: ', '').trim();
      return errStr.isNotEmpty ? errStr : 'Failed to submit attendance. Please try again.';
    }
  }

  // Fetch School Broadcasts / Announcements
  static Future<List<Announcement>> fetchBroadcasts() async {
    try {
      final response = await ApiService.get('/communication/broadcasts');
      List? list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        if (response['items'] is List) {
          list = response['items'];
        } else if (response['data'] is List) {
          list = response['data'];
        }
      }

      if (list != null) {
        return list.map((item) => _mapApiBroadcastToAnnouncement(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchBroadcasts error: $e');
    }
    return [];
  }

  // Post Broadcast / Class Announcement / Homework from Teacher App
  static Future<bool> createBroadcast({
    required String title,
    required String message,
    required String targetType, // 'class' | 'section' | 'school' | 'staff_only'
    String? targetClassId,
    List<String>? targetClassIds,
    String? targetSectionId,
    List<String>? attachments,
    String? scheduledFor,
  }) async {
    try {
      final payload = {
        'title': title,
        'body': message,
        'targetType': targetType,
        'channels': ['in_app', 'push_fcm'],
        if (targetClassId != null) 'targetClassId': targetClassId,
        if (targetClassIds != null) 'targetClassIds': targetClassIds,
        if (targetSectionId != null) 'targetSectionId': targetSectionId,
        if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
        if (scheduledFor != null) 'scheduledFor': scheduledFor,
      };
      final res = await ApiService.post('/communication/broadcasts', payload);
      return res != null;
    } catch (e) {
      debugPrint('TeacherDataService.createBroadcast error: $e');
      return false;
    }
  }

  // Mark Broadcast as Read on Backend
  static Future<bool> markBroadcastRead(String broadcastId) async {
    try {
      final res = await ApiService.post('/communication/broadcasts/$broadcastId/read', {});
      return res != null;
    } catch (e) {
      debugPrint('TeacherDataService.markBroadcastRead error: $e');
      return false;
    }
  }

  // Register Device Push Token
  static Future<bool> registerDeviceToken({
    required String deviceToken,
    String platform = 'android',
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) async {
    try {
      final res = await ApiService.post('/communication/device-token', {
        'deviceToken': deviceToken,
        'platform': platform,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (osVersion != null) 'osVersion': osVersion,
        if (appVersion != null) 'appVersion': appVersion,
      });
      return res != null;
    } catch (e) {
      debugPrint('TeacherDataService.registerDeviceToken error: $e');
      return false;
    }
  }

  // Remove Device Push Token
  static Future<bool> removeDeviceToken(String deviceToken) async {
    try {
      final res = await ApiService.post('/communication/device-token/remove', {
        'deviceToken': deviceToken,
      });
      return res != null;
    } catch (e) {
      debugPrint('TeacherDataService.removeDeviceToken error: $e');
      return false;
    }
  }

  // Fetch Staff Subject Assignments
  static Future<List<String>> fetchSubjectAssignments(String staffId) async {
    try {
      final response = await ApiService.get('/staff/$staffId/subject-assignments');
      List? list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        if (response['items'] is List) {
          list = response['items'];
        } else if (response['data'] is List) {
          list = response['data'];
        }
      }

      if (list != null) {
        final List<String> subjects = [];
        for (var item in list) {
          if (item is Map<String, dynamic> && item['subject'] != null) {
            final subj = item['subject'].toString().trim();
            if (subj.isNotEmpty && !subjects.contains(subj)) {
              subjects.add(subj);
            }
          }
        }
        return subjects;
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchSubjectAssignments error: $e');
    }
    return [];
  }

  // Fetch Teacher's Own Monthly Attendance & Calendar
  static Future<TeacherMonthlyAttendance?> fetchMyMonthlyAttendance(String month) async {
    try {
      final response = await ApiService.get('/staff-attendance/my-attendance?month=$month');
      if (response is Map<String, dynamic>) {
        return TeacherMonthlyAttendance.fromJson(response);
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchMyMonthlyAttendance error: $e');
    }
    return null;
  }

  // Fetch School Holidays from Admin Portal
  static Future<List<Holiday>> fetchSchoolHolidays({String? academicYearId}) async {
    try {
      final String queryParam = (academicYearId != null && academicYearId.isNotEmpty) ? '?academicYearId=$academicYearId' : '';
      final response = await ApiService.get('/school-holidays$queryParam');
      List? list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        if (response['items'] is List) {
          list = response['items'];
        } else if (response['data'] is List) {
          list = response['data'];
        }
      }

      if (list != null) {
        final List<Holiday> holidays = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            holidays.add(Holiday.fromJson(item));
          }
        }
        return holidays;
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchSchoolHolidays error: $e');
    }
    return [];
  }

  // Mapper helper: API Student JSON -> App Student model
  static Student _mapApiStudentToModel(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? 'S-UNK';
    final String rawName = json['fullName'] ??
        json['name'] ??
        "${json['firstName'] ?? ''} ${json['lastName'] ?? ''}";
    final String fullName = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();

    final String rollNo = json['rollNumber']?.toString() ??
        json['rollNo']?.toString() ??
        json['currentEnrollment']?['rollNumber']?.toString() ??
        '';
    final String enrollmentNo = json['grNumber'] ?? json['enrollmentNo'] ?? 'GR-${id.substring(0, id.length > 4 ? 4 : id.length)}';
    
    final currentEnrollment = json['currentEnrollment'];
    final sectionData = json['section'] ?? currentEnrollment?['section'] ?? currentEnrollment;
    
    String studentClass = '';
    if (sectionData != null) {
      final className = sectionData['className'] ?? sectionData['class']?['name'] ?? sectionData['classLevel'] ?? '';
      final sectionName = sectionData['sectionName'] ?? sectionData['name'] ?? '';
      if (className.isNotEmpty || sectionName.isNotEmpty) {
        studentClass = "$className $sectionName".trim();
      }
    }
    if (studentClass.isEmpty && json['studentClass'] != null) {
      studentClass = json['studentClass'].toString();
    }
    if (studentClass.isEmpty) {
      studentClass = 'Grade 10 A';
    }

    final primaryParent = json['primaryParent'] ??
        (json['parentContacts'] != null && (json['parentContacts'] as List).isNotEmpty
            ? json['parentContacts'][0]
            : null);

    final String parentName = primaryParent != null 
        ? (primaryParent['name'] ?? "${primaryParent['firstName'] ?? ''} ${primaryParent['lastName'] ?? ''}".trim())
        : (json['parentName'] ?? 'Parent');
    final String parentMobile = primaryParent?['mobilePrimary'] ?? primaryParent?['mobile'] ?? json['parentMobile'] ?? '';
    final String parentEmail = primaryParent?['email'] ?? json['parentEmail'] ?? '';

    final double attnPct = (json['attendancePercentage'] != null)
        ? (double.tryParse(json['attendancePercentage'].toString()) ?? 0.0)
        : (json['attendancePercent'] != null
            ? (double.tryParse(json['attendancePercent'].toString()) ?? 0.0)
            : 0.0);

    final bool feeDefaulter = json['feeDefaulter'] == true || json['feeDue'] == true || json['hasDue'] == true;
    final bool absentToday = json['absentToday'] == true;

    return Student(
      id: id,
      name: fullName.isNotEmpty ? fullName : 'Student',
      rollNo: rollNo,
      enrollmentNo: enrollmentNo,
      studentClass: studentClass,
      dateOfBirth: json['dob'] ?? (json['dateOfBirth']?.toString().split('T')[0] ?? ''),
      gender: (json['gender'] as String?)?.toUpperCase() ?? 'MALE',
      parentName: parentName,
      parentMobile: parentMobile,
      parentEmail: parentEmail,
      address: json['addressLine1'] ?? json['address'] ?? '',
      bloodGroup: json['bloodGroup'] ?? 'B+',
      emergencyContact: parentMobile.isNotEmpty ? parentMobile : (json['emergencyContact'] ?? ''),
      absentToday: absentToday,
      feeDefaulter: feeDefaulter,
      attendancePercentage: attnPct,
    );
  }

  // Fetch true attendance percentage per student for academic year from attendance-reporting
  static Future<Map<String, double>> fetchStudentAttendancePercentages({
    String? academicYearId,
    String? classId,
    String? sectionId,
  }) async {
    try {
      final now = DateTime.now();
      final dateTo = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final dateFrom = "${now.year - 1}-06-01"; // Academic year start window
      final query = '?dateFrom=$dateFrom&dateTo=$dateTo${academicYearId != null ? '&academicYearId=$academicYearId' : ''}${classId != null ? '&classId=$classId' : ''}${sectionId != null ? '&sectionId=$sectionId' : ''}&pageSize=100';

      final response = await ApiService.get('/attendance-reporting/student-list$query');
      final Map<String, double> map = {};
      List? items;
      if (response is Map && response['items'] is List) {
        items = response['items'];
      } else if (response is List) {
        items = response;
      }
      if (items != null) {
        for (var item in items) {
          if (item is Map) {
            final sId = item['studentId']?.toString() ?? item['id']?.toString();
            final pct = item['attendancePercent'] ?? item['attendancePercentage'];
            if (sId != null && pct != null) {
              map[sId] = double.tryParse(pct.toString()) ?? 0.0;
            }
          }
        }
      }
      return map;
    } catch (e) {
      debugPrint('TeacherDataService.fetchStudentAttendancePercentages error: $e');
      return {};
    }
  }

  // Check and fetch today's attendance session records for section
  static Future<Map<String, String>?> fetchTodayAttendanceRecords(String sectionId) async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final session = await fetchAttendanceSession(sectionId, dateStr);
      if (session != null && session['records'] is List) {
        final Map<String, String> recordMap = {};
        for (var r in session['records']) {
          if (r is Map && r['studentId'] != null) {
            recordMap[r['studentId'].toString()] = (r['status']?.toString().toUpperCase() ?? 'P');
          }
        }
        return recordMap;
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchTodayAttendanceRecords error: $e');
    }
    return null;
  }

  // Mapper helper: API Broadcast JSON -> App Announcement model
  static Announcement _mapApiBroadcastToAnnouncement(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? 'A-UNK';
    final String title = json['title'] ?? 'Announcement';
    final String message = json['body'] ?? json['message'] ?? '';
    final String author = json['senderName'] ?? json['author'] ?? 'School Administration';

    final String targetType = (json['targetType'] ?? json['target_type'] ?? 'school').toString().toLowerCase();
    String scope = 'School';
    if (targetType == 'staff_only' || targetType == 'staff') {
      scope = 'Staff';
    } else if (targetType == 'class' || targetType == 'section' || targetType == 'custom') {
      scope = 'Class';
    }

    String date = '2026-05-10';
    String time = '09:00 AM';
    if (json['createdAt'] != null) {
      try {
        final dt = DateTime.parse(json['createdAt'].toString()).toLocal();
        date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final m = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        time = '$h:$m $ampm';
      } catch (_) {
        date = json['createdAt']?.toString().split('T')[0] ?? '2026-05-10';
      }
    }

    final String? classScope = json['targetClassName'] ??
        json['targetClass'] ??
        json['targetSectionName'] ??
        (targetType == 'class' || targetType == 'section' ? 'Class Notice' : null);

    List<String>? attachments;
    if (json['attachments'] is List) {
      attachments = (json['attachments'] as List).map((a) {
        if (a is Map) return (a['url'] ?? a['fileName'] ?? '').toString();
        return a.toString();
      }).where((s) => s.isNotEmpty).toList();
    } else if (json['mediaUrls'] is List) {
      attachments = (json['mediaUrls'] as List).map((m) => m.toString()).toList();
    }

    return Announcement(
      id: id,
      title: title,
      message: message,
      author: author,
      authorId: json['composedByStaffId'] ?? json['senderId'] ?? 'ADMIN',
      classScope: classScope,
      date: date,
      time: time,
      scope: scope,
      fullDate: json['createdAt']?.toString(),
      attachments: attachments,
    );
  }
}
