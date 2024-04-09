import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String? userId = FirebaseAuth.instance.currentUser?.uid;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseMessaging();
  await initNotifications();
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  handleRemoteMessage(message);
}

Future<void> initFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleRemoteMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  String? fcmToken = await messaging.getToken();

  // Save FCM token to Firestore
  if (fcmToken != null) {
    await saveFcmTokenToFirestore(fcmToken, userId!);
  }
}

void handleRemoteMessage(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {

    showNotification(
      FlutterLocalNotificationsPlugin(),
      '${notification.title} - ${notification.body}',
    );
  }
}

Future<void> saveFcmTokenToFirestore(String fcmToken, String userId) async {
  try {
    CollectionReference tokens =
        FirebaseFirestore.instance.collection('userID_tokens');

    // Set the token to the document with the user ID
    await tokens.doc(userId).set({'FCMtoken': fcmToken});

  } catch (e) {
    rethrow;
  }
}

Future<void> initNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Define a notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'step_milestone_channel', // id
    'Step Milestone', // title
    description: 'Displays step milestones', // description
    importance: Importance.max,
  );

  // Create the notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> showNotification(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  String message,
) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'step_milestone_channel',
    'Step Milestone',
    channelDescription: 'Displays step milestones',
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'ticker',
    visibility: NotificationVisibility.public,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    'Step Milestone Notification',
    message,
    platformChannelSpecifics,
  );
}
