import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int downloadProgressId = 1;
  static const String channelId = 'download_progress';
  static const String channelName = 'Download Progress';
  static const String channelDescription = 'Shows download progress for tracks';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.low,
              showBadge: false,
              playSound: false,
              enableVibration: false,
            ),
          );
    }

    _isInitialized = true;
  }

  Future<void> showDownloadProgress({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
  }) async {
    if (!_isInitialized) await initialize();

    final percentage = total > 0 ? (progress * 100 ~/ total) : 0;
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      downloadProgressId,
      'Downloading $trackName',
      '$artistName • $percentage%',
      details,
    );
  }

  Future<void> showDownloadComplete({
    required String trackName,
    required String artistName,
    int? completedCount,
    int? totalCount,
  }) async {
    if (!_isInitialized) await initialize();

    final title = completedCount != null && totalCount != null
        ? 'Download Complete ($completedCount/$totalCount)'
        : 'Download Complete';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      downloadProgressId,
      title,
      '$trackName - $artistName',
      details,
    );
  }

  Future<void> showQueueComplete({
    required int completedCount,
    required int failedCount,
  }) async {
    if (!_isInitialized) await initialize();

    final title = failedCount > 0
        ? 'Downloads Finished ($completedCount done, $failedCount failed)'
        : 'All Downloads Complete';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      downloadProgressId,
      title,
      '$completedCount tracks downloaded successfully',
      details,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notifications.cancel(downloadProgressId);
  }
}
