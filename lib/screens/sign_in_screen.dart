import 'package:background_services/screens/health_screen.dart';
import 'package:background_services/utils/api_calls.dart';
import 'package:background_services/utils/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  static const routeName = '/sign-in-screen';

  const SignInScreen({super.key});
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleSignIn() async {
    String? userId = await signInWithGoogle(_googleSignIn, fetchHealthData);
    if (userId != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      Navigator.popAndPushNamed(context, HealthDataScreen.routeName,
          arguments: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/leafy_background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Welcome to Health Steps',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50.0),
                Image.asset('assets/images/google_health_logo.png',
                    height: 150.0),
                const SizedBox(height: 50.0),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 12.0),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  onPressed: _handleSignIn,
                  child: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
