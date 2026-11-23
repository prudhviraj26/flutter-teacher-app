import 'package:intl/intl.dart';
export 'broadcast_type.dart';
export 'health_record.dart';
import 'broadcast_type.dart';

class Teacher {
  final String id;
  final String name;
  final String employeeId;
  final String mobile;
  final String email;
  final String designation; // 'Class Teacher' | 'Subject Teacher'
  final String? assignedClass;
  final String? sectionId;
  final List<String>? assignedClasses;
  final List<String> subjects;
  final String joiningDate;
  final String? schoolName;
  final String? photoUrl;
  final String? schoolLogoUrl;

  Teacher({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.mobile,
    required this.email,
    required this.designation,
    this.assignedClass,
    this.sectionId,
    this.assignedClasses,
    required this.subjects,
    required this.joiningDate,
    this.schoolName,
    this.photoUrl,
    this.schoolLogoUrl,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      employeeId: json['employeeId'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
      designation: json['designation'] as String,
      assignedClass: json['assignedClass'] as String?,
      sectionId: json['sectionId'] as String?,
      assignedClasses: (json['assignedClasses'] as List<dynamic>?)?.map((e) => e as String).toList(),
      subjects: (json['subjects'] as List<dynamic>).map((e) => e as String).toList(),
      joiningDate: json['joiningDate'] as String,
      schoolName: json['schoolName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      schoolLogoUrl: json['schoolLogoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeId': employeeId,
      'mobile': mobile,
      'email': email,
      'designation': designation,
      'assignedClass': assignedClass,
      'sectionId': sectionId,
      'assignedClasses': assignedClasses,
      'subjects': subjects,
      'joiningDate': joiningDate,
      'schoolName': schoolName,
      'photoUrl': photoUrl,
      'schoolLogoUrl': schoolLogoUrl,
    };
  }

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'Teacher') return 'Teacher';
    final parts = trimmed.split(RegExp(r'\s+'));
    const prefixes = {'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.', 'dr', 'dr.', 'shri', 'smt'};
    if (parts.length > 1 && prefixes.contains(parts[0].toLowerCase())) {
      return parts[1];
    }
    return parts.first;
  }
}

class Student {
  final String id;
  final String name;
  final String rollNo;
  final String enrollmentNo;
  final String studentClass; // mapped from 'class'
  final String dateOfBirth;
  final String gender;
  final String parentName;
  final String parentMobile;
  final String? parentEmail;
  final String address;
  final String bloodGroup;
  final String emergencyContact;
  bool absentToday;
  final bool feeDefaulter;
  final double attendancePercentage;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.enrollmentNo,
    required this.studentClass,
    required this.dateOfBirth,
    required this.gender,
    required this.parentName,
    required this.parentMobile,
    this.parentEmail,
    required this.address,
    required this.bloodGroup,
    required this.emergencyContact,
    this.absentToday = false,
    this.feeDefaulter = false,
    this.attendancePercentage = 100.0,
  });

  Student copyWith({
    String? id,
    String? name,
    String? rollNo,
    String? enrollmentNo,
    String? studentClass,
    String? dateOfBirth,
    String? gender,
    String? parentName,
    String? parentMobile,
    String? parentEmail,
    String? address,
    String? bloodGroup,
    String? emergencyContact,
    bool? absentToday,
    bool? feeDefaulter,
    double? attendancePercentage,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNo: rollNo ?? this.rollNo,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      studentClass: studentClass ?? this.studentClass,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      parentName: parentName ?? this.parentName,
      parentMobile: parentMobile ?? this.parentMobile,
      parentEmail: parentEmail ?? this.parentEmail,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      absentToday: absentToday ?? this.absentToday,
      feeDefaulter: feeDefaulter ?? this.feeDefaulter,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}

class NoticeAttachment {
  final String name;
  final String url;
  final int sizeBytes;
  final String contentType;
  final String? blobPath;

  NoticeAttachment({
    required this.name,
    required this.url,
    this.sizeBytes = 0,
    this.contentType = '',
    this.blobPath,
  });

  factory NoticeAttachment.fromJson(dynamic json) {
    if (json is String) {
      final uri = Uri.tryParse(json);
      final fileName = uri != null && uri.pathSegments.isNotEmpty ? uri.pathSegments.last : json;
      return NoticeAttachment(
        name: fileName,
        url: json,
      );
    }
    if (json is Map) {
      return NoticeAttachment(
        name: (json['name'] ?? json['fileName'] ?? json['originalName'] ?? 'Attachment').toString(),
        url: (json['readUrl'] ?? json['url'] ?? '').toString(),
        sizeBytes: (json['sizeBytes'] is int)
            ? json['sizeBytes'] as int
            : int.tryParse(json['sizeBytes']?.toString() ?? '0') ?? 0,
        contentType: (json['contentType'] ?? json['mimeType'] ?? '').toString(),
        blobPath: json['blobPath']?.toString(),
      );
    }
    return NoticeAttachment(name: 'Attachment', url: '');
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'sizeBytes': sizeBytes,
    'contentType': contentType,
    if (blobPath != null) 'blobPath': blobPath,
  };

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class Notice {
  final String id;
  final String source;
  final String title;
  final String date;
  final String time;
  final String body;
  final String? fullDate;
  final NoticeCta? cta;
  final List<NoticeAttachment> attachments;

  Notice({
    required this.id,
    required this.source,
    required this.title,
    required this.date,
    required this.time,
    required this.body,
    this.fullDate,
    this.cta,
    this.attachments = const [],
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      body: json['body'] as String? ?? '',
      fullDate: json['fullDate'] as String?,
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List).map((a) => NoticeAttachment.fromJson(a)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'title': title,
    'date': date,
    'time': time,
    'body': body,
    'fullDate': fullDate,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };
}

class NoticeCta {
  final String label;
  final String action;

  NoticeCta({required this.label, required this.action});
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String author;
  final String authorId;
  final String? classScope; // mapped from 'class'
  final String date;
  final String time;
  final String scope; // 'Class' | 'School' | 'Staff'
  final String? fullDate;
  final List<String>? attachments;
  final List<NoticeAttachment> attachmentObjects;
  final bool isRead;
  final BroadcastType broadcastType;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.author,
    required this.authorId,
    this.classScope,
    required this.date,
    required this.time,
    required this.scope,
    this.fullDate,
    this.attachments,
    this.attachmentObjects = const [],
    this.isRead = false,
    this.broadcastType = BroadcastType.classNotice,
  });
}

class StaffNotice {
  final String id;
  final String title;
  final String message;
  final String author;
  final String date;
  final String time;
  final String category; // 'General' | 'Meeting' | 'Duty' | 'Urgent'
  final String? fullDate;
  final List<NoticeAttachment> attachments;

  StaffNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.author,
    required this.date,
    required this.time,
    required this.category,
    this.fullDate,
    this.attachments = const [],
  });

  factory StaffNotice.fromJson(Map<String, dynamic> json) {
    return StaffNotice(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      author: json['author'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      fullDate: json['fullDate'] as String?,
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List).map((a) => NoticeAttachment.fromJson(a)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'author': author,
    'date': date,
    'time': time,
    'category': category,
    'fullDate': fullDate,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };
}

class ClassUpdate {
  final String id;
  final String type; // 'Classwork' | 'Homework'
  final String title;
  final String description;
  final String subject;
  final String classTarget; // mapped from 'class'
  final String teacherId;
  final String teacherName;
  final String? dueDate;
  final List<String>? attachments;
  final List<NoticeAttachment> attachmentObjects;
  final String date;

  bool get isHomework => type.toLowerCase() == 'homework';
  bool get isClasswork => !isHomework;

  ClassUpdate({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.subject,
    required this.classTarget,
    required this.teacherId,
    required this.teacherName,
    this.dueDate,
    this.attachments,
    this.attachmentObjects = const [],
    required this.date,
  });

  ClassUpdate copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? subject,
    String? classTarget,
    String? teacherId,
    String? teacherName,
    String? dueDate,
    List<String>? attachments,
    List<NoticeAttachment>? attachmentObjects,
    String? date,
  }) {
    return ClassUpdate(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      classTarget: classTarget ?? this.classTarget,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      attachmentObjects: attachmentObjects ?? this.attachmentObjects,
      date: date ?? this.date,
    );
  }

  factory ClassUpdate.fromJson(Map<String, dynamic> json) {
    final rawAtts = json['attachments'];
    List<NoticeAttachment> attObjs = [];
    List<String> strAtts = [];
    if (rawAtts is List) {
      for (final a in rawAtts) {
        final obj = NoticeAttachment.fromJson(a);
        attObjs.add(obj);
        strAtts.add(obj.name);
      }
    }
    return ClassUpdate(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'Classwork',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      classTarget: json['classTarget'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      dueDate: json['dueDate'] as String?,
      attachments: strAtts,
      attachmentObjects: attObjs,
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'subject': subject,
      'classTarget': classTarget,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dueDate': dueDate,
      'attachments': attachmentObjects.isNotEmpty
          ? attachmentObjects.map((a) => a.toJson()).toList()
          : attachments,
      'date': date,
    };
  }
}

class AttendanceRecord {
  final String studentId;
  String status; // 'P' | 'A' | 'H' | 'W'
  String? reason;

  AttendanceRecord({required this.studentId, required this.status, this.reason});
}

class DailyAttendance {
  final String date;
  final String classTarget; // mapped from 'class'
  final List<AttendanceRecord> records;
  final String submittedBy;
  final String submittedAt;

  DailyAttendance({
    required this.date,
    required this.classTarget,
    required this.records,
    required this.submittedBy,
    required this.submittedAt,
  });
}

class ParentMessage {
  final String id;
  final String text;
  final String sender; // 'teacher' | 'parent'
  final String timestamp;
  final bool isAttachment;
  final String? attachmentName;
  bool failed;
  final String? readAt;
  final bool isDeleted;
  final String status; // 'sending' | 'sent' | 'delivered' | 'read'

  ParentMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isAttachment = false,
    this.attachmentName,
    this.failed = false,
    this.readAt,
    this.isDeleted = false,
    this.status = 'sent',
  });

  bool get isRead => readAt != null || status == 'read';

  factory ParentMessage.fromJson(Map<String, dynamic> json) {
    final senderType = (json['sender'] ?? json['senderType'] ?? 'teacher').toString();
    final bodyText = (json['text'] ?? json['body'] ?? '').toString();
    final readAtStr = json['readAt']?.toString();
    final isDel = json['isDeleted'] as bool? ?? false;

    String status = 'sent';
    if (readAtStr != null && readAtStr.isNotEmpty) {
      status = 'read';
    } else {
      status = 'delivered';
    }

    return ParentMessage(
      id: (json['id'] ?? '').toString(),
      text: bodyText,
      sender: senderType,
      timestamp: (json['timestamp'] ?? json['createdAt'] ?? '').toString(),
      isAttachment: json['isAttachment'] as bool? ?? false,
      attachmentName: json['attachmentName'] as String?,
      failed: json['failed'] as bool? ?? false,
      readAt: readAtStr,
      isDeleted: isDel,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp,
      'isAttachment': isAttachment,
      'attachmentName': attachmentName,
      'failed': failed,
      'readAt': readAt,
      'isDeleted': isDeleted,
      'status': status,
    };
  }
}

class ParentConversation {
  final String parentId;
  final String parentName;
  final String studentName;
  final String studentClass;
  final String mobile;
  String lastMessage;
  final List<ParentMessage> messages;
  String? timeLabel;
  bool unread;
  String? threadId;
  String? studentId;
  DateTime? lastMessageAt;
  int unreadCount;

  ParentConversation({
    required this.parentId,
    required this.parentName,
    required this.studentName,
    required this.studentClass,
    required this.mobile,
    required this.lastMessage,
    required this.messages,
    this.timeLabel,
    this.unread = false,
    this.threadId,
    this.studentId,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ParentConversation.fromJson(Map<String, dynamic> json) {
    var msgsJson = json['messages'] as List<dynamic>?;
    List<ParentMessage> msgs = msgsJson != null
        ? msgsJson.map((e) => ParentMessage.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    DateTime? lAt;
    if (json['lastMessageAt'] != null) {
      try {
        lAt = DateTime.parse(json['lastMessageAt'].toString()).toLocal();
      } catch (_) {}
    } else if (msgs.isNotEmpty) {
      try {
        lAt = DateTime.parse(msgs.last.timestamp).toLocal();
      } catch (_) {}
    }

    final uCount = json['teacherUnreadCount'] as int? ?? json['unreadCount'] as int? ?? 0;

    return ParentConversation(
      parentId: (json['parentId'] ?? json['parentContactId'] ?? '').toString(),
      parentName: (json['parentName'] ?? 'Parent').toString(),
      studentName: (json['studentName'] ?? 'Student').toString(),
      studentClass: (json['studentClass'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      lastMessage: (json['lastMessage'] ?? '').toString(),
      messages: msgs,
      timeLabel: json['timeLabel'] as String?,
      unread: uCount > 0 || (json['unread'] as bool? ?? false),
      threadId: json['threadId']?.toString() ?? json['id']?.toString(),
      studentId: json['studentId']?.toString(),
      lastMessageAt: lAt,
      unreadCount: uCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'studentName': studentName,
      'studentClass': studentClass,
      'mobile': mobile,
      'lastMessage': lastMessage,
      'messages': messages.map((e) => e.toJson()).toList(),
      'timeLabel': timeLabel,
      'unread': unread,
      'threadId': threadId,
      'studentId': studentId,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}

class Duty {
  final String id;
  final String date;
  final String type;
  final String time;
  final String location;
  final String notes;

  Duty({
    required this.id,
    required this.date,
    required this.type,
    required this.time,
    required this.location,
    required this.notes,
  });
}

class Event {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  final String startDate;
  final String endDate;
  final String? startTime;
  final String? endTime;
  final bool isAllDay;
  final String category; // 'CULTURAL' | 'ACADEMIC' | 'SPORTS' | 'GENERAL'
  final String scope; // 'SCHOOL' | 'CLASS' | 'SECTION'
  final String attendanceImpact;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.location = 'School Campus',
    this.description = '',
    this.startDate = '',
    this.endDate = '',
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.category = 'GENERAL',
    this.scope = 'SCHOOL',
    this.attendanceImpact = 'REGULAR_ATTENDANCE',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final start = json['startDate']?.toString() ?? json['date']?.toString() ?? '';
    final end = json['endDate']?.toString() ?? start;
    final isAllDay = json['isAllDay'] as bool? ?? false;
    final sTime = json['startTime']?.toString();
    final eTime = json['endTime']?.toString();

    // Format human-friendly time string
    String formattedTime = json['time']?.toString() ?? '';
    if (formattedTime.isEmpty) {
      if (isAllDay) {
        formattedTime = 'All Day';
      } else if (sTime != null && sTime.isNotEmpty) {
        formattedTime = eTime != null && eTime.isNotEmpty ? '$sTime - $eTime' : sTime;
      } else {
        formattedTime = 'All Day';
      }
    }

    // Format human-friendly date string
    String formattedDate = json['date']?.toString() ?? '';
    if (formattedDate.isEmpty && start.isNotEmpty) {
      try {
        final dt = DateTime.parse(start);
        formattedDate = DateFormat('EEEE, d MMMM yyyy').format(dt);
      } catch (_) {
        formattedDate = start;
      }
    }

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Event',
      date: formattedDate.isNotEmpty ? formattedDate : 'Upcoming',
      time: formattedTime,
      location: json['location']?.toString() ?? 'School Campus',
      description: json['description']?.toString() ?? '',
      startDate: start,
      endDate: end,
      startTime: sTime,
      endTime: eTime,
      isAllDay: isAllDay,
      category: json['category']?.toString() ?? 'GENERAL',
      scope: json['scope']?.toString() ?? 'SCHOOL',
      attendanceImpact: json['attendanceImpact']?.toString() ?? 'REGULAR_ATTENDANCE',
    );
  }
}

class AcademicYearItem {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  AcademicYearItem({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory AcademicYearItem.fromJson(Map<String, dynamic> json) {
    return AcademicYearItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      isCurrent: json['isCurrent'] == true,
    );
  }

  String get formattedDuration {
    final startFmt = DateFormat('MMM yyyy').format(startDate);
    final endFmt = DateFormat('MMM yyyy').format(endDate);
    return '$startFmt – $endFmt';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}

class Photo {
  final String id;
  final String url;

  Photo({required this.id, required this.url});
}

class Album {
  final String id;
  final String title;
  final String coverPhoto;
  final int photoCount;
  final List<Photo> photos;

  Album({
    required this.id,
    required this.title,
    required this.coverPhoto,
    required this.photoCount,
    required this.photos,
  });
}

class Holiday {
  final String id;
  final String date;
  final String day;
  final String month;
  final String? year;
  final String title;
  final String type; // 'National' | 'Festival' | 'School' | 'Gazetted' | 'Bank Holiday'
  final String academicYearId;
  final String? description;
  final DateTime fullDate;

  Holiday({
    required this.id,
    required this.date,
    required this.day,
    required this.month,
    this.year,
    required this.title,
    required this.type,
    this.academicYearId = '',
    this.description,
    DateTime? fullDate,
  }) : fullDate = fullDate ?? DateTime.tryParse(date) ?? DateTime.now();

  factory Holiday.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['date'] ?? '').toString();
    DateTime parsedDt;
    if (rawDate.contains('-')) {
      parsedDt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDt = DateTime.now();
    }

    final dayName = json['day']?.toString() ?? DateFormat('EEEE').format(parsedDt);
    final monthShort = json['month']?.toString() ?? DateFormat('MMM').format(parsedDt);
    final dayNum = rawDate.contains('-')
        ? DateFormat('dd').format(parsedDt)
        : (json['date']?.toString() ?? '01');

    return Holiday(
      id: (json['id'] ?? '').toString(),
      date: dayNum,
      day: dayName,
      month: monthShort,
      year: parsedDt.year.toString(),
      title: (json['name'] ?? json['title'] ?? 'School Holiday').toString(),
      type: (json['type'] ?? 'School').toString(),
      academicYearId: (json['academicYearId'] ?? '').toString(),
      description: json['description']?.toString(),
      fullDate: parsedDt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'day': day,
      'month': month,
      'year': year,
      'title': title,
      'type': type,
      'academicYearId': academicYearId,
      'description': description,
      'fullDate': fullDate.toIso8601String(),
    };
  }
}

class ExamResult {
  final String id;
  final String title;
  final String examClass;
  final String date;
  final String status; // 'Published' | 'Upcoming'

  ExamResult({
    required this.id,
    required this.title,
    required this.examClass,
    required this.date,
    required this.status,
  });
}

class SchoolConfig {
  final String name;
  final String nameMarathi;
  final String nameHindi;

  SchoolConfig({
    required this.name,
    required this.nameMarathi,
    required this.nameHindi,
  });
}

class TeacherDayAttendance {
  final String date;
  final String dayOfWeek;
  final bool isWorkingDay;
  final bool isHoliday;
  final String? holidayName;
  final String? status; // 'present' | 'absent' | 'half_day' | 'leave' | null
  final String? reason;
  final String? notes;
  final String? markedAt;
  final String? markedBy;

  TeacherDayAttendance({
    required this.date,
    required this.dayOfWeek,
    required this.isWorkingDay,
    required this.isHoliday,
    this.holidayName,
    this.status,
    this.reason,
    this.notes,
    this.markedAt,
    this.markedBy,
  });

  factory TeacherDayAttendance.fromJson(Map<String, dynamic> json) {
    return TeacherDayAttendance(
      date: json['date'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      isWorkingDay: json['isWorkingDay'] as bool? ?? true,
      isHoliday: json['isHoliday'] as bool? ?? false,
      holidayName: json['holidayName'] as String?,
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      markedAt: json['markedAt'] as String?,
      markedBy: json['markedBy'] as String?,
    );
  }
}

class TeacherAttendanceSummary {
  final int daysPresent;
  final int daysAbsent;
  final int daysHalfDay;
  final int daysLeave;
  final int daysNotMarked;
  final double? attendancePercent;

  TeacherAttendanceSummary({
    required this.daysPresent,
    required this.daysAbsent,
    required this.daysHalfDay,
    required this.daysLeave,
    required this.daysNotMarked,
    this.attendancePercent,
  });

  factory TeacherAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceSummary(
      daysPresent: (json['daysPresent'] as num?)?.toInt() ?? 0,
      daysAbsent: (json['daysAbsent'] as num?)?.toInt() ?? 0,
      daysHalfDay: (json['daysHalfDay'] as num?)?.toInt() ?? 0,
      daysLeave: (json['daysLeave'] as num?)?.toInt() ?? 0,
      daysNotMarked: (json['daysNotMarked'] as num?)?.toInt() ?? 0,
      attendancePercent: (json['attendancePercent'] as num?)?.toDouble(),
    );
  }
}

class TeacherMonthlyAttendance {
  final String month;
  final String monthLabel;
  final int instructionalDays;
  final TeacherAttendanceSummary summary;
  final List<TeacherDayAttendance> days;

  TeacherMonthlyAttendance({
    required this.month,
    required this.monthLabel,
    required this.instructionalDays,
    required this.summary,
    required this.days,
  });

  factory TeacherMonthlyAttendance.fromJson(Map<String, dynamic> json) {
    return TeacherMonthlyAttendance(
      month: json['month'] as String? ?? '',
      monthLabel: json['monthLabel'] as String? ?? '',
      instructionalDays: (json['instructionalDays'] as num?)?.toInt() ?? 0,
      summary: TeacherAttendanceSummary.fromJson((json['summary'] as Map<String, dynamic>?) ?? {}),
      days: ((json['days'] as List<dynamic>?) ?? [])
          .map((d) => TeacherDayAttendance.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

