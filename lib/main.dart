import 'package:background_services/screens/health_screen.dart';
import 'package:background_services/screens/sign_in_screen.dart';
import 'package:background_services/utils/api_calls.dart';
import 'package:background_services/utils/notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:rxdart/rxdart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Permission.activityRecognition.request();
  await Permission.location.request();
  await Permission.notification.request();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  startResetTimer();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'step_milestone_channel',
      channelName: 'Basic notifications',
      channelDescription: 'Displays step milestones',
      // defaultColor: const Color(0xFF9D50DD),
      // ledColor: const Color(0xFF9D50DD),
      importance: NotificationImportance.Max,
      locked: true,
      playSound: true,
    ),
  ]);

  final messageStreamController = BehaviorSubject<RemoteMessage>();

  if (defaultTargetPlatform != TargetPlatform.iOS) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10,
          channelKey: 'step_milestone_channel',
          title: message.notification?.title,
          body: message.notification?.body,
        ),
      );

      messageStreamController.sink.add(message);
    });
  }

  messageStreamController.listen((message) {
    if (message.notification != null) {
      var lastMessage = 'Received a notification message:'
          '\nTitle=${message.notification?.title},'
          '\nBody=${message.notification?.body},'
          '\nData=${message.data}';
      if (message.data.containsKey('image')) {
        // handle the image data here
        String imageUrl = message.data['image'];
      }
    } else {
      var lastMessage = 'Received a data message: ${message.data}';
    }
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  runApp(MyApp(
      initialRoute:
          userId != null ? HealthDataScreen.routeName : SignInScreen.routeName,
      userId: userId));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String? userId;

  const MyApp({Key? key, required this.initialRoute, this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SignInScreen(),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        HealthDataScreen.routeName: (context) {
          final userId =
              ModalRoute.of(context)!.settings.arguments ?? this.userId;
          return HealthDataScreen(userId: userId is String ? userId : null);
        },
        SignInScreen.routeName: (context) => const SignInScreen(),
      },
    );
  }
}
