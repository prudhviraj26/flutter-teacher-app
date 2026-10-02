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
    };
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

class Notice {
  final String id;
  final String source;
  final String title;
  final String date;
  final String time;
  final String body;
  final NoticeCta? cta;

  Notice({
    required this.id,
    required this.source,
    required this.title,
    required this.date,
    required this.time,
    required this.body,
    this.cta,
  });
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
  final String scope; // 'Class' | 'School'

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

  StaffNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.author,
    required this.date,
    required this.time,
    required this.category,
  });
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
  final String date;

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
    required this.date,
  });

  factory ClassUpdate.fromJson(Map<String, dynamic> json) {
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
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
      'attachments': attachments,
      'date': date,
    };
  }
}

class AttendanceRecord {
  final String studentId;
  String status; // 'P' | 'A' | 'H' | 'W'

  AttendanceRecord({required this.studentId, required this.status});
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

  ParentMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isAttachment = false,
    this.attachmentName,
    this.failed = false,
  });
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
  });
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

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });
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
  final String title;
  final String type; // 'National' | 'Festival' | 'School'

  Holiday({
    required this.id,
    required this.date,
    required this.day,
    required this.month,
    required this.title,
    required this.type,
  });
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

