import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service responsible for initializing and displaying
/// both local (instant & scheduled) and push notifications.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static int _scheduleNotificationIdCounter = 1000; // Use high IDs for scheduled notifications

  /// Should be assigned from the application so that the service can
  /// perform navigation when the user taps a notification.
  static GlobalKey<NavigatorState>? navigatorKey;

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    if (!enabled) {
      await _flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  Future<void> initNotifications() async {
    // initialize timezone database (required for scheduled notifications)
    try {
      tzdata.initializeTimeZones();
      final String timezoneName = tz.local.name;
      debugPrint('📍 Timezone: $timezoneName');
      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint('✅ Timezone initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Timezone initialization error: $e - Using default timezone');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (e) {
        debugPrint('❌ Failed to set timezone to UTC: $e');
      }
    }

    // create an Android notification channel (required for Oreo+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel', // id
      'Default Notifications', // name
      description: 'General notifications for the Cryptography Visualizer app',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iOSSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped with payload: ${response.payload}');
        _onSelectNotification(response.payload);
      },
    );

    // If the app was launched via a notification tap, navigate accordingly.
    final NotificationAppLaunchDetails? launchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      debugPrint('🚀 App launched from notification tap');
      _onSelectNotification(launchDetails?.notificationResponse?.payload);
    }

    // register the channel (Android only)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request permissions for iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // note: local notifications do not require an explicit permission request
    //    on Android. iOS permissions are managed by the platform package or
    //    by the user when they first receive a notification.
    // configure Firebase messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    // handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'FCM onMessage received: title=${message.notification?.title} body=${message.notification?.body}',
      );
    });

    // when a message is opened/tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened');
      handleNotificationClick(
        message.data['route'] ?? message.data['payload'] ?? 'history',
      );
    });
  }

  /// Instant local notification used when encryption completes.
  Future<void> showEncryptNotification({String payload = 'history'}) async {
    if (!await isNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Encryption Complete',
      'Your encryption process finished successfully.',
      details,
      payload: payload,
    );
  }

  /// Instant local notification used when decryption completes.
  Future<void> showDecryptNotification({String payload = 'history'}) async {
    if (!await isNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      2,
      'Decryption Complete',
      'Your decryption process finished successfully.',
      details,
      payload: payload,
    );
  }

  /// Instant local notification when adding to history.
  Future<void> showAddToHistoryNotification({String payload = 'history'}) async {
    if (!await isNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      3,
      'Added to History',
      'Your cipher operation has been saved to history.',
      details,
      payload: payload,
    );
  }

  /// Instant local notification when profile is updated.
  Future<void> showUpdateProfileNotification({String payload = 'profile'}) async {
    if (!await isNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      4,
      'Profile Updated',
      'Your profile has been updated successfully.',
      details,
      payload: payload,
    );
  }

  /// Schedule a notification after the given [delay].
  Future<void> scheduleNotification(Duration delay, {String payload = 'history'}) async {
    if (!await isNotificationsEnabled()) return;

    final int notificationId = _scheduleNotificationIdCounter++;
    Future.delayed(delay, () async {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Reminder',
        'Check your Cipher History!',
        details,
        payload: payload,
      );
    });
  }

  Future<void> _onSelectNotification(String? payload) async {
    // called when a local notification is tapped
    final route = _routeForPayload(payload);

    // Navigate to the appropriate screen
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed(route);
    }
  }

  /// Shared handler for any notification click (instant, scheduled, or push).
  void handleNotificationClick([String? payload]) {
    if (navigatorKey == null) {
      debugPrint('Navigator key not set, cannot open notification target');
      return;
    }
    navigatorKey?.currentState?.pushNamed(_routeForPayload(payload));
  }

  String _routeForPayload(String? payload) {
    switch (payload) {
      case 'profile':
        return '/profile';
      case 'home':
        return '/home';
      case 'settings':
        return '/settings';
      case 'history':
      default:
        return '/history';
    }
  }
}
