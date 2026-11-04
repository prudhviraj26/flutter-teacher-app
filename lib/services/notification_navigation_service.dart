import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'teacher_data_service.dart';
import 'device_info_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[TeacherPushBackground] Handling background message: ${message.messageId}');
}

class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important school and teacher notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static bool _isInitialized = false;

  /// Active chat identifier currently open in view (suppresses foreground notification banners)
  static String? activeChatThreadId;

  /// Initializes Firebase and Local Notification subsystems safely
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase App if configured
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Android notification channel
      if (!kIsWeb && Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_highImportanceChannel);
      }

      // 3. Initialize Local Notifications Plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              handleNotificationPayload(data);
            } catch (e) {
              debugPrint('[TeacherLocalNotification] Payload parse error: $e');
            }
          }
        },
      );

      // 4. Foreground Message Listener -> Display Heads-Up Banner & Auto-Sync In-App State
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[Teacher FCM Foreground] Received: ${message.notification?.title}');
        _showForegroundNotification(message);
        _syncAppStateOnNotification(message.data);
      });

      // 5. Background Message Open Listener (App running in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[Teacher FCM OpenedApp] User tapped notification from background');
        handleNotificationPayload(message.data);
      });

      // 6. Token Refresh Listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('[Teacher FCM] Token refreshed');
        final telemetry = await DeviceInfoService.getDeviceTelemetry();
        await TeacherDataService.registerDeviceToken(
          deviceToken: newToken,
          platform: telemetry.platform,
          deviceUuid: telemetry.deviceUuid,
          deviceModel: telemetry.deviceModel,
          deviceManufacturer: telemetry.deviceManufacturer,
          osVersion: telemetry.osVersion,
          appVersion: telemetry.appVersion,
          locale: telemetry.locale,
          timezone: telemetry.timezone,
        );
      });

      _isInitialized = true;
      debugPrint('✓ [NotificationNavigationService] Successfully initialized for Teacher App');
    } catch (e) {
      debugPrint(
        '⚠️ [NotificationNavigationService] Firebase initialization note: $e',
      );
    }
  }

  /// Check if the app was launched by tapping a push notification from terminated state
  static Future<void> checkInitialNotification() async {
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[Teacher FCM Terminated] App launched from notification');
        Future.delayed(const Duration(milliseconds: 600), () {
          handleNotificationPayload(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('[Teacher FCM] checkInitialNotification error: $e');
    }
  }

  /// Displays foreground notification heads-up banner
  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Suppress notification banner if user currently has this chat thread open
    final chatThread = message.data['threadId'] ?? message.data['parentId'];
    if (activeChatThreadId != null &&
        message.data['type'] == 'chat' &&
        chatThread != null &&
        (chatThread == activeChatThreadId)) {
      debugPrint('[FCM Foreground] Suppressed heads-up banner for active chat thread $activeChatThreadId');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _highImportanceChannel.id,
      _highImportanceChannel.name,
      channelDescription: _highImportanceChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF0F766E), // AppColors.primary
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadString =
        message.data.isNotEmpty ? jsonEncode(message.data) : null;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payloadString,
    );
  }

  /// Request push permission and register token with backend.
  /// If already authorized, skips prompt and quietly refreshes token.
  static Future<bool> requestPermissionAndRegister() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Check current permission status first
      final currentSettings = await messaging.getNotificationSettings();
      if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
          currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
        return await _fetchAndRegisterToken(messaging);
      }

      // 2. If not yet determined, prompt using Android/iOS native dialog
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAuthorized) {
        debugPrint('[Teacher FCM] Push permissions denied or dismissed by user');
        return false;
      }

      return await _fetchAndRegisterToken(messaging);
    } catch (e) {
      debugPrint('[Teacher FCM] requestPermissionAndRegister error: $e');
    }
    return false;
  }

  /// Fetches FCM device token and registers with the backend
  static Future<bool> _fetchAndRegisterToken(FirebaseMessaging messaging) async {
    try {
      String? token;
      try {
        token = await messaging.getToken();
      } catch (e) {
        debugPrint('[Teacher FCM] Error fetching APNs/FCM token: $e');
      }

      if (token != null && token.isNotEmpty) {
        debugPrint('[Teacher FCM] Token obtained: ${token.substring(0, 15)}...');
        final telemetry = await DeviceInfoService.getDeviceTelemetry();
        await TeacherDataService.registerDeviceToken(
          deviceToken: token,
          platform: telemetry.platform,
          deviceUuid: telemetry.deviceUuid,
          deviceModel: telemetry.deviceModel,
          deviceManufacturer: telemetry.deviceManufacturer,
          osVersion: telemetry.osVersion,
          appVersion: telemetry.appVersion,
          locale: telemetry.locale,
          timezone: telemetry.timezone,
        );
        return true;
      }
    } catch (e) {
      debugPrint('[Teacher FCM] _fetchAndRegisterToken error: $e');
    }
    return false;
  }

  /// Unregister FCM token on logout
  static Future<void> unregisterDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await TeacherDataService.removeDeviceToken(token);
        debugPrint('[Teacher FCM] Device token removed on logout');
      }
    } catch (e) {
      debugPrint('[Teacher FCM] unregisterDeviceToken note: $e');
    }
  }

  /// Real-time state synchronization when a notification arrives or is opened
  static void _syncAppStateOnNotification(Map<String, dynamic> data) {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.loggedIn) {
          final type = data['type']?.toString().toLowerCase();
          if (type == 'school_notice' || type == 'staff_notice' || type == 'notice' || type == 'broadcast') {
            appState.refreshBroadcasts();
          } else if (type == 'class_update' || type == 'homework' || type == 'classwork') {
            appState.refreshClassUpdates();
          } else if (type == 'chat' || type == 'parent_chat') {
            appState.fetchParentConversations();
          } else if (type == 'attendance') {
            appState.fetchTodayAttendanceSession();
          } else {
            appState.loadLiveData();
          }
        }
      }
    } catch (e) {
      debugPrint('[Teacher FCM Sync] Note during auto-refresh: $e');
    }
  }

  /// Deep-Link Routing for Teacher App Screens
  static Future<void> handleNotificationPayload(Map<String, dynamic> data) async {
    debugPrint('[TeacherNotificationNavigation] Handling payload: $data');

    // Always sync state so data is fresh
    _syncAppStateOnNotification(data);

    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('⚠️ NavigatorState is null. Cannot route.');
      return;
    }

    final type = data['type']?.toString().toLowerCase();
    final parentId = data['parentId']?.toString();

    switch (type) {
      case 'chat':
      case 'parent_chat':
        if (parentId != null && parentId.isNotEmpty) {
          nav.pushNamed('/parent-connect/chat/$parentId');
        } else {
          nav.pushNamed('/parent-connect');
        }
        break;
      case 'attendance':
        nav.pushNamed('/attendance');
        break;
      case 'notice':
      case 'broadcast':
      case 'school_notice':
        nav.pushNamed('/school-notice');
        break;
      case 'staff_notice':
        nav.pushNamed('/staff-notice');
        break;
      case 'class_update':
      case 'homework':
      case 'classwork':
        nav.pushNamed('/class-update');
        break;
      case 'announcement':
        nav.pushNamed('/announcement');
        break;
      case 'duty':
      case 'duty_diary':
        nav.pushNamed('/duty-diary');
        break;
      case 'event':
      case 'events':
        nav.pushNamed('/events');
        break;
      case 'gallery':
        nav.pushNamed('/gallery');
        break;
      case 'holiday':
      case 'holidays':
        nav.pushNamed('/holidays');
        break;
      default:
        nav.pushNamed('/home');
        break;
    }
  }
}

