enum BroadcastType {
  classNotice('class_notice'),
  schoolNotice('school_notice'),
  homework('homework'),
  classwork('classwork'),
  unknown('unknown');

  final String value;
  const BroadcastType(this.value);

  static BroadcastType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'class_notice':
        return BroadcastType.classNotice;
      case 'school_notice':
        return BroadcastType.schoolNotice;
      case 'homework':
        return BroadcastType.homework;
      case 'classwork':
        return BroadcastType.classwork;
      default:
        return BroadcastType.unknown;
    }
  }
}

