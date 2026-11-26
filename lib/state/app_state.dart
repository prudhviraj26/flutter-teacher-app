import '../services/api_service.dart';
import '../services/notification_navigation_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/models.dart';
import '../constants/translations.dart';
import '../services/auth_service.dart';
import '../services/teacher_data_service.dart';
import '../services/attachment_local_store.dart';
import '../services/gallery_local_store.dart';

enum AuthBootstrapResult {
  authenticated,
  offlineAuthenticated,
  unauthenticated,
}

class AppState extends ChangeNotifier {
  String? _acceptedTermsVersion;
  String? _acceptedPrivacyVersion;
  String? get acceptedTermsVersion => _acceptedTermsVersion;
  String? get acceptedPrivacyVersion => _acceptedPrivacyVersion;

  Map<String, dynamic>? _activeLegalDocs;
  Map<String, dynamic>? get activeLegalDocs => _activeLegalDocs;

  Future<bool> checkNeedsLegalAssent() async {
    try {
      _activeLegalDocs = await ApiService.fetchActiveLegalDocuments();
      if (_activeLegalDocs == null) return false;

      final terms = _activeLegalDocs?['terms'] as Map<String, dynamic>?;
      final privacy = _activeLegalDocs?['privacy'] as Map<String, dynamic>?;

      final targetTermsVer = terms?['version']?.toString() ?? 'v1.0.0';
      final targetPrivacyVer = privacy?['version']?.toString() ?? 'v1.0.0';
      final termsMajor = terms?['isMajor'] == true;
      final privacyMajor = privacy?['isMajor'] == true;

      // Enterprise standard: Consent belongs to the individual user account
      final String? empId = _teacher?.employeeId;
      final String? mobile = _teacher?.mobile;
      final String? tId = _teacher?.id;

      final userTerms = _acceptedTermsVersion ??
          (empId != null && empId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$empId') : null) ??
          (mobile != null && mobile.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$mobile') : null) ??
          (tId != null && tId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$tId') : null);

      final userPrivacy = _acceptedPrivacyVersion ??
          (empId != null && empId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$empId') : null) ??
          (mobile != null && mobile.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$mobile') : null) ??
          (tId != null && tId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$tId') : null);

      if (userTerms == null || userPrivacy == null) {
        return true;
      }

      if (termsMajor && userTerms != targetTermsVer) {
        return true;
      }
      if (privacyMajor && userPrivacy != targetPrivacyVer) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[AppState] checkNeedsLegalAssent error: $e');
      return false;
    }
  }

  Future<void> onLegalConsentAccepted({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    _acceptedTermsVersion = termsVersion;
    _acceptedPrivacyVersion = privacyVersion;

    if (_teacher != null) {
      if (_teacher!.employeeId.isNotEmpty) {
        await _prefs?.setString('veyho_accepted_terms_${_teacher!.employeeId}', termsVersion);
        await _prefs?.setString('veyho_accepted_privacy_${_teacher!.employeeId}', privacyVersion);
      }
      if (_teacher!.mobile.isNotEmpty) {
        await _prefs?.setString('veyho_accepted_terms_${_teacher!.mobile}', termsVersion);
        await _prefs?.setString('veyho_accepted_privacy_${_teacher!.mobile}', privacyVersion);
      }
      if (_teacher!.id.isNotEmpty) {
        await _prefs?.setString('veyho_accepted_terms_${_teacher!.id}', termsVersion);
        await _prefs?.setString('veyho_accepted_privacy_${_teacher!.id}', privacyVersion);
      }
    }

    final userJson = _prefs?.getString('veyho_teacher_user');
    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = json.decode(userJson);
        userData['acceptedTermsVersion'] = termsVersion;
        userData['acceptedPrivacyVersion'] = privacyVersion;
        await _prefs?.setString('veyho_teacher_user', json.encode(userData));
      } catch (_) {}
    }
    notifyListeners();
  }

  SharedPreferences? _prefs;

  // Language & Session
  String _language = 'en';
  bool _loggedIn = false;
  bool _mustChangePassword = false;
  Teacher? _teacher;
  String? _profilePic;

  // Live Data lists
  List<Student> _students = [];
  List<Announcement> _announcements = [];
  List<ClassUpdate> _classUpdates = [];
  final List<DailyAttendance> _attendanceHistory = [];
  List<ParentConversation> _parentConversations = [];
  final List<Duty> _duties = [];
  List<StaffNotice> _staffNotices = [];
  List<Notice> _notices = [];
  List<Event> _events = [];
  bool _isEventsLoading = false;
  List<Album> _albums = [];
  bool _isGalleryLoading = false;
  List<Holiday> _holidays = [];
  List<AcademicYearItem> _academicYears = [];
  String? _selectedAcademicYearId;
  bool _isHolidaysLoading = false;
  final List<ExamResult> _examResults = [];
  final Map<String, HealthRecord> _studentHealthCache = {};
  bool _isLoadingHealth = false;

  // Active Attendance Marking Session (keyed by sectionId for multi-class teachers)
  final Map<String, Map<String, String>> _tempAttendanceBySection = {}; // sectionId -> (studentId -> 'P'|'A')
  final Map<String, Map<String, String>> _tempAttendanceReasonsBySection = {}; // sectionId -> (studentId -> reason)
  final Map<String, bool> _isAttendanceSubmittedTodayBySection = {}; // sectionId -> submitted
  final Map<String, DailyAttendance> _todayAttendanceBySection = {}; // sectionId -> today summary
  String? _activeAttendanceSectionId;

  bool _isLoadingStudents = false;
  bool _isSubmittingAttendance = false;

  // Teacher Own Monthly Attendance & Calendar
  TeacherMonthlyAttendance? _monthlyAttendance;
  bool _isLoadingMonthlyAttendance = false;

  // Read Tracking for Badges
  Set<String> _readNoticeIds = {};

  // Getters
  String get language => _language;
  bool get loggedIn => _loggedIn;
  bool get mustChangePassword => _mustChangePassword;
  String? _lastLoginError;
  String? get lastLoginError => _lastLoginError;
  Teacher? get teacher => _teacher;
  String? get profilePic => _profilePic;
  String? _schoolLogoUrl;
  String? get schoolLogoUrl => _schoolLogoUrl;
  String? _schoolLogoBase64;
  String? get schoolLogoBase64 => _schoolLogoBase64;
  String get currentSchoolName => _teacher?.schoolName ?? schoolConfig.name;
  bool get isLoadingStudents => _isLoadingStudents;

  String? get activeAttendanceSectionId {
    if (_activeAttendanceSectionId != null && _activeAttendanceSectionId!.isNotEmpty) {
      return _activeAttendanceSectionId;
    }
    final ids = _teacher?.allClassTeacherSectionIds ?? const [];
    if (ids.isNotEmpty) return ids.first;
    return _teacher?.sectionId;
  }

  String get activeAttendanceClassName =>
      _teacher?.resolveClassDisplayName(activeAttendanceSectionId) ??
      _teacher?.assignedClass ??
      '';

  void setActiveAttendanceSection(String? sectionId, {String? className}) {
    final resolved = (sectionId != null && sectionId.isNotEmpty)
        ? sectionId
        : _teacher?.resolveSectionId(className);
    if (resolved != null && resolved.isNotEmpty) {
      _activeAttendanceSectionId = resolved;
      initTempAttendance(sectionId: resolved, className: className);
      notifyListeners();
    }
  }

  String get _defaultAttendanceSectionKey {
    final active = activeAttendanceSectionId;
    if (active != null && active.isNotEmpty) return active;
    return 'default';
  }

  bool isAttendanceSubmittedForSection(String? sectionId) {
    final key = (sectionId != null && sectionId.isNotEmpty) ? sectionId : _defaultAttendanceSectionKey;
    return _isAttendanceSubmittedTodayBySection[key] == true;
  }

  bool get isAttendanceSubmittedToday => isAttendanceSubmittedForSection(activeAttendanceSectionId);
  bool get isSubmittingAttendance => _isSubmittingAttendance;
  TeacherMonthlyAttendance? get monthlyAttendance => _monthlyAttendance;
  bool get isLoadingMonthlyAttendance => _isLoadingMonthlyAttendance;

  // Read Tracking Getters & Badge Counters
  Set<String> get readNoticeIds => _readNoticeIds;
  bool isNoticeRead(String id) => _readNoticeIds.contains(id);

  int get unreadSchoolNoticesCount =>
      _notices.where((n) => !_readNoticeIds.contains(n.id)).length;

  int get unreadStaffNoticesCount =>
      _staffNotices.where((n) => !_readNoticeIds.contains(n.id)).length;

  int get unreadAnnouncementsCount {
    return announcements.where((a) {
      final isAuthoredByTeacher = (_teacher?.id != null && a.authorId == _teacher!.id) ||
          (_teacher?.name != null && a.author.toLowerCase() == _teacher!.name.toLowerCase());
      if (isAuthoredByTeacher) return false;
      return !_readNoticeIds.contains(a.id);
    }).length;
  }

  int get unreadClassUpdatesCount {
    return classUpdates.where((u) {
      final isAuthoredByTeacher = (_teacher?.id != null && u.teacherId == _teacher!.id) ||
          (_teacher?.name != null && u.teacherName.toLowerCase() == _teacher!.name.toLowerCase());
      if (isAuthoredByTeacher) return false;
      return !_readNoticeIds.contains(u.id);
    }).length;
  }

  int get unreadParentMessagesCount {
    int total = 0;
    for (final c in _parentConversations) {
      if (c.messages.isEmpty && c.lastMessage.trim().isEmpty) continue;
      if (c.unreadCount > 0) {
        total += c.unreadCount;
      } else if (c.unread) {
        total += 1;
      }
    }
    return total;
  }

  int get totalUnreadCommunicationsCount =>
      unreadSchoolNoticesCount +
      unreadStaffNoticesCount +
      unreadAnnouncementsCount +
      unreadClassUpdatesCount +
      unreadParentMessagesCount;

  final SchoolConfig schoolConfig = SchoolConfig(
    name: 'Demo International School',
    nameMarathi: 'डेमो आंतरराष्ट्रीय शाळा',
    nameHindi: 'डेमो इंटरनेशनल स्कूल',
  );

  List<Student> get students => _students;
  List<Announcement> get announcements => _filterClassAnnouncements(_announcements);
  List<ClassUpdate> get classUpdates => _filterClassUpdates(_classUpdates);
  List<DailyAttendance> get attendanceHistory => _attendanceHistory;
  List<ParentConversation> get parentConversations => _parentConversations;
  List<Duty> get duties => _duties;
  List<StaffNotice> get staffNotices => _staffNotices;
  List<Notice> get notices => _notices;
  List<Event> get events => _events;
  bool get isEventsLoading => _isEventsLoading;
  List<Album> get albums => _albums;
  bool get isGalleryLoading => _isGalleryLoading;
  List<Holiday> get holidays => _holidays;
  List<AcademicYearItem> get academicYears => _academicYears;
  String? get selectedAcademicYearId => _selectedAcademicYearId;
  bool get isHolidaysLoading => _isHolidaysLoading;
  List<ExamResult> get examResults => _examResults;
  bool get isLoadingHealth => _isLoadingHealth;

  HealthRecord? getCachedStudentHealth(String studentId) => _studentHealthCache[studentId];

  Future<HealthRecord> fetchStudentHealthRecord(Student student, {bool forceRefresh = false}) async {
    if (!forceRefresh && _studentHealthCache.containsKey(student.id)) {
      return _studentHealthCache[student.id]!;
    }
    _isLoadingHealth = true;
    notifyListeners();
    try {
      final record = await TeacherDataService.fetchStudentHealth(student.id, studentFallback: student);
      _studentHealthCache[student.id] = record;
      return record;
    } finally {
      _isLoadingHealth = false;
      notifyListeners();
    }
  }

  Map<String, String> tempAttendanceForSection(String? sectionId) {
    final key = (sectionId != null && sectionId.isNotEmpty) ? sectionId : _defaultAttendanceSectionKey;
    return _tempAttendanceBySection[key] ?? const {};
  }

  Map<String, String> tempAttendanceReasonsForSection(String? sectionId) {
    final key = (sectionId != null && sectionId.isNotEmpty) ? sectionId : _defaultAttendanceSectionKey;
    return _tempAttendanceReasonsBySection[key] ?? const {};
  }

  DailyAttendance? todayAttendanceForSection(String? sectionId) {
    final key = (sectionId != null && sectionId.isNotEmpty) ? sectionId : _defaultAttendanceSectionKey;
    return _todayAttendanceBySection[key];
  }

  /// Filters [_students] strictly to a single section by [sectionId] UUID or normalized [className].
  List<Student> studentsForSection({String? sectionId, String? className}) {
    final sid = (sectionId != null && sectionId.isNotEmpty) ? sectionId : null;
    final resolvedClass = className ?? _teacher?.resolveClassDisplayName(sid);
    final targetToken = (resolvedClass != null && resolvedClass.isNotEmpty)
        ? Teacher.normalizeClassToken(resolvedClass)
        : '';

    if (sid == null && targetToken.isEmpty) {
      return _students;
    }

    return _students.where((s) {
      if (sid != null && s.sectionId != null && s.sectionId!.isNotEmpty) {
        return s.sectionId == sid;
      }
      if (targetToken.isNotEmpty) {
        return Teacher.normalizeClassToken(s.studentClass) == targetToken;
      }
      return false;
    }).toList();
  }

  Map<String, String> get tempAttendance => tempAttendanceForSection(activeAttendanceSectionId);
  Map<String, String> get tempAttendanceReasons => tempAttendanceReasonsForSection(activeAttendanceSectionId);

  Completer<void>? _initCompleter;

  // Constructor
  AppState() {
    ensureInitialized();
  }

  Future<void> ensureInitialized() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    final completer = Completer<void>();
    _initCompleter = completer;
    try {
      await _initPreferences();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<AuthBootstrapResult> bootstrapAuth() async {
    await ensureInitialized();
    final refreshToken = await ApiService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _loggedIn = false;
      return AuthBootstrapResult.unauthenticated;
    }

    try {
      final refreshed = await ApiService.refreshTokenSilently();
      if (refreshed) {
        _loggedIn = true;
        // Silent session re-hydration: Replicates login by fetching /auth/me and syncing fresh models
        try {
          await loadLiveData(skipGetMe: false).timeout(const Duration(seconds: 4));
        } catch (_) {
          loadLiveData(skipGetMe: false);
        }
        return AuthBootstrapResult.authenticated;
      }
    } catch (e) {
      debugPrint('[AppState] Teacher splash proactive refresh error: $e');
    }

    final checkToken = await ApiService.getRefreshToken();
    if (checkToken != null && checkToken.isNotEmpty && _loggedIn) {
      return AuthBootstrapResult.offlineAuthenticated;
    }

    _loggedIn = false;
    return AuthBootstrapResult.unauthenticated;
  }

  /// Automated cache invalidation & migration hook triggered when APK is upgraded
  Future<void> _checkAppVersionUpgrade() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = '${packageInfo.version}+${packageInfo.buildNumber}';
      final storedBuild = _prefs?.getString('veyho_app_build_version');

      if (storedBuild != currentBuild) {
        debugPrint('[AppUpgrade] Teacher App update detected: $storedBuild -> $currentBuild');

        // 1. Wipe stale delta sync watermarks to force full fresh sync of notices, broadcasts, and rosters
        final keys = _prefs?.getKeys() ?? <String>{};
        for (final key in keys) {
          if (key.startsWith('veyho_last_broadcast_sync_') ||
              key.startsWith('veyho_last_teacher_broadcast_sync_') ||
              key.startsWith('veyho_last_sync_')) {
            await _prefs?.remove(key);
          }
        }

        // 2. Clear old cached notices/updates list so cards re-render cleanly
        await _prefs?.remove('cached_notices');
        await _prefs?.remove('cached_class_updates');

        // 3. Update stored build version
        await _prefs?.setString('veyho_app_build_version', currentBuild);
        debugPrint('[AppUpgrade] Cache migration complete for build $currentBuild');
      }
    } catch (e) {
      debugPrint('[AppUpgrade] Version check error: $e');
    }
  }

  // Init Shared Preferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAppVersionUpgrade();
    
    // Load language
    _language = _prefs?.getString('veyho_language') ?? 'en';
    
    // Load session user
    final userJson = _prefs?.getString('veyho_teacher_user');
    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = json.decode(userJson);
        final storedRole = userData['role']?.toString();
        // RBAC: Reject parent sessions in teacher app
        if (storedRole == 'parent') {
          debugPrint('RBAC: Parent session detected in teacher app storage. Purging.');
          await ApiService.clearTokens();
          await _prefs?.remove('veyho_teacher_user');
          _loggedIn = false;
        } else {
          _loggedIn = userData['loggedIn'] as bool? ?? false;
          if (userData['teacher'] != null) {
            _teacher = Teacher.fromJson(userData['teacher']);
          }
          final String? empId = _teacher?.employeeId;
          final String? mobile = _teacher?.mobile;
          final String? tId = _teacher?.id;

          _acceptedTermsVersion = userData['acceptedTermsVersion'] as String? ??
              (empId != null && empId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$empId') : null) ??
              (mobile != null && mobile.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$mobile') : null) ??
              (tId != null && tId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$tId') : null);

          _acceptedPrivacyVersion = userData['acceptedPrivacyVersion'] as String? ??
              (empId != null && empId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$empId') : null) ??
              (mobile != null && mobile.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$mobile') : null) ??
              (tId != null && tId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$tId') : null);
        }
      } catch (e) {
        // clear corrupted data
        _prefs?.remove('veyho_teacher_user');
      }
    }
    
    // Load cached school logo and teacher avatar from flash storage (0 egress)
    _schoolLogoUrl = _prefs?.getString('veyho_cached_school_logo_url');
    _schoolLogoBase64 = _prefs?.getString('veyho_cached_school_logo');
    if (_teacher != null) {
      _profilePic = _prefs?.getString('teacher_avatar_${_teacher!.employeeId}') ??
          _prefs?.getString('veyho_teacher_avatar_${_teacher!.id}');
    }

    // Load cached academic years if available
    final cachedYearsJson = _prefs?.getString('veyho_cached_academic_years');
    if (cachedYearsJson != null && cachedYearsJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(cachedYearsJson);
        _academicYears = list.map((item) => AcademicYearItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint("Error loading cached academic years: $e");
      }
    }

    // Load cached notices, class updates, and parent conversations immediately on startup
    await _loadReadNoticeIds();
    await _loadCachedNotices();
    await _loadCachedClassUpdates();
    await _loadCachedParentConversations();
    await _loadCachedAlbums();

    notifyListeners();

    if (_loggedIn) {
      _registerDeviceToken();
      loadLiveData();
    }
  }

  /// Download an image once and cache it as base64 in local device storage (0-egress)
  Future<void> _cacheImageLocally(
    String url,
    String prefKey,
    void Function(String base64Data) onCached,
  ) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final b64 = base64Encode(res.bodyBytes);
        await _prefs?.setString(prefKey, b64);
        onCached(b64);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error caching image locally ($prefKey): $e');
    }
  }

  Future<void> _syncMediaAssets(
    String? apiSchoolLogoUrl,
    String? apiPhotoUrl,
    String teacherId,
    String employeeId,
  ) async {
    // School Logo 0-egress flash caching
    if (apiSchoolLogoUrl != null && apiSchoolLogoUrl.isNotEmpty) {
      _schoolLogoUrl = apiSchoolLogoUrl;
      await _prefs?.setString('veyho_cached_school_logo_url', apiSchoolLogoUrl);
      final cleanLogoPath = apiSchoolLogoUrl.split('?').first;
      final cachedLogoPath = _prefs?.getString('veyho_cached_school_logo_path');
      if (_schoolLogoBase64 == null || cachedLogoPath != cleanLogoPath) {
        await _cacheImageLocally(apiSchoolLogoUrl, 'veyho_cached_school_logo', (b64) {
          _schoolLogoBase64 = b64;
        });
        await _prefs?.setString('veyho_cached_school_logo_path', cleanLogoPath);
      }
    }

    // Teacher Profile Picture 0-egress flash caching
    if (apiPhotoUrl != null && apiPhotoUrl.isNotEmpty) {
      final cleanPhotoPath = apiPhotoUrl.split('?').first;
      final cachedPhotoPath = _prefs?.getString('veyho_teacher_avatar_path_$teacherId');
      if (_profilePic == null || cachedPhotoPath != cleanPhotoPath) {
        await _cacheImageLocally(apiPhotoUrl, 'teacher_avatar_$employeeId', (b64) {
          _profilePic = b64;
        });
        if (_profilePic != null) {
          await _prefs?.setString('teacher_avatar_$employeeId', _profilePic!);
          await _prefs?.setString('veyho_teacher_avatar_$teacherId', _profilePic!);
        }
        await _prefs?.setString('veyho_teacher_avatar_path_$teacherId', cleanPhotoPath);
      }
    }
  }

  // Load Live Data from NestJS API
  
  DateTime? _lastSyncTime;

  /// Background-safe live data synchronization with 5-second debounce.
  Future<void> syncLiveData({bool force = false}) async {
    if (!_loggedIn) return;

    final now = DateTime.now();
    if (!force && _lastSyncTime != null && now.difference(_lastSyncTime!).inSeconds < 5) {
      debugPrint('[AppState] syncLiveData throttled (${now.difference(_lastSyncTime!).inSeconds}s since last sync)');
      return;
    }

    _lastSyncTime = now;
    debugPrint('[AppState] syncLiveData: auto-refreshing teacher live data in background');
    try {
      await loadLiveData(skipGetMe: false);
    } catch (e) {
      debugPrint('[AppState] syncLiveData error: $e');
    }
  }

  Teacher _parseTeacherFromUserMap(
    Map<String, dynamic> userMap, {
    String? fallbackMobile,
  }) {
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

    List<ClassSectionAssignment> parsedCtSections = [];
    if (userMap['classTeacherSections'] != null && userMap['classTeacherSections'] is List) {
      parsedCtSections = (userMap['classTeacherSections'] as List)
          .whereType<Map>()
          .map((e) => ClassSectionAssignment.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.sectionId.isNotEmpty || c.displayName.isNotEmpty)
          .toList();
    }

    final String designation = (role == 'class_teacher' || (userMap['roles'] is List && (userMap['roles'] as List).contains('class_teacher')))
        ? 'Class Teacher'
        : 'Subject Teacher';

    final String joiningDate = userMap['joiningDate'] as String? ?? userMap['dateOfJoining'] as String? ?? '01-06-2022';
    final String? apiPhotoUrl = userMap['photoUrl'] as String?;
    final String? apiSchoolLogoUrl = userMap['schoolLogoUrl'] as String?;

    return Teacher(
      id: userMap['id'] ?? 'T001',
      name: fullName.isNotEmpty ? fullName : 'Teacher',
      employeeId: apiEmployeeId,
      mobile: userMap['mobile'] ?? (fallbackMobile ?? ''),
      email: userMap['email'] ?? '',
      designation: designation,
      assignedClass: apiAssignedClass,
      sectionId: apiSectionId,
      assignedClasses: parsedAssignedClasses,
      classTeacherSections: parsedCtSections,
      subjects: parsedSubjects,
      joiningDate: joiningDate,
      schoolName: apiSchoolName,
      photoUrl: apiPhotoUrl,
      schoolLogoUrl: apiSchoolLogoUrl,
    );
  }

  Future<void> loadLiveData({bool skipGetMe = false}) async {
    if (!_loggedIn) return;

    _isLoadingStudents = true;
    notifyListeners();

    try {
      // Refresh current teacher details from /auth/me if available and not skipped
      if (!skipGetMe) {
        try {
          final meResponse = await AuthService.getMe();
          final userMap = meResponse['user'] as Map<String, dynamic>?;
          if (userMap != null) {
            final String role = userMap['role'] ?? 'class_teacher';
            if (role == 'parent') {
              debugPrint('RBAC: Teacher /auth/me returned parent role. Logging out.');
              await logout();
              return;
            }

            _teacher = _parseTeacherFromUserMap(userMap, fallbackMobile: _teacher?.mobile);

            // Sync media assets with local cache for 0-egress fast rendering
            await _syncMediaAssets(
              _teacher!.schoolLogoUrl,
              _teacher!.photoUrl,
              _teacher!.id,
              _teacher!.employeeId,
            );

            // Persist updated teacher model to SharedPreferences so subsequent cold starts have fresh data
            final updatedUserData = {
              'loggedIn': true,
              'role': role,
              'teacher': _teacher!.toJson(),
              'acceptedTermsVersion': _acceptedTermsVersion,
              'acceptedPrivacyVersion': _acceptedPrivacyVersion,
            };
            await _prefs?.setString('veyho_teacher_user', json.encode(updatedUserData));
          }
        } catch (e) {
          debugPrint("AuthService.getMe error during loadLiveData: $e");
        }
      }

      final List<String> teacherSectionIds = _teacher?.allClassTeacherSectionIds ?? const [];

      // Proactively ensure academic years are loaded & rollover cache check runs before delta sync
      try {
        await fetchAcademicYearsAndHolidays(silent: true);
      } catch (hErr) {
        debugPrint("Error fetching live academic years: $hErr");
      }

      // Run independent data fetching pipelines concurrently
      await Future.wait([
        // Pipeline 1: Live students, attendance percentages, and today's attendance sessions across all assigned sections
        () async {
          try {
            var liveStudents = await TeacherDataService.fetchStudents(sectionIds: teacherSectionIds);
            if (liveStudents.isEmpty && teacherSectionIds.isNotEmpty) {
              liveStudents = await TeacherDataService.fetchStudents();
            }
            _students = liveStudents;

            try {
              final attPercentages = await TeacherDataService.fetchStudentAttendancePercentages(
                sectionIds: teacherSectionIds,
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

            // Sequenced after _students loads so initTempAttendance & absentToday flags match populated rosters
            try {
              await fetchTodayAttendanceSession();
            } catch (e) {
              debugPrint("Error fetching today attendance session: $e");
            }
          } catch (e) {
            debugPrint("Error fetching live students: $e");
          }
        }(),

        // Pipeline 2: Unified Broadcast & Class Updates Delta Sync (updates notification badge counters)
        () async {
          try {
            await syncBroadcasts();
          } catch (e) {
            debugPrint("Error syncing broadcasts: $e");
          }
        }(),

        // Pipeline 4: School events
        () async {
          try {
            await refreshEvents(silent: true);
          } catch (eErr) {
            debugPrint("Error fetching live events: $eErr");
          }
        }(),

        // Pipeline 5: Parent chat conversations (for unread count badge & chat list)
        () async {
          try {
            await fetchParentConversations();
          } catch (e) {
            debugPrint("Error fetching parent conversations: $e");
          }
        }(),

        // Pipeline 6: Media Gallery Albums
        () async {
          try {
            await fetchGallery(silent: true);
          } catch (gErr) {
            debugPrint("Error fetching live gallery: $gErr");
          }
        }(),
      ]);

      // Fetch live subject assignments if current subjects are empty or default to General
      if (_teacher != null && (_teacher!.subjects.isEmpty || _teacher!.subjects.contains('General'))) {
        try {
          final liveSubjects = await TeacherDataService.fetchSubjectAssignments(_teacher!.id);
          if (liveSubjects.isNotEmpty) {
            _teacher = _teacher!.copyWith(subjects: liveSubjects);
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

      initTempAttendance();

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
    _lastLoginError = null;
    if (mobile.isEmpty || password.isEmpty) return false;

    try {
      final response = await AuthService.login(
        emailOrMobile: mobile,
        password: password,
      );

      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        // Role validation: Ensure user has a valid teacher role
        final String userRole = userMap['role']?.toString() ?? '';
        final List rolesList = userMap['roles'] is List ? (userMap['roles'] as List) : [];
        final roles = rolesList.map((r) => r.toString()).toList();
        if (userRole.isNotEmpty && !roles.contains(userRole)) {
          roles.add(userRole);
        }

        const validTeacherRoles = ['class_teacher', 'subject_teacher', 'teacher'];
        final isTeacher = roles.any((r) => validTeacherRoles.contains(r));

        if (!isTeacher) {
          _lastLoginError = 'Access restricted to teachers only.';
          await ApiService.clearTokens();
          return false;
        }
        final String role = userMap['role'] ?? 'class_teacher';
        final loadedTeacher = _parseTeacherFromUserMap(userMap, fallbackMobile: mobile);

        _mustChangePassword = (response['mustChangePassword'] == true) || (userMap['mustChangePassword'] == true);
        final String empId = loadedTeacher.employeeId;
        final String tMobile = loadedTeacher.mobile;
        final String tId = loadedTeacher.id;

        _acceptedTermsVersion = response['acceptedTermsVersion'] as String? ??
            userMap['acceptedTermsVersion'] as String? ??
            (empId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$empId') : null) ??
            (tMobile.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$tMobile') : null) ??
            (tId.isNotEmpty ? _prefs?.getString('veyho_accepted_terms_$tId') : null);

        _acceptedPrivacyVersion = response['acceptedPrivacyVersion'] as String? ??
            userMap['acceptedPrivacyVersion'] as String? ??
            (empId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$empId') : null) ??
            (tMobile.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$tMobile') : null) ??
            (tId.isNotEmpty ? _prefs?.getString('veyho_accepted_privacy_$tId') : null);
        _loggedIn = true;
        _teacher = loadedTeacher;

        final userData = {
          'loggedIn': true,
          'role': role,
          'teacher': loadedTeacher.toJson(),
          'acceptedTermsVersion': _acceptedTermsVersion,
          'acceptedPrivacyVersion': _acceptedPrivacyVersion,
        };
        await _prefs?.setString('veyho_teacher_user', json.encode(userData));
        _profilePic = _prefs?.getString('teacher_avatar_${loadedTeacher.employeeId}') ??
            _prefs?.getString('veyho_teacher_avatar_${loadedTeacher.id}');
        _syncMediaAssets(loadedTeacher.schoolLogoUrl, loadedTeacher.photoUrl, loadedTeacher.id, loadedTeacher.employeeId);
        // Instant local cache loads
        await _loadReadNoticeIds();
        await _loadCachedNotices();
        await _loadClassUpdates();
        notifyListeners();

        // Non-blocking background sync:
        // Transition into home instantly (<0.5s) while device registration
        // and parallel live data sync proceed in the background.
        _registerDeviceToken();
        loadLiveData(skipGetMe: true);

        return true;
      }
      return false;
    } catch (e) {
      debugPrint("API login failed: $e");
      String msg = e.toString().replaceAll('Exception: ', '').trim();
      if (msg.toLowerCase().startsWith('network error:')) {
        msg = msg.substring('network error:'.length).trim();
      }
      _lastLoginError = msg.isNotEmpty ? msg : 'Invalid Mobile Number or Password';
      return false;
    }
  }

  // Change Password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _mustChangePassword = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("AppState.changePassword error: $e");
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (err.contains('invalid_current_password') || err.toLowerCase().contains('invalid current') || err.toLowerCase().contains('current password')) {
        return 'Current temporary password is incorrect';
      }
      if (err.contains('cannot be the same')) {
        return 'New password cannot be the same as current password';
      }
      return err.isNotEmpty ? err : 'Failed to update password. Please try again.';
    }
  }

  // Logout Logic
  Future<void> logout() async {
    await _removeDeviceToken();
    await AuthService.logout();
    _loggedIn = false;
    _mustChangePassword = false;
    _teacher = null;
    _profilePic = null;
    _schoolLogoUrl = null;
    _schoolLogoBase64 = null;
    _staffNotices.clear();
    _notices.clear();
    _announcements.clear();
    _classUpdates.clear();
    _readNoticeIds.clear();
    _albums.clear();
    _students.clear();
    _activeAttendanceSectionId = null;
    _attendanceHistory.clear();
    _tempAttendanceBySection.clear();
    _tempAttendanceReasonsBySection.clear();
    _isAttendanceSubmittedTodayBySection.clear();
    _todayAttendanceBySection.clear();
    await _prefs?.remove('veyho_teacher_user');
    notifyListeners();
  }

  // Device Token Registration & Removal for FCM Push Pipeline
  Future<void> _registerDeviceToken() async {
    if (!_loggedIn) return;
    try {
      await NotificationNavigationService.requestPermissionAndRegister();
    } catch (e) {
      debugPrint("Device token registration error: $e");
    }
  }

  Future<void> _removeDeviceToken() async {
    try {
      await NotificationNavigationService.unregisterDeviceToken();
      await _prefs?.remove('veyho_device_token');
    } catch (e) {
      debugPrint("Device token removal error: $e");
    }
  }

  // Read Tracking Persistence & Live Sync Helpers
  Future<void> _loadReadNoticeIds() async {
    final teacherId = _teacher?.id ?? 'default';
    final list = _prefs?.getStringList('veyho_read_broadcasts_$teacherId') ?? [];
    _readNoticeIds = list.toSet();
  }

  Future<void> _saveReadNoticeIds() async {
    final teacherId = _teacher?.id ?? 'default';
    await _prefs?.setStringList('veyho_read_broadcasts_$teacherId', _readNoticeIds.toList());
  }

  Future<void> markNoticeAsRead(String id) async {
    if (id.isEmpty || _readNoticeIds.contains(id)) return;
    _readNoticeIds.add(id);
    await _saveReadNoticeIds();
    notifyListeners();
    if (_loggedIn) {
      TeacherDataService.markBroadcastRead(id).catchError((_) => false);
    }
  }

  Future<void> markStaffNoticeAsRead(String id) async => markNoticeAsRead(id);
  Future<void> markAnnouncementAsRead(String id) async => markNoticeAsRead(id);
  Future<void> markClassUpdateAsRead(String id) async => markNoticeAsRead(id);

  Future<void> markAllSchoolNoticesAsRead() async {
    final unread = _notices.where((n) => !_readNoticeIds.contains(n.id)).map((n) => n.id).toList();
    if (unread.isEmpty) return;
    _readNoticeIds.addAll(unread);
    await _saveReadNoticeIds();
    notifyListeners();
    for (final id in unread) {
      TeacherDataService.markBroadcastRead(id).catchError((_) => false);
    }
  }

  Future<void> markAllStaffNoticesAsRead() async {
    final unread = _staffNotices.where((n) => !_readNoticeIds.contains(n.id)).map((n) => n.id).toList();
    if (unread.isEmpty) return;
    _readNoticeIds.addAll(unread);
    await _saveReadNoticeIds();
    notifyListeners();
    for (final id in unread) {
      TeacherDataService.markBroadcastRead(id).catchError((_) => false);
    }
  }

  Future<void> markAllAnnouncementsAsRead() async {
    final unread = announcements.where((a) => !_readNoticeIds.contains(a.id)).map((a) => a.id).toList();
    if (unread.isEmpty) return;
    _readNoticeIds.addAll(unread);
    await _saveReadNoticeIds();
    notifyListeners();
    for (final id in unread) {
      TeacherDataService.markBroadcastRead(id).catchError((_) => false);
    }
  }

  Future<void> markAllClassUpdatesAsRead() async {
    final unread = classUpdates.where((u) => !_readNoticeIds.contains(u.id)).map((u) => u.id).toList();
    if (unread.isEmpty) return;
    _readNoticeIds.addAll(unread);
    await _saveReadNoticeIds();
    notifyListeners();
  }

  // Academic Year Check Helper
  bool _isWithinCurrentAcademicYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return true;
    try {
      final dt = DateTime.parse(dateStr);
      AcademicYearItem? currentYear;
      if (_academicYears.isNotEmpty) {
        currentYear = _academicYears.firstWhere(
          (y) => y.isCurrent,
          orElse: () => _academicYears.first,
        );
      }
      final ayStart = currentYear?.startDate ?? DateTime(2026, 4, 1);
      final ayEnd = currentYear != null
          ? DateTime(currentYear.endDate.year, currentYear.endDate.month, currentYear.endDate.day, 23, 59, 59)
          : DateTime(2027, 3, 31, 23, 59, 59);
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
        _staffNotices.sort((a, b) {
          final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
          final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
          return dtB.compareTo(dtA);
        });
      }
      final schoolStored = _prefs?.getString('veyho_teacher_school_notices_$teacherId');
      if (schoolStored != null && schoolStored.isNotEmpty) {
        final List<dynamic> list = json.decode(schoolStored);
        _notices = list.map((item) => Notice.fromJson(item as Map<String, dynamic>)).toList();
        _notices.sort((a, b) {
          final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
          final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
          return dtB.compareTo(dtA);
        });
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

  // Class Update normalization and fingerprinting helpers
  String _normalizeClassUpdateText(String s) {
    var cleaned = s.replaceAll(RegExp(r'\bdue(\s+date)?\s*:\s*.*$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b(regards|with regards|thanks|thank you)\b.*$', caseSensitive: false, dotAll: true), '');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  String _makeClassUpdateFingerprint(ClassUpdate u) {
    var subj = u.subject.trim().toLowerCase();
    if (subj.isEmpty || subj == 'general') {
      if (u.title.toLowerCase().contains('science')) {
        subj = 'science';
      } else if (u.title.toLowerCase().contains('math')) {
        subj = 'mathematics';
      } else if (u.title.toLowerCase().contains('english')) {
        subj = 'english';
      }
    }
    final norm = _normalizeClassUpdateText(u.description);
    final core = norm.length > 40 ? norm.substring(0, 40) : norm;
    return "${u.type.trim().toLowerCase()}_${subj}_$core";
  }

  /// Normalizes class/grade strings (e.g. "Grade 5 - A", "Class 5 A") into a canonical token ("5a")
  String _canonicalClass(String s) {
    return s
        .toLowerCase()
        .replaceAll('grade', '')
        .replaceAll('class', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Collects all canonical class tokens the currently authenticated teacher is assigned to
  List<String> _getTeacherCanonicalClasses() {
    final teacherClasses = <String>[];
    if (_teacher == null) return teacherClasses;
    void addClass(String raw) {
      if (raw.isEmpty) return;
      final norm = _canonicalClass(raw);
      if (norm.isNotEmpty && !teacherClasses.contains(norm)) {
        teacherClasses.add(norm);
      }
    }

    for (final c in _teacher!.allClassTeacherDisplayNames) {
      addClass(c);
    }
    if (_teacher!.assignedClasses != null) {
      for (final c in _teacher!.assignedClasses!) {
        addClass(c);
      }
    }
    return teacherClasses;
  }

  List<ClassUpdate> _filterClassUpdates(List<ClassUpdate> updates) {
    final teacherClasses = _getTeacherCanonicalClasses();
    return updates.where((u) {
      final isAuthoredByTeacher = (_teacher?.id != null && u.teacherId == _teacher!.id) ||
          (_teacher?.name != null && u.teacherName.toLowerCase() == _teacher!.name.toLowerCase());
      if (isAuthoredByTeacher) return true;

      if (teacherClasses.isEmpty) return false;

      final targetNorm = _canonicalClass(u.classTarget);
      if (targetNorm.isEmpty || targetNorm == 'all') return false;

      return teacherClasses.contains(targetNorm);
    }).toList();
  }

  List<Announcement> _filterClassAnnouncements(List<Announcement> announcements) {
    final teacherClasses = _getTeacherCanonicalClasses();
    return announcements.where((a) {
      if (a.scope == 'Staff' || a.scope == 'School') {
        return false;
      }

      if (a.broadcastType != BroadcastType.classNotice) {
        return false;
      }

      final isAuthoredByTeacher = (_teacher?.id != null && a.authorId == _teacher!.id) ||
          (_teacher?.name != null && a.author.toLowerCase() == _teacher!.name.toLowerCase());

      if (isAuthoredByTeacher) {
        return true;
      }

      if (a.scope == 'Class' || a.scope == 'Direct') {
        if (teacherClasses.isEmpty || a.classScope == null || a.classScope!.isEmpty) {
          return false;
        }
        if (a.classScope!.toLowerCase().trim() == 'class notice') {
          return false;
        }

        final targetNorm = _canonicalClass(a.classScope!);
        if (targetNorm.isEmpty || targetNorm == 'notice') return false;

        return teacherClasses.contains(targetNorm);
      }

      return false;
    }).toList();
  }

  /// Automatically clears delta sync watermarks, cleans up previous academic year cached
  /// data, and triggers storage file cleanup if the academic year has rolled over.
  Future<void> _checkAndPurgePriorAcademicYearCache(AcademicYearItem activeYear) async {
    final teacherId = _teacher?.id ?? 'default';
    final storedYearIdKey = 'veyho_active_academic_year_id_$teacherId';
    final watermarkKey = 'veyho_last_broadcast_sync_$teacherId';
    final lastKnownYearId = _prefs?.getString(storedYearIdKey);

    if (lastKnownYearId != null && lastKnownYearId != activeYear.id) {
      debugPrint('[AppState] Academic year rollover detected ($lastKnownYearId -> ${activeYear.id}). Purging prior academic year cache.');
      // 1. Invalidate delta sync watermark so next sync does a full baseline ingestion with dateFrom = activeYear.startDate
      await _prefs?.remove(watermarkKey);

      // 2. Purge in-memory records older than active academic year start date
      final threshold = activeYear.startDate;
      _staffNotices.removeWhere((n) {
        final dt = DateTime.tryParse(n.fullDate ?? n.date);
        return dt != null && dt.isBefore(threshold);
      });
      _notices.removeWhere((n) {
        final dt = DateTime.tryParse(n.fullDate ?? n.date);
        return dt != null && dt.isBefore(threshold);
      });
      _announcements.removeWhere((a) {
        final dt = DateTime.tryParse(a.fullDate ?? a.date);
        return dt != null && dt.isBefore(threshold);
      });
      _classUpdates.removeWhere((u) {
        final dt = DateTime.tryParse(u.date);
        return dt != null && dt.isBefore(threshold);
      });

      // 3. Prune orphan IDs from _readNoticeIds
      final activeIds = <String>{
        ..._staffNotices.map((n) => n.id),
        ..._notices.map((n) => n.id),
        ..._announcements.map((a) => a.id),
        ..._classUpdates.map((u) => u.id),
      };
      _readNoticeIds.removeWhere((id) => !activeIds.contains(id));

      // 4. Save cleaned collections to local cache
      await _saveCachedNotices();
      await _saveClassUpdates();
      await _saveReadNoticeIds();

      // Purge in-memory albums older than active academic year start date
      _albums.removeWhere((a) {
        final dt = DateTime.tryParse(a.eventDate);
        return dt != null && dt.isBefore(threshold);
      });
      await _saveCachedAlbums();

      // 5. Automatic cleanup of physical attachments & gallery media on local storage
      await AttachmentLocalStore.autoCleanupPriorAcademicYear(threshold);
      await GalleryLocalStore.autoCleanupPriorAcademicYear(threshold);

      // 6. Update stored academic year ID
      await _prefs?.setString(storedYearIdKey, activeYear.id);
      notifyListeners();
    } else if (lastKnownYearId == null) {
      // First boot / baseline setup
      await _prefs?.setString(storedYearIdKey, activeYear.id);
      // Run attachment & gallery cleanup on cold boot to ensure clean state
      await AttachmentLocalStore.autoCleanupPriorAcademicYear(activeYear.startDate);
      await GalleryLocalStore.autoCleanupPriorAcademicYear(activeYear.startDate);
    }
  }

  /// Unified sync pipeline for all broadcasts, school circulars, staff notices, and class updates.
  /// Bounded strictly to the active academic year start date when full, or incrementally using delta watermark.
  Future<void> syncBroadcasts({bool forceFull = false}) async {
    final teacherId = _teacher?.id ?? 'default';
    final watermarkKey = 'veyho_last_broadcast_sync_$teacherId';

    // 1. Determine active academic year
    AcademicYearItem? currentYear;
    if (_academicYears.isNotEmpty) {
      currentYear = _academicYears.firstWhere(
        (y) => y.isCurrent,
        orElse: () => _academicYears.first,
      );
    }
    final ayStart = currentYear?.startDate ?? DateTime(2026, 4, 1);

    // 2. Determine query parameters: since vs dateFrom
    String? since;
    String? dateFrom;
    final lastSync = _prefs?.getString(watermarkKey);

    if (forceFull || lastSync == null || lastSync.isEmpty) {
      // Cold start or forced manual pull-to-refresh: strictly bounded to active academic year start date!
      dateFrom = ayStart.toUtc().toIso8601String();
    } else {
      // Incremental delta sync
      since = lastSync;
    }

    try {
      final syncResult = await TeacherDataService.fetchAllBroadcastsUnified(
        since: since,
        dateFrom: dateFrom,
      );

      final liveAnnouncements = syncResult.announcements;
      final liveUpdates = syncResult.classUpdates;
      final isDelta = (since != null && since.isNotEmpty);

      // --- Part 1: Process Class Updates ---
      if (!isDelta) {
        // Cold start / full refresh:
        if (liveUpdates.isNotEmpty) {
          final Map<String, ClassUpdate> dedupContentMap = {};
          for (final u in liveUpdates) {
            final fp = _makeClassUpdateFingerprint(u);
            if (!dedupContentMap.containsKey(fp)) {
              dedupContentMap[fp] = u;
              final isAuthored = (_teacher?.id != null && u.teacherId == _teacher!.id) ||
                  (_teacher?.name != null && u.teacherName.toLowerCase() == _teacher!.name.toLowerCase());
              if (isAuthored) {
                _readNoticeIds.add(u.id);
              }
            }
          }
          // Merge any unsynced local pending updates (e.g. temporary CU... ids)
          for (final u in _classUpdates) {
            if (u.id.startsWith('CU')) {
              final fp = _makeClassUpdateFingerprint(u);
              if (!dedupContentMap.containsKey(fp)) {
                dedupContentMap[fp] = u;
              }
            }
          }
          final mergedList = _filterClassUpdates(
            dedupContentMap.values.where((u) => _isWithinCurrentAcademicYear(u.date)).toList(),
          );
          mergedList.sort((a, b) => b.date.compareTo(a.date));
          _classUpdates = mergedList;
        }
      } else {
        // Delta sync: upsert new/modified class updates
        if (liveUpdates.isNotEmpty) {
          final existingMap = <String, ClassUpdate>{};
          for (final u in _classUpdates) {
            existingMap[_makeClassUpdateFingerprint(u)] = u;
          }
          for (final u in liveUpdates) {
            final fp = _makeClassUpdateFingerprint(u);
            existingMap[fp] = u;
            final isAuthored = (_teacher?.id != null && u.teacherId == _teacher!.id) ||
                (_teacher?.name != null && u.teacherName.toLowerCase() == _teacher!.name.toLowerCase());
            if (isAuthored) {
              _readNoticeIds.add(u.id);
            }
          }
          final mergedList = _filterClassUpdates(
            existingMap.values.where((u) => _isWithinCurrentAcademicYear(u.date)).toList(),
          );
          mergedList.sort((a, b) => b.date.compareTo(a.date));
          _classUpdates = mergedList;
        }
      }

      // --- Part 2: Process Announcements (Staff, School, Class Notices) ---
      if (!isDelta) {
        // Cold start / full refresh
        if (liveAnnouncements.isNotEmpty) {
          for (final a in liveAnnouncements) {
            final isAuthoredByTeacher = (_teacher?.id != null && a.authorId == _teacher!.id) ||
                (_teacher?.name != null && a.author.toLowerCase() == _teacher!.name.toLowerCase());
            if (a.isRead || isAuthoredByTeacher) {
              _readNoticeIds.add(a.id);
            }
          }

          final ayAnnouncements = liveAnnouncements
              .where((a) => _isWithinCurrentAcademicYear(a.fullDate ?? a.date))
              .toList();
          ayAnnouncements.sort((a, b) {
            final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
            final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
            return dtB.compareTo(dtA);
          });

          // Staff Notices
          final staffList = ayAnnouncements.where((a) => a.scope == 'Staff').toList();
          _staffNotices = staffList.map((a) => StaffNotice(
            id: a.id,
            title: a.title,
            message: a.message,
            author: a.author,
            date: a.date,
            time: a.time,
            fullDate: a.fullDate,
            category: '',
            attachments: a.attachmentObjects,
          )).toList();

          // School Notices
          final schoolList = ayAnnouncements.where((a) => a.scope == 'School').toList();
          _notices = schoolList.map((a) => Notice(
            id: a.id,
            source: a.author,
            title: a.title,
            body: a.message,
            date: a.date,
            time: a.time,
            fullDate: a.fullDate,
            attachments: a.attachmentObjects,
          )).toList();

          // Class Announcements
          _announcements = _filterClassAnnouncements(ayAnnouncements);
        }
      } else {
        // Delta sync: upsert new/updated announcements into in-memory collections
        if (liveAnnouncements.isNotEmpty) {
          for (final a in liveAnnouncements) {
            final isAuthoredByTeacher = (_teacher?.id != null && a.authorId == _teacher!.id) ||
                (_teacher?.name != null && a.author.toLowerCase() == _teacher!.name.toLowerCase());
            if (a.isRead || isAuthoredByTeacher) {
              _readNoticeIds.add(a.id);
            }

            if (!_isWithinCurrentAcademicYear(a.fullDate ?? a.date)) continue;

            if (a.scope == 'Staff') {
              final staffItem = StaffNotice(
                id: a.id,
                title: a.title,
                message: a.message,
                author: a.author,
                date: a.date,
                time: a.time,
                fullDate: a.fullDate,
                category: '',
                attachments: a.attachmentObjects,
              );
              final idx = _staffNotices.indexWhere((n) => n.id == a.id);
              if (idx >= 0) {
                _staffNotices[idx] = staffItem;
              } else {
                _staffNotices.insert(0, staffItem);
              }
            } else if (a.scope == 'School') {
              final noticeItem = Notice(
                id: a.id,
                source: a.author,
                title: a.title,
                body: a.message,
                date: a.date,
                time: a.time,
                fullDate: a.fullDate,
                attachments: a.attachmentObjects,
              );
              final idx = _notices.indexWhere((n) => n.id == a.id);
              if (idx >= 0) {
                _notices[idx] = noticeItem;
              } else {
                _notices.insert(0, noticeItem);
              }
            }
          }

          // Also update class announcements for delta
          final newClassAnnouncements = _filterClassAnnouncements(liveAnnouncements);
          for (final a in newClassAnnouncements) {
            final idx = _announcements.indexWhere((n) => n.id == a.id);
            if (idx >= 0) {
              _announcements[idx] = a;
            } else {
              _announcements.insert(0, a);
            }
          }

          _staffNotices.sort((a, b) {
            final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
            final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
            return dtB.compareTo(dtA);
          });
          _notices.sort((a, b) {
            final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
            final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
            return dtB.compareTo(dtA);
          });
          _announcements.sort((a, b) {
            final dtA = DateTime.tryParse(a.fullDate ?? a.date) ?? DateTime(1970);
            final dtB = DateTime.tryParse(b.fullDate ?? b.date) ?? DateTime(1970);
            return dtB.compareTo(dtA);
          });
        }
      }

      // --- Part 3: Persist Caches and Advance Watermark ---
      await _saveReadNoticeIds();
      await _saveCachedNotices();
      await _saveClassUpdates();

      // Record high-water mark timestamp (in UTC ISO8601 format)
      await _prefs?.setString(watermarkKey, DateTime.now().toUtc().toIso8601String());
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing broadcasts: $e");
    }
  }

  // Refresh and sort all broadcasts by timestamp within Academic Year
  Future<void> refreshBroadcasts({bool forceFull = false}) async {
    await syncBroadcasts(forceFull: forceFull);
  }

  // Add Class Announcement with live API Sync to Web Admin Sent Items
  Future<void> addAnnouncement(
    Announcement ann, {
    List<dynamic>? rawAttachments,
    String? targetSectionId,
  }) async {
    _announcements.insert(0, ann);
    _readNoticeIds.add(ann.id);
    await _saveReadNoticeIds();
    notifyListeners();

    if (_loggedIn) {
      try {
        final resolvedSectionId = (targetSectionId != null && targetSectionId.isNotEmpty)
            ? targetSectionId
            : (_teacher?.resolveSectionId(ann.classScope) ?? _teacher?.sectionId);
        final hasSection = resolvedSectionId != null && resolvedSectionId.isNotEmpty;
        await TeacherDataService.createBroadcast(
          title: ann.title,
          message: ann.message,
          targetType: hasSection ? 'section' : 'school',
          broadcastType: BroadcastType.classNotice,
          targetSectionId: hasSection ? resolvedSectionId : null,
          attachments: rawAttachments ?? ann.attachments,
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
  Future<void> refreshClassUpdates({bool forceFull = false}) async {
    await syncBroadcasts(forceFull: forceFull);
  }

  void setSelectedAcademicYear(String? yearId) {
    if (_selectedAcademicYearId != yearId) {
      _selectedAcademicYearId = yearId;
      notifyListeners();
      fetchAcademicYearsAndHolidays(yearId: yearId);
      refreshEvents(yearId: yearId);
      fetchGallery(yearId: yearId);
    }
  }

  // Fetch Academic Years and Holidays from API
  Future<void> fetchAcademicYearsAndHolidays({String? yearId, bool silent = false}) async {
    try {
      if (!silent) {
        _isHolidaysLoading = true;
        notifyListeners();
      }

      // 1. Fetch academic years
      final years = await TeacherDataService.fetchAcademicYears();
      if (years.isNotEmpty) {
        _academicYears = years;
        // Save to prefs for offline/startup restore
        final yearsJson = _academicYears.map((y) => y.toJson()).toList();
        await _prefs?.setString('veyho_cached_academic_years', json.encode(yearsJson));

        // Check active year and execute cache purge if academic year rollover occurred
        final current = _academicYears.firstWhere(
          (y) => y.isCurrent,
          orElse: () => _academicYears.first,
        );
        await _checkAndPurgePriorAcademicYearCache(current);
      }

      // Determine target academic year
      String? targetYearId = yearId ?? _selectedAcademicYearId;
      if (targetYearId == null && _academicYears.isNotEmpty) {
        final current = _academicYears.firstWhere(
          (y) => y.isCurrent,
          orElse: () => _academicYears.first,
        );
        targetYearId = current.id;
      }
      _selectedAcademicYearId = targetYearId;

      // 2. Fetch holidays for target academic year
      final liveHolidays = await TeacherDataService.fetchSchoolHolidays(academicYearId: targetYearId);
      if (liveHolidays.isNotEmpty) {
        _holidays = liveHolidays;
        _holidays.sort((a, b) => a.fullDate.compareTo(b.fullDate));
      }
    } catch (e) {
      debugPrint("Error fetching academic years and holidays: $e");
    } finally {
      _isHolidaysLoading = false;
      notifyListeners();
    }
  }

  // Refresh Holidays from API
  Future<void> refreshHolidays({String? yearId}) async {
    await fetchAcademicYearsAndHolidays(yearId: yearId, silent: false);
  }

  // Refresh Events from API
  Future<void> refreshEvents({String? yearId, bool silent = false}) async {
    try {
      if (!silent) {
        _isEventsLoading = true;
        notifyListeners();
      }
      final targetYearId = yearId ?? _selectedAcademicYearId;
      final liveEvents = await TeacherDataService.fetchEvents(academicYearId: targetYearId);
      _events = liveEvents;
    } catch (e) {
      debugPrint("Error refreshing events: $e");
    } finally {
      _isEventsLoading = false;
      notifyListeners();
    }
  }

  // Refresh Media Gallery Albums (Event Media) from API
  Future<void> fetchGallery({String? yearId, bool silent = false}) async {
    try {
      if (!silent) {
        _isGalleryLoading = true;
        notifyListeners();
      }
      final targetYearId = yearId ?? _selectedAcademicYearId;
      final liveAlbums = await TeacherDataService.fetchGallery(academicYearId: targetYearId);
      _albums = liveAlbums;
      await _saveCachedAlbums();
    } catch (e) {
      debugPrint("Error fetching gallery albums: $e");
    } finally {
      _isGalleryLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedAlbums() async {
    final teacherId = _teacher?.id ?? 'default';
    final key = 'veyho_teacher_cached_albums_$teacherId';
    final raw = _prefs?.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = json.decode(raw);
        _albums = decoded
            .map((item) => Album.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint("Error restoring cached teacher albums: $e");
      }
    }
  }

  Future<void> _saveCachedAlbums() async {
    final teacherId = _teacher?.id ?? 'default';
    final key = 'veyho_teacher_cached_albums_$teacherId';
    try {
      final jsonStr = json.encode(_albums.map((a) => a.toJson()).toList());
      await _prefs?.setString(key, jsonStr);
    } catch (e) {
      debugPrint("Error saving cached teacher albums: $e");
    }
  }

  Future<void> _loadCachedClassUpdates() async {
    final teacherId = _teacher?.id ?? 'default';

    // Instant local cache restore with deduplication
    final stored = _prefs?.getString('veyho_teacher_class_updates_$teacherId');
    if (stored != null && stored.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(stored);
        final parsed = list.map((item) => ClassUpdate.fromJson(item as Map<String, dynamic>)).toList();
        
        final Map<String, ClassUpdate> dedupMap = {};
        for (final u in parsed) {
          if (_isWithinCurrentAcademicYear(u.date)) {
            final fp = _makeClassUpdateFingerprint(u);
            if (!dedupMap.containsKey(fp)) {
              dedupMap[fp] = u;
            } else if (dedupMap[fp]!.id.startsWith('CU') && !u.id.startsWith('CU')) {
              // Prefer server-assigned UUID over temporary CU... id
              dedupMap[fp] = u;
            }
          }
        }
        _classUpdates = dedupMap.values.toList();
        _classUpdates.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint("Error loading class updates from storage: $e");
      }
    }
  }

  Future<void> _loadClassUpdates() async {
    await _loadCachedClassUpdates();
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
  Future<void> addClassUpdate(
    ClassUpdate update, {
    List<dynamic>? rawAttachments,
    String? targetSectionId,
  }) async {
    _classUpdates.insert(0, update);
    _readNoticeIds.add(update.id);
    await _saveReadNoticeIds();
    await _saveClassUpdates();
    notifyListeners();

    if (_loggedIn) {
      try {
        final broadcastTitle = "${update.subject}: ${update.title}";
        final broadcastBody = update.description;
        final resolvedSectionId = (targetSectionId != null && targetSectionId.isNotEmpty)
            ? targetSectionId
            : (_teacher?.resolveSectionId(update.classTarget) ?? _teacher?.sectionId);
        final hasSection = resolvedSectionId != null && resolvedSectionId.isNotEmpty;
        final broadcastType = update.type.toLowerCase() == 'classwork'
            ? BroadcastType.classwork
            : BroadcastType.homework;
        final res = await TeacherDataService.createBroadcast(
          title: broadcastTitle,
          message: broadcastBody,
          targetType: hasSection ? 'section' : 'school',
          broadcastType: broadcastType,
          targetSectionId: hasSection ? resolvedSectionId : null,
          attachments: rawAttachments ?? update.attachments,
        );

        // If server created successfully with ID, reconcile temporary CU ID to server UUID immediately
        if (res != null && res['id'] != null) {
          final serverId = res['id'].toString();
          final idx = _classUpdates.indexWhere((u) => u.id == update.id);
          if (idx != -1) {
            _classUpdates[idx] = _classUpdates[idx].copyWith(id: serverId);
            _readNoticeIds.remove(update.id);
            _readNoticeIds.add(serverId);
            await _saveReadNoticeIds();
            await _saveClassUpdates();
            notifyListeners();
          }
        }
        await refreshClassUpdates();
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

      // Default empty monthly calendar if live API is unavailable
      _monthlyAttendance = _createEmptyMonthlyAttendance(month);
    } catch (e) {
      debugPrint("Error in fetchMonthlyAttendance: $e");
      _monthlyAttendance = _createEmptyMonthlyAttendance(month);
    } finally {
      _isLoadingMonthlyAttendance = false;
      notifyListeners();
    }
  }

  TeacherMonthlyAttendance _createEmptyMonthlyAttendance(String month) {
    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? DateTime.now().month) : DateTime.now().month;
    final totalDays = DateUtils.getDaysInMonth(year, m);

    final List<TeacherDayAttendance> days = [];
    int instructional = 0;

    for (int d = 1; d <= totalDays; d++) {
      final dt = DateTime(year, m, d);
      final isSunday = (dt.weekday == DateTime.sunday);
      final isWorking = !isSunday;
      final dateStr = "$year-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
      final dayOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][dt.weekday - 1];

      if (isWorking) {
        instructional++;
      }

      days.add(TeacherDayAttendance(
        date: dateStr,
        dayOfWeek: dayOfWeek,
        isWorkingDay: isWorking,
        isHoliday: false,
        holidayName: null,
        status: null,
      ));
    }

    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthLabel = "${monthNames[m - 1]} $year";

    return TeacherMonthlyAttendance(
      month: month,
      monthLabel: monthLabel,
      instructionalDays: instructional,
      summary: TeacherAttendanceSummary(
        daysPresent: 0,
        daysAbsent: 0,
        daysHalfDay: 0,
        daysLeave: 0,
        daysNotMarked: instructional,
        attendancePercent: null,
      ),
      days: days,
    );
  }

  String _resolveAttendanceSectionId(String? sectionId) {
    if (sectionId != null && sectionId.isNotEmpty) return sectionId;
    return _defaultAttendanceSectionKey;
  }

  // Active Attendance operations (scoped per sectionId)
  void initTempAttendance({String? sectionId, String? className}) {
    final key = _resolveAttendanceSectionId(sectionId);
    final sectionStudents = studentsForSection(sectionId: key == 'default' ? null : key, className: className);
    final validIds = sectionStudents.map((s) => s.id).toSet();

    final tempMap = _tempAttendanceBySection.putIfAbsent(key, () => {});
    final reasonMap = _tempAttendanceReasonsBySection.putIfAbsent(key, () => {});

    tempMap.removeWhere((id, _) => !validIds.contains(id));
    reasonMap.removeWhere((id, _) => !validIds.contains(id));
    for (final s in sectionStudents) {
      tempMap.putIfAbsent(s.id, () => 'P');
    }
  }

  void updateTempAttendance(String studentId, String status, {String? sectionId}) {
    final key = _resolveAttendanceSectionId(sectionId);
    final tempMap = _tempAttendanceBySection.putIfAbsent(key, () => {});
    tempMap[studentId] = status;
    if (status == 'P') {
      _tempAttendanceReasonsBySection[key]?.remove(studentId);
    }
    notifyListeners();
  }

  void updateTempAttendanceReason(String studentId, String reason, {String? sectionId}) {
    final key = _resolveAttendanceSectionId(sectionId);
    final reasonMap = _tempAttendanceReasonsBySection.putIfAbsent(key, () => {});
    reasonMap[studentId] = reason;
    notifyListeners();
  }

  Future<void> fetchTodayAttendanceSession({String? sectionId}) async {
    if (sectionId != null && sectionId.isNotEmpty) {
      await _fetchSingleAttendanceSession(sectionId);
      notifyListeners();
      return;
    }
    final sectionIds = _teacher?.allClassTeacherSectionIds ?? const [];
    if (sectionIds.isEmpty) return;
    await Future.wait(sectionIds.map(_fetchSingleAttendanceSession));
    notifyListeners();
  }

  Future<void> _fetchSingleAttendanceSession(String sectionId) async {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final classLabel = _teacher?.resolveClassDisplayName(sectionId) ?? _teacher?.assignedClass ?? 'Nursery A';

    try {
      final sessionData = await TeacherDataService.fetchAttendanceSession(sectionId, dateStr);
      if (sessionData != null && sessionData['session'] != null) {
        _isAttendanceSubmittedTodayBySection[sectionId] = true;
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
            _tempAttendanceBySection[sectionId] = fetchedTemp;
            _tempAttendanceReasonsBySection[sectionId] = fetchedReasons;
          }

          final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
          final summary = DailyAttendance(
            date: dateStr,
            classTarget: classLabel,
            sectionId: sectionId,
            records: records,
            submittedBy: _teacher?.id ?? 'T001',
            submittedAt: "$dateStr $timeStr",
          );
          _todayAttendanceBySection[sectionId] = summary;
          _attendanceHistory.removeWhere((h) => h.date == dateStr && (h.sectionId == sectionId || h.classTarget == classLabel));
          _attendanceHistory.insert(0, summary);
        }
      } else {
        _isAttendanceSubmittedTodayBySection[sectionId] = false;
        initTempAttendance(sectionId: sectionId, className: classLabel);
      }
    } catch (e) {
      debugPrint("Error fetching today's attendance session for $sectionId: $e");
    }
  }

  String? _lastAttendanceError;
  String? get lastAttendanceError => _lastAttendanceError;

  Future<bool> submitAttendance(
    String teacherId, {
    String? sectionId,
    String? classTarget,
  }) async {
    _isSubmittingAttendance = true;
    _lastAttendanceError = null;
    notifyListeners();

    final String? targetSectionId = (sectionId != null && sectionId.isNotEmpty)
        ? sectionId
        : _teacher?.sectionId;
    if (targetSectionId == null || targetSectionId.isEmpty) {
      _lastAttendanceError = 'No assigned section found for your teacher profile.';
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }

    final resolvedClassTarget = classTarget ?? _teacher?.resolveClassDisplayName(targetSectionId) ?? _teacher?.assignedClass ?? 'Grade 10 A';
    final sectionStudents = studentsForSection(sectionId: targetSectionId, className: resolvedClassTarget);
    if (sectionStudents.isEmpty) {
      _lastAttendanceError = 'No students found in $resolvedClassTarget roster.';
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, String>> apiRecords = [];
    final List<AttendanceRecord> localRecords = [];
    final tempMap = _tempAttendanceBySection[targetSectionId] ?? const {};
    final reasonMap = _tempAttendanceReasonsBySection[targetSectionId] ?? const {};

    // Strictly build records from current section students list only
    for (var s in sectionStudents) {
      final status = tempMap[s.id] ?? 'P';
      final reason = (reasonMap[s.id] ?? '').trim();
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
      sectionId: targetSectionId,
      date: dateStr,
      records: apiRecords,
    );

    if (error == null) {
      _isAttendanceSubmittedTodayBySection[targetSectionId] = true;
      final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      final summary = DailyAttendance(
        date: dateStr,
        classTarget: resolvedClassTarget,
        sectionId: targetSectionId,
        records: localRecords,
        submittedBy: teacherId,
        submittedAt: "$dateStr $timeStr",
      );
      _todayAttendanceBySection[targetSectionId] = summary;
      _attendanceHistory.removeWhere((h) => h.date == dateStr && (h.sectionId == targetSectionId || h.classTarget == resolvedClassTarget));
      _attendanceHistory.insert(0, summary);
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

  // Save parent conversations to SharedPreferences for instant badge rendering
  Future<void> _saveParentConversations() async {
    final teacherId = _teacher?.id ?? 'default';
    try {
      final jsonList = _parentConversations.map((c) => c.toJson()).toList();
      await _prefs?.setString('veyho_teacher_parent_conversations_$teacherId', json.encode(jsonList));
    } catch (e) {
      debugPrint("Error saving parent conversations to storage: $e");
    }
  }

  // Load cached parent conversations from storage immediately on startup
  Future<void> _loadCachedParentConversations() async {
    final teacherId = _teacher?.id ?? 'default';
    final stored = _prefs?.getString('veyho_teacher_parent_conversations_$teacherId');
    if (stored != null && stored.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(stored);
        _parentConversations = list
            .map((item) => ParentConversation.fromJson(item as Map<String, dynamic>))
            .where((c) => c.messages.isNotEmpty || c.lastMessage.trim().isNotEmpty)
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading cached parent conversations: $e");
      }
    }
  }

  // Parent chats operations
  Future<void> fetchParentConversations() async {
    try {
      final liveThreads = await TeacherDataService.fetchTeacherChatThreads();
      // Only keep active threads that have actual messages exchanged
      final validThreads = liveThreads
          .where((c) => c.messages.isNotEmpty || c.lastMessage.trim().isNotEmpty)
          .toList();

      // Preserve active in-memory messages to prevent chat screen flickering/disappearing
      for (final live in validThreads) {
        ParentConversation? existing;
        for (final c in _parentConversations) {
          if ((c.threadId != null && live.threadId != null && c.threadId == live.threadId) ||
              (c.parentId.isNotEmpty && c.parentId == live.parentId)) {
            existing = c;
            break;
          }
        }
        if (existing != null && existing.messages.isNotEmpty && live.messages.isEmpty) {
          live.messages.addAll(existing.messages);
        }
      }

      // Preserve any active empty conversation currently open in ParentChatScreen so polling
      // never wipes an open draft before the teacher sends the first message.
      final activeThreadId = NotificationNavigationService.activeChatThreadId;
      final activeParentId = NotificationNavigationService.activeChatParentId;
      for (final c in _parentConversations) {
        final isActiveOpen = (activeThreadId != null &&
                activeThreadId.isNotEmpty &&
                (c.threadId == activeThreadId || c.parentId == activeThreadId)) ||
            (activeParentId != null &&
                activeParentId.isNotEmpty &&
                (c.parentId == activeParentId || c.threadId == activeParentId));
        if (!isActiveOpen) continue;

        final alreadyPresent = validThreads.any((v) =>
            (v.threadId != null && c.threadId != null && v.threadId == c.threadId) ||
            (v.parentId.isNotEmpty && v.parentId == c.parentId));
        if (!alreadyPresent) {
          validThreads.insert(0, c);
        }
      }

      _parentConversations = validThreads;
      await _saveParentConversations();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching parent conversations: $e");
    }
  }

  void addParentMessage(String parentId, String text, String sender) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId || c.threadId == parentId);
    final now = DateTime.now();
    final timeIso = now.toIso8601String();
    
    final tempId = "temp_${now.millisecondsSinceEpoch}";
    final newMessage = ParentMessage(
      id: tempId,
      text: text,
      sender: sender,
      timestamp: timeIso,
      status: 'sending',
    );

    if (idx != -1) {
      _parentConversations[idx].messages.add(newMessage);
      _parentConversations[idx].lastMessage = text;
      _parentConversations[idx].lastMessageAt = now;
      _parentConversations[idx].timeLabel = 'Just now';
      if (sender == 'parent') {
        _parentConversations[idx].unread = true;
        _parentConversations[idx].unreadCount += 1;
      }
      notifyListeners();

      final realThreadId = _parentConversations[idx].threadId ?? _parentConversations[idx].parentId;
      final studentIdForDraft = _parentConversations[idx].studentId;
      if (realThreadId.isNotEmpty && sender == 'teacher') {
        Future<void>(() async {
          String effectiveThreadId = realThreadId;
          if (effectiveThreadId.startsWith('P_') && studentIdForDraft != null && studentIdForDraft.isNotEmpty) {
            final resolved = await TeacherDataService.startOrGetTeacherChatThread(studentIdForDraft);
            if (resolved != null && resolved.threadId != null && resolved.threadId!.isNotEmpty) {
              effectiveThreadId = resolved.threadId!;
              final curIdx = _parentConversations.indexWhere(
                  (c) => c.parentId == parentId || c.threadId == parentId);
              if (curIdx != -1) {
                _parentConversations[curIdx].threadId = effectiveThreadId;
              }
            }
          }
          final res = await TeacherDataService.sendTeacherMessage(effectiveThreadId, text);
          if (res != null && res['id'] != null) {
            final curIdx = _parentConversations.indexWhere(
                (c) => c.threadId == effectiveThreadId || c.parentId == parentId || c.threadId == parentId);
            if (curIdx != -1) {
              final mIdx = _parentConversations[curIdx].messages.indexWhere((m) => m.id == tempId);
              if (mIdx != -1) {
                _parentConversations[curIdx].messages[mIdx] = ParentMessage(
                  id: res['id'].toString(),
                  text: text,
                  sender: 'teacher',
                  timestamp: res['createdAt']?.toString() ?? now.toIso8601String(),
                  status: 'sent',
                );
                notifyListeners();
              }
            }
          }
        }).catchError((e) {
          debugPrint('Teacher send message error: $e');
        });
      }
    }
  }

  // Fetch full message history for active teacher conversation
  Future<void> fetchTeacherThreadMessages(String parentOrThreadId) async {
    final idx = _parentConversations.indexWhere((c) => c.threadId == parentOrThreadId || c.parentId == parentOrThreadId);
    if (idx == -1) return;

    final realThreadId = _parentConversations[idx].threadId ?? _parentConversations[idx].parentId;
    if (realThreadId.isEmpty) return;

    try {
      final res = await TeacherDataService.fetchTeacherThreadMessages(realThreadId);
      final msgsJson = res?['messages'] as List<dynamic>? ?? [];
      final msgs = msgsJson.map((m) => ParentMessage.fromJson(m as Map<String, dynamic>)).toList();
      _parentConversations[idx].messages.clear();
      _parentConversations[idx].messages.addAll(msgs);
      if (msgs.isNotEmpty) {
        _parentConversations[idx].lastMessage = msgs.last.text;
        try {
          _parentConversations[idx].lastMessageAt = DateTime.parse(msgs.last.timestamp).toLocal();
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching teacher thread messages: $e');
    }
  }

  void markChatAsRead(String parentOrThreadId) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentOrThreadId || c.threadId == parentOrThreadId);
    if (idx != -1) {
      _parentConversations[idx].unread = false;
      _parentConversations[idx].unreadCount = 0;
      final realThreadId = _parentConversations[idx].threadId ?? _parentConversations[idx].parentId;
      if (realThreadId.isNotEmpty) {
        TeacherDataService.markTeacherThreadRead(realThreadId).catchError((_) => false);
      }
      _saveParentConversations();
      notifyListeners();
    }
  }

  Future<void> pollTeacherChatDelta(String parentOrThreadId) async {
    final idx = _parentConversations.indexWhere((c) => c.threadId == parentOrThreadId || c.parentId == parentOrThreadId);
    if (idx == -1) return;

    final realThreadId = _parentConversations[idx].threadId ?? _parentConversations[idx].parentId;
    if (realThreadId.isEmpty) return;

    String? latestTime;
    if (_parentConversations[idx].messages.isNotEmpty) {
      final lastMsg = _parentConversations[idx].messages.last;
      if (DateTime.tryParse(lastMsg.timestamp) != null) {
        latestTime = lastMsg.timestamp;
      }
    }

    try {
      final res = await TeacherDataService.fetchTeacherThreadMessages(realThreadId, since: latestTime);
      final msgsJson = res?['messages'] as List<dynamic>? ?? [];
      if (msgsJson.isNotEmpty) {
        bool hasInbound = false;
        for (var m in msgsJson) {
          final parsed = ParentMessage.fromJson(m as Map<String, dynamic>);
          final existingIdx = _parentConversations[idx].messages.indexWhere((e) => e.id == parsed.id);
          if (existingIdx != -1) {
            _parentConversations[idx].messages[existingIdx] = parsed;
          } else {
            _parentConversations[idx].messages.add(parsed);
          }
          if (parsed.sender == 'parent') {
            hasInbound = true;
          }
          _parentConversations[idx].lastMessage = parsed.text;
          try {
            _parentConversations[idx].lastMessageAt = DateTime.parse(parsed.timestamp).toLocal();
          } catch (_) {}
        }
        // Since the teacher is actively watching this chat, automatically mark new incoming messages as read
        if (hasInbound) {
          _parentConversations[idx].unread = false;
          _parentConversations[idx].unreadCount = 0;
          TeacherDataService.markTeacherThreadRead(realThreadId).catchError((_) => false);
          _saveParentConversations();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteTeacherMessage(String parentOrThreadId, String messageId) async {
    final idx = _parentConversations.indexWhere((c) => c.threadId == parentOrThreadId || c.parentId == parentOrThreadId);
    if (idx != -1) {
      final mIdx = _parentConversations[idx].messages.indexWhere((m) => m.id == messageId);
      if (mIdx != -1) {
        final m = _parentConversations[idx].messages[mIdx];
        _parentConversations[idx].messages[mIdx] = ParentMessage(
          id: m.id,
          text: 'This message was deleted',
          sender: m.sender,
          timestamp: m.timestamp,
          readAt: m.readAt,
          isDeleted: true,
          status: m.status,
        );
        notifyListeners();
      }
      TeacherDataService.deleteTeacherMessage(messageId).catchError((_) => false);
    }
  }

  Future<ParentConversation> openOrCreateParentChat(Student student) async {
    final existingIdx = _parentConversations.indexWhere(
      (c) => (c.studentId != null && c.studentId == student.id) || c.studentName == student.name,
    );
    if (existingIdx != -1) {
      return _parentConversations[existingIdx];
    }

    final liveThread = await TeacherDataService.startOrGetTeacherChatThread(student.id);
    if (liveThread != null) {
      final idx = _parentConversations.indexWhere(
        (c) => (liveThread.threadId != null && c.threadId == liveThread.threadId) ||
            (c.studentId != null && c.studentId == student.id),
      );
      if (idx != -1) {
        return _parentConversations[idx];
      }
      _parentConversations.insert(0, liveThread);
      notifyListeners();
      return liveThread;
    }

    final cleanParent = student.parentName
        .replaceFirst(RegExp(r'^(Mr\.|Mrs\.|Ms\.|Mr|Mrs|Ms)\s*', caseSensitive: false), '')
        .trim();
    final fallbackConv = ParentConversation(
      parentId: 'P_${student.id}',
      parentName: cleanParent.isNotEmpty ? cleanParent : 'Parent',
      studentId: student.id,
      studentName: student.name,
      studentClass: student.studentClass,
      mobile: student.parentMobile,
      lastMessage: '',
      messages: [],
      timeLabel: 'Just now',
    );
    _parentConversations.insert(0, fallbackConv);
    notifyListeners();
    return fallbackConv;
  }

  void startNewConversation(ParentConversation newConv) {
    _parentConversations.insert(0, newConv);
    notifyListeners();
  }

  void addParentMessageObject(String parentId, ParentMessage message) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId || c.threadId == parentId);
    if (idx != -1) {
      _parentConversations[idx].messages.add(message);
      _parentConversations[idx].lastMessage = message.text;
      notifyListeners();
    }
  }

  void markMessageAsSent(String parentId, String messageId) {
    final idx = _parentConversations.indexWhere((c) => c.parentId == parentId || c.threadId == parentId);
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
    for (var h in _holidays) {
      if (h.fullDate.year == now.year &&
          h.fullDate.month == now.month &&
          h.fullDate.day == now.day) {
        return h;
      }
    }
    return null;
  }

  bool get isTodaySunday => DateTime.now().weekday == DateTime.sunday;
  bool get isTodayHoliday => getTodayHoliday() != null || isTodaySunday;
}
