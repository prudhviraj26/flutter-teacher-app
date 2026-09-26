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
  static Future<bool> submitAttendance({
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
      return true;
    } catch (e) {
      debugPrint('TeacherDataService.submitAttendance error: $e');
      return false;
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
    final sectionData = json['section'] ?? currentEnrollment;
    
    String studentClass = 'Class';
    if (sectionData != null) {
      final className = sectionData['className'] ?? sectionData['classLevel'] ?? '';
      final sectionName = sectionData['sectionName'] ?? sectionData['name'] ?? '';
      if (className.isNotEmpty || sectionName.isNotEmpty) {
        studentClass = "$className $sectionName".trim();
      }
    }

    final primaryParent = json['primaryParent'] ??
        (json['parentContacts'] != null && (json['parentContacts'] as List).isNotEmpty
            ? json['parentContacts'][0]
            : null);

    final String parentName = primaryParent != null 
        ? (primaryParent['name'] ?? "${primaryParent['firstName'] ?? ''} ${primaryParent['lastName'] ?? ''}".trim())
        : (json['parentName'] ?? 'Parent');
    final String parentMobile = primaryParent?['mobilePrimary'] ?? primaryParent?['mobile'] ?? json['parentMobile'] ?? '';

    return Student(
      id: id,
      name: fullName.isNotEmpty ? fullName : 'Student',
      rollNo: rollNo,
      enrollmentNo: enrollmentNo,
      studentClass: studentClass,
      dateOfBirth: json['dob'] ?? (json['dateOfBirth']?.toString().split('T')[0] ?? '01-01-2017'),
      gender: (json['gender'] as String?)?.toUpperCase() ?? 'Male',
      parentName: parentName.isNotEmpty ? parentName : 'Parent',
      parentMobile: parentMobile,
      address: json['addressLine1'] ?? json['address'] ?? 'School Address',
      bloodGroup: json['bloodGroup'] ?? 'O+',
      emergencyContact: parentMobile,
      absentToday: json['absentToday'] ?? false,
      feeDefaulter: json['feeDefaulter'] ?? false,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 95.0,
    );
  }

  // Mapper helper: API Broadcast JSON -> App Announcement model
  static Announcement _mapApiBroadcastToAnnouncement(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? 'A-UNK';
    final String title = json['title'] ?? 'Announcement';
    final String message = json['body'] ?? json['message'] ?? '';
    final String author = json['senderName'] ?? json['author'] ?? 'School Administration';

    return Announcement(
      id: id,
      title: title,
      message: message,
      author: author,
      authorId: json['senderId'] ?? 'ADMIN',
      date: json['createdAt']?.toString().split('T')[0] ?? '2026-05-10',
      time: '09:00 AM',
      scope: 'School',
    );
  }
}
