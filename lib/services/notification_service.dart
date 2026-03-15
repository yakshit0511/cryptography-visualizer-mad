import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

/// Singleton service responsible for initializing and displaying
/// both local (instant & scheduled) and push notifications.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Should be assigned from the application so that the service can
  /// perform navigation when the user taps a notification.
  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initNotifications() async {
    // initialize timezone database (required for scheduled notifications)
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    // create an Android notification channel (required for Oreo+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel', // id
      'Default Notifications', // name
      description: 'General notifications for the Cryptography Visualizer app',
      importance: Importance.high,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onSelectNotification(response.payload);
      },
    );

    // If the app was launched via a notification tap, navigate accordingly.
    final NotificationAppLaunchDetails? launchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _onSelectNotification(launchDetails?.notificationResponse?.payload);
    }

    // register the channel (Android only)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

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
      handleNotificationClick();
    });
  }

  /// Instant local notification used when encryption completes.
  Future<void> showEncryptNotification({String payload = 'history'}) async {
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
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Reminder',
      'Check your Cipher History!',
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> _onSelectNotification(String? payload) async {
    // called when a local notification is tapped
    String route = '/history'; // default
    if (payload == 'profile') {
      route = '/profile';
    } else if (payload == 'home') {
      route = '/home';
    }
    // Navigate to the appropriate screen
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed(route);
    }
  }

  /// Shared handler for any notification click (instant, scheduled, or push).
  void handleNotificationClick() {
    if (navigatorKey == null) {
      debugPrint('Navigator key not set, cannot open history screen');
      return;
    }
    navigatorKey?.currentState?.pushNamed('/history');
  }
}
