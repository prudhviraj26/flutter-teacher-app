import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/models.dart';

class BroadcastSyncResult {
  final List<Announcement> announcements;
  final List<ClassUpdate> classUpdates;

  BroadcastSyncResult({
    required this.announcements,
    required this.classUpdates,
  });
}

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

  // Unified Broadcast & Class Update Fetch (Single network call, dual mapping)
  static Future<BroadcastSyncResult> fetchAllBroadcastsUnified({
    String? since,
    String? dateFrom,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, String>{
        if (since != null && since.isNotEmpty) 'since': since,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (pageSize != null) 'pageSize': pageSize.toString(),
      };
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final path = queryString.isNotEmpty ? '/communication/broadcasts?$queryString' : '/communication/broadcasts';
      final response = await ApiService.get(path);

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
        final announcements = <Announcement>[];
        final classUpdates = <ClassUpdate>[];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              announcements.add(_mapApiBroadcastToAnnouncement(item));
            } catch (aErr) {
              debugPrint('Error mapping announcement item: $aErr');
            }
            try {
              final bType = (item['broadcastType'] ?? item['broadcast_type'] ?? '').toString().toLowerCase();
              if (bType == 'homework' || bType == 'classwork') {
                classUpdates.add(_mapApiBroadcastToClassUpdate(item));
              }
            } catch (cuErr) {
              debugPrint('Error mapping class update item: $cuErr');
            }
          }
        }
        return BroadcastSyncResult(
          announcements: announcements,
          classUpdates: classUpdates,
        );
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchAllBroadcastsUnified error: $e');
    }
    return BroadcastSyncResult(announcements: [], classUpdates: []);
  }

  // Fetch School Broadcasts / Announcements (uses unified pipeline)
  static Future<List<Announcement>> fetchBroadcasts({
    String? since,
    String? dateFrom,
    int? pageSize,
  }) async {
    final result = await fetchAllBroadcastsUnified(
      since: since,
      dateFrom: dateFrom,
      pageSize: pageSize,
    );
    return result.announcements;
  }

  // Upload Attachment via Multipart
  static Future<Map<String, dynamic>?> uploadAttachment(
    File file, {
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    try {
      final res = await ApiService.uploadMultipart(
        '/communication/broadcasts/upload-attachment',
        file: file,
        onProgress: onProgress,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('TeacherDataService.uploadAttachment error: $e');
    }
    return null;
  }

  // Upload Profile Photo via Multipart
  static Future<Map<String, dynamic>?> uploadProfilePhoto(
    String teacherId,
    File file,
  ) async {
    try {
      final res = await ApiService.uploadMultipart(
        '/staff/$teacherId/photo',
        file: file,
        fieldName: 'photo',
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('TeacherDataService.uploadProfilePhoto error: $e');
    }
    return null;
  }

  // Post Broadcast / Class Announcement / Homework from Teacher App
  static Future<Map<String, dynamic>?> createBroadcast({
    required String title,
    required String message,
    required String targetType, // 'class' | 'section' | 'school' | 'staff_only'
    BroadcastType? broadcastType,
    String? targetClassId,
    List<String>? targetClassIds,
    String? targetSectionId,
    List<dynamic>? attachments,
    String? scheduledFor,
  }) async {
    try {
      final payload = {
        'title': title,
        'body': message,
        'targetType': targetType,
        if (broadcastType != null) 'broadcastType': broadcastType.value,
        'channels': ['in_app', 'push_fcm'],
        if (targetClassId != null) 'targetClassId': targetClassId,
        if (targetClassIds != null) 'targetClassIds': targetClassIds,
        if (targetSectionId != null) 'targetSectionId': targetSectionId,
        if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
        if (scheduledFor != null) 'scheduledFor': scheduledFor,
      };
      final res = await ApiService.post('/communication/broadcasts', payload);
      if (res is Map<String, dynamic>) {
        return res;
      } else if (res != null) {
        return {'success': true};
      }
      return null;
    } catch (e) {
      debugPrint('TeacherDataService.createBroadcast error: $e');
      return null;
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
    String? deviceUuid,
    String? deviceModel,
    String? deviceManufacturer,
    String? osVersion,
    String? appVersion,
    String? locale,
    String? timezone,
  }) async {
    try {
      final res = await ApiService.post('/communication/device-token', {
        'deviceToken': deviceToken,
        'platform': platform,
        if (deviceUuid != null) 'deviceUuid': deviceUuid,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (deviceManufacturer != null) 'deviceManufacturer': deviceManufacturer,
        if (osVersion != null) 'osVersion': osVersion,
        if (appVersion != null) 'appVersion': appVersion,
        if (locale != null) 'locale': locale,
        if (timezone != null) 'timezone': timezone,
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

  // Fetch Academic Years
  static Future<List<AcademicYearItem>> fetchAcademicYears() async {
    try {
      final response = await ApiService.get('/academic/years');
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
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => AcademicYearItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchAcademicYears error: $e');
    }
    return [];
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

  // Fetch School Events
  static Future<List<Event>> fetchEvents({String? academicYearId}) async {
    try {
      final String queryParam = (academicYearId != null && academicYearId.isNotEmpty)
          ? '?academicYearId=$academicYearId'
          : '';
      final response = await ApiService.get('/school-events$queryParam');
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
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => Event.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchEvents error: $e');
    }
    return [];
  }

  // Mapper helper: API Student JSON -> App Student model
  static Student _mapApiStudentToModel(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? 'S-UNK';
    final String rawName = json['fullName'] ??
        json['name'] ??
        "${json['firstName'] ?? ''} ${json['middleName'] ?? ''} ${json['lastName'] ?? ''}";
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

    final primaryParent = json['primaryParent'] ??
        (json['parentContacts'] != null && (json['parentContacts'] as List).isNotEmpty
            ? json['parentContacts'][0]
            : null);

    final String rawParentName = primaryParent != null 
        ? (primaryParent['name'] ?? "${primaryParent['firstName'] ?? ''} ${primaryParent['middleName'] ?? ''} ${primaryParent['lastName'] ?? ''}".trim())
        : (json['parentName'] ?? '');
    final String parentName = (rawParentName.trim().toLowerCase() == 'parent' || rawParentName.trim().isEmpty)
        ? ''
        : rawParentName.replaceAll(RegExp(r'\s+'), ' ').trim();
    final String parentMobile = primaryParent?['mobilePrimary'] ?? primaryParent?['mobile'] ?? json['parentMobile'] ?? '';
    final String parentEmail = primaryParent?['email'] ?? json['parentEmail'] ?? '';

    final double attnPct = (json['attendancePercentage'] != null)
        ? (double.tryParse(json['attendancePercentage'].toString()) ?? 100.0)
        : (json['attendancePercent'] != null
            ? (double.tryParse(json['attendancePercent'].toString()) ?? 100.0)
            : 100.0);

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
      address: json['addressLine1'] ?? json['addressLine'] ?? json['address'] ?? '',
      bloodGroup: json['bloodGroup'] ?? 'Not Specified',
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

      final response = await ApiService.get('/attendance/reports/student-list$query');
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

  /// Extracts the first non-empty class/section target label from an API broadcast JSON map.
  static String? _extractClassTarget(Map<String, dynamic> json) {
    final candidates = <String?>[
      json['targetSectionName']?.toString(),
      json['targetClassName']?.toString(),
      json['targetClass']?.toString(),
      if (json['targetClassNames'] is List && (json['targetClassNames'] as List).isNotEmpty)
        (json['targetClassNames'] as List).map((e) => e.toString()).join(', '),
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
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

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String date = todayStr;
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
        date = json['createdAt']?.toString().split('T')[0] ?? todayStr;
      }
    }

    final String? classScope = _extractClassTarget(json) ??
        (targetType == 'class' || targetType == 'section' ? 'Class Notice' : null);

    final List<NoticeAttachment> attachmentObjects = [];
    final List<String> stringAttachments = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        final obj = NoticeAttachment.fromJson(a);
        attachmentObjects.add(obj);
        stringAttachments.add(obj.name);
      }
    } else if (json['mediaUrls'] is List) {
      for (final m in json['mediaUrls']) {
        final obj = NoticeAttachment.fromJson(m);
        attachmentObjects.add(obj);
        stringAttachments.add(obj.name);
      }
    }

    final bool isRead = json['isRead'] == true || json['is_read'] == true;

    final String? rawType = json['broadcastType']?.toString().toLowerCase() ??
        json['broadcast_type']?.toString().toLowerCase();
    final defaultType = targetType == 'school' ? 'school_notice' : 'class_notice';
    final BroadcastType broadcastType = BroadcastType.fromString(rawType ?? defaultType);

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
      attachments: stringAttachments,
      attachmentObjects: attachmentObjects,
      isRead: isRead,
      broadcastType: broadcastType,
    );
  }

  // --- Teacher Chat Methods ---

  static Future<ParentConversation?> startOrGetTeacherChatThread(String studentId) async {
    try {
      final response = await ApiService.post('/communication/chat/teacher/threads', {
        'studentId': studentId,
      });
      if (response is Map<String, dynamic>) {
        return ParentConversation.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error starting teacher chat thread: $e');
      return null;
    }
  }

  static Future<List<ParentConversation>> fetchTeacherChatThreads() async {
    try {
      final response = await ApiService.get('/communication/chat/teacher/threads');
      if (response is List) {
        return response
            .map((item) => ParentConversation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching teacher chat threads: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchTeacherThreadMessages(String threadId, {String? since}) async {
    try {
      final query = since != null ? '?since=${Uri.encodeComponent(since)}' : '';
      final response = await ApiService.get('/communication/chat/teacher/threads/$threadId/messages$query');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching thread messages: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendTeacherMessage(String threadId, String body) async {
    try {
      final response = await ApiService.post('/communication/chat/teacher/threads/$threadId/messages', {
        'body': body,
      });
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error sending teacher message: $e');
      return null;
    }
  }

  static Future<bool> markTeacherThreadRead(String threadId) async {
    try {
      await ApiService.post('/communication/chat/teacher/threads/$threadId/read', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteTeacherMessage(String messageId) async {
    try {
      await ApiService.delete('/communication/chat/teacher/messages/$messageId');
      return true;
    } catch (_) {
      return false;
    }
  }

  // Fetch Class Updates (Homework & Classwork) from Backend API (uses unified pipeline)
  static Future<List<ClassUpdate>> fetchClassUpdates({
    String? since,
    String? dateFrom,
    int? pageSize,
  }) async {
    final result = await fetchAllBroadcastsUnified(
      since: since,
      dateFrom: dateFrom,
      pageSize: pageSize,
    );
    return result.classUpdates;
  }

  static ClassUpdate _mapApiBroadcastToClassUpdate(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? 'CU-UNK';
    final String rawTitle = json['title'] ?? 'Class Update';
    final String bType = (json['broadcastType'] ?? json['broadcast_type'] ?? 'classwork').toString().toLowerCase();
    final String type = bType == 'homework' ? 'Homework' : 'Classwork';

    String subject = 'General';
    String title = rawTitle;
    if (rawTitle.contains(':')) {
      final parts = rawTitle.split(':');
      subject = parts[0].trim();
      title = parts.sublist(1).join(':').trim();
    }

    String description = json['body'] ?? json['message'] ?? '';
    description = description.replaceAll(RegExp(r'\bdue(\s+date)?\s*:\s*.*$', caseSensitive: false), '').trim();
    final String teacherName = json['senderName'] ?? json['author'] ?? 'Teacher';
    final String teacherId = json['composedByStaffId']?.toString() ??
        json['senderStaffId']?.toString() ??
        json['authorId']?.toString() ??
        '';

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String date = todayStr;
    if (json['createdAt'] != null) {
      try {
        final dt = DateTime.parse(json['createdAt'].toString()).toLocal();
        date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      } catch (_) {
        date = json['createdAt']?.toString().split('T')[0] ?? todayStr;
      }
    }

    final List<NoticeAttachment> attachmentObjects = [];
    final List<String> stringAttachments = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        final obj = NoticeAttachment.fromJson(a);
        attachmentObjects.add(obj);
        stringAttachments.add(obj.name);
      }
    }

    final String classTarget = _extractClassTarget(json) ?? 'All';

    return ClassUpdate(
      id: id,
      type: type,
      title: title.isNotEmpty ? title : rawTitle,
      description: description,
      subject: subject,
      classTarget: classTarget,
      teacherId: teacherId,
      teacherName: teacherName,
      dueDate: null,
      attachments: stringAttachments,
      attachmentObjects: attachmentObjects,
      date: date,
    );
  }

  // Fetch Student Health / Medical details
  static Future<HealthRecord> fetchStudentHealth(String studentId, {Student? studentFallback}) async {
    try {
      final response = await ApiService.get('/students/$studentId');
      if (response is Map<String, dynamic>) {
        return HealthRecord.fromJson(response);
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchStudentHealth error: $e');
    }
    return HealthRecord.empty(
      studentId,
      fullName: studentFallback?.name,
      bloodGroup: studentFallback?.bloodGroup,
      parentName: studentFallback?.parentName,
      parentMobile: studentFallback?.parentMobile,
    );
  }

  // Fetch Media Gallery Albums (Event Media)
  static Future<List<Album>> fetchGallery({String? academicYearId}) async {
    try {
      final queryParam = (academicYearId != null && academicYearId.isNotEmpty)
          ? '?academicYearId=$academicYearId'
          : '';
      final response = await ApiService.get('/communication/gallery$queryParam');

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
        return list
            .map((item) => Album.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('TeacherDataService.fetchGallery error: $e');
    }
    return [];
  }
}
