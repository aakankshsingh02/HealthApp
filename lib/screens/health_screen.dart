import 'package:background_services/utils/api_calls.dart';
import 'package:background_services/utils/notifications.dart';
import 'package:background_services/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthDataScreen extends StatefulWidget {
  static const routeName = '/health-screen';
  final String? userId;
  const HealthDataScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  HealthFactory health = HealthFactory();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool isLoading = true;
  int totalSteps = 0;
  double totalDistance = 0.0;
  double totalCaloriesBurned = 0.0;
  late String? userId;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initNotifications();
    initFirebaseMessaging();
    userId = widget.userId;
    fetchHealthData(userId!).then((healthDataResults) async {
      int totalSteps = await healthDataResults['totalSteps'];
      double totalDistance = await healthDataResults['totalDistance'];
      double totalCaloriesBurned =
          await healthDataResults['totalCaloriesBurned'];
      String? error = healthDataResults['error']; // Get the error message

      if (error != null) {
        setState(() {
          errorMessage = error; // Set errorMessage if error occurred
          isLoading = false;
          print({
            "isLoading = false",
          });
        });
      } else {
        setState(() {
          this.totalSteps = totalSteps;
          this.totalDistance = totalDistance;
          this.totalCaloriesBurned = totalCaloriesBurned;
          isLoading = false;
        });
      }
    });
    _initPedometer();
    _loadTotalSteps();
  }

  void onStepCount(StepCount event) {
    if (mounted) {
      setState(() {
        totalSteps = event.steps;
      });
    }

    _saveTotalSteps();

    if (event.steps % 100 == 0) {
      showNotification(flutterLocalNotificationsPlugin, event.steps.toString());
      saveStepCountToFirestore(userId!, totalSteps);
    }
  }

  void _saveTotalSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('totalSteps', totalSteps);
  }

  void _initPedometer() {
    initPedometer(onStepCount, () => mounted);
  }

  void _loadTotalSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        totalSteps = prefs.getInt('totalSteps') ?? 0;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    Pedometer.stepCountStream.drain();
    Pedometer.pedestrianStatusStream.drain();
    _initPedometer();
    _loadTotalSteps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/leafy_background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text(
          'Health Data',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/leafy_background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.green,
              ))
            : errorMessage != null
                ? buildErrorWidget(context)
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildCard(
                          'Total Steps',
                          '$totalSteps',
                          Icons.directions_walk,
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        buildCard(
                          'Total Distance',
                          '$totalDistance km',
                          Icons.directions_run,
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        buildCard(
                          'Total Calories Burned',
                          '$totalCaloriesBurned',
                          Icons.fireplace,
                        ),
                        const SizedBox(height: 20),
                        const LogoutButton(
                            routeNameAfterLogout: '/sign-in-screen')
                      ],
                    ),
                  ),
      ),
    );
  }
}
