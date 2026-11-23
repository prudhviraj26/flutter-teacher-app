class HealthRecord {
  final String studentId;
  final String fullName;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final String ongoingMedications;
  final String emergencyContactName;
  final String emergencyContactRelation;
  final String emergencyContactPhone;
  final String doctorName;
  final String doctorPhone;
  final String notes;

  HealthRecord({
    required this.studentId,
    this.fullName = '',
    this.bloodGroup = 'NA',
    this.allergies = 'NA',
    this.chronicConditions = 'NA',
    this.ongoingMedications = 'NA',
    this.emergencyContactName = 'NA',
    this.emergencyContactRelation = 'NA',
    this.emergencyContactPhone = 'NA',
    this.doctorName = 'NA',
    this.doctorPhone = 'NA',
    this.notes = 'NA',
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    String sanitize(dynamic val) {
      if (val == null) return 'NA';
      final s = val.toString().trim();
      if (s.isEmpty ||
          s == '—' ||
          s.toLowerCase() == 'none reported' ||
          s.toLowerCase() == 'not provided' ||
          s.toLowerCase() == 'not specified' ||
          s.toLowerCase() == 'n/a') {
        return 'NA';
      }
      return s;
    }

    final m = json['medicalInfo'] is Map<String, dynamic>
        ? json['medicalInfo'] as Map<String, dynamic>
        : json;

    return HealthRecord(
      studentId: (json['studentId'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      bloodGroup: sanitize(json['bloodGroup'] ?? m['bloodGroup']),
      allergies: sanitize(m['allergies']),
      chronicConditions: sanitize(m['chronicConditions'] ?? m['conditions']),
      ongoingMedications: sanitize(m['ongoingMedications'] ?? m['medications']),
      emergencyContactName: sanitize(m['emergencyContactName'] ?? json['parentName']),
      emergencyContactRelation: sanitize(m['emergencyContactRelation'] ?? 'Parent'),
      emergencyContactPhone: sanitize(m['emergencyContactPhone'] ?? json['parentMobile']),
      doctorName: sanitize(m['doctorName'] ?? m['familyDoctorName']),
      doctorPhone: sanitize(m['doctorPhone'] ?? m['familyDoctorPhone']),
      notes: sanitize(m['notes']),
    );
  }

  factory HealthRecord.empty(
    String studentId, {
    String? fullName,
    String? bloodGroup,
    String? parentName,
    String? parentMobile,
  }) {
    return HealthRecord(
      studentId: studentId,
      fullName: fullName ?? '',
      bloodGroup: (bloodGroup != null &&
              bloodGroup.isNotEmpty &&
              bloodGroup.toLowerCase() != 'not specified')
          ? bloodGroup
          : 'NA',
      emergencyContactName: (parentName != null && parentName.isNotEmpty) ? parentName : 'NA',
      emergencyContactRelation: (parentName != null && parentName.isNotEmpty) ? 'Parent' : 'NA',
      emergencyContactPhone: (parentMobile != null && parentMobile.isNotEmpty) ? parentMobile : 'NA',
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'fullName': fullName,
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'ongoingMedications': ongoingMedications,
        'emergencyContactName': emergencyContactName,
        'emergencyContactRelation': emergencyContactRelation,
        'emergencyContactPhone': emergencyContactPhone,
        'doctorName': doctorName,
        'doctorPhone': doctorPhone,
        'notes': notes,
      };
}

