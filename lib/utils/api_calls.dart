import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

HealthFactory health = HealthFactory();
Future<Map<String, dynamic>> fetchHealthData(String userId) async {
  Map<String, dynamic> healthDataResults = {
    'totalSteps': 0,
    'totalDistance': 0.0,
    'totalCaloriesBurned': 0.0,
  };

  try {
    // Check if the user is signed in
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception(
          "User not signed in. Please sign in to fetch health data.");
    }

    // Ensure activity recognition permission is granted
    if (!(await Permission.activityRecognition.isGranted)) {
      throw Exception("Activity recognition permission not granted");
    }

    // Define health data types to fetch
    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_DELTA,
    ];

    // Fetch health data
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      DateTime.now(),
      types,
    );

    // Calculate health data metrics
    healthDataResults['totalSteps'] = await calculateTotalSteps(healthData);
    healthDataResults['totalDistance'] =
        await calculateTotalDistance(healthData);
    healthDataResults['totalCaloriesBurned'] =
        await calculateTotalCaloriesBurned(healthData);

    // Save health data to local storage
    await saveUserData(healthDataResults);
  } catch (e, stackTrace) {
    // Handle errors
    print("Error fetching health data: $e");
    print("Stack trace: $stackTrace");
    healthDataResults['error'] = 'Error fetching health data: $e';
  }

  return healthDataResults;
}

Future<void> saveUserData(Map<String, dynamic> healthDataResults) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int totalSteps = await healthDataResults['totalSteps'];
  double totalDistance = await healthDataResults['totalDistance'];
  prefs.setInt('totalSteps', totalSteps);
  prefs.setDouble('totalDistance', totalDistance);
  prefs.setDouble(
      'totalCaloriesBurned', healthDataResults['totalCaloriesBurned']);
}

Future<void> initPedometer(
    Function onStepCount, Function isStillMounted) async {
  Pedometer.pedestrianStatusStream.listen((event) {});
  Pedometer.stepCountStream.listen((event) {
    if (isStillMounted()) {
      onStepCount(event);
    }
  });
}

Future<void> saveStepCountToFirestore(String userID, int stepCount) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference docRef =
        firestore.collection('userID_tokens').doc(userID);
    await docRef.set({'totalSteps': stepCount}, SetOptions(merge: true));
  } catch (e) {
    rethrow;
  }
}

Future<int> calculateTotalSteps(List<HealthDataPoint> healthData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int totalSteps = prefs.getInt('totalSteps') ?? 0;

  for (var dataPoint in healthData) {
    if (dataPoint.type == HealthDataType.STEPS) {
      totalSteps += dataPoint.value as int;
    }
  }
  await prefs.setInt('totalSteps', totalSteps);
  return totalSteps;
}

Future<double> calculateTotalDistance(List<HealthDataPoint> healthData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double strideLengthInMeters = 0.698;
  int steps = prefs.getInt('totalSteps') ?? 0;

  double totalDistance = (steps * strideLengthInMeters) / 1000;
  totalDistance = double.parse(totalDistance.toStringAsFixed(2));

  await prefs.setDouble('totalDistance', totalDistance);
  return totalDistance;
}

Future<double> calculateTotalCaloriesBurned(
    List<HealthDataPoint> healthData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int steps = prefs.getInt('totalSteps') ?? 0;

  double totalCaloriesBurned = steps / 22.0;
  totalCaloriesBurned = double.parse(totalCaloriesBurned.toStringAsFixed(2));

  return totalCaloriesBurned;
}

Future<void> resetValuesAtMidnight() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime lastReset =
      DateTime.parse(prefs.getString('lastReset') ?? '2000-01-01');
  DateTime today = DateTime.now();
  DateTime todayMidnight = DateTime(today.year, today.month, today.day);

  if (lastReset.isBefore(todayMidnight)) {
    prefs.setInt('totalSteps', 0);
    prefs.setDouble('totalDistance', 0.0);
    prefs.setDouble('totalCaloriesBurned', 0.0);
    prefs.setString('lastReset', todayMidnight.toIso8601String());
  } else {
    if (kDebugMode) {
      print('Values have already been reset for today.');
    }
  }
}

void startResetTimer() {
  Timer.periodic(const Duration(minutes: 1), (Timer t) async {
    DateTime now = DateTime.now();

    if (now.hour == 0 && now.minute == 0) {
      await resetValuesAtMidnight();
    }
  });
}
