import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutButton extends StatelessWidget {
  final String routeNameAfterLogout;

  const LogoutButton({Key? key, required this.routeNameAfterLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      label: const Text(
        'Logout',
        style: TextStyle(color: Colors.white),
      ),
      icon: const Icon(
        Icons.logout,
        color: Colors.white,
      ),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove('userId');
        GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        Navigator.pushReplacementNamed(context, routeNameAfterLogout);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }
}

//error widget

Widget buildErrorWidget(BuildContext context) {
  return const SizedBox(
    width: double.infinity,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "THIS IS A TESTING APP!",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.0),
        Text(
          'Ask admin to give you testing permission.',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.0),
        LogoutButton(routeNameAfterLogout: '/sign-in-screen')
      ],
    ),
  );
}

// Health Data Cards

Widget buildCard(String title, String value, IconData icon) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    elevation: 5,
    color: Colors.white,
    child: ListTile(
      leading: Icon(
        icon,
        color: Colors.black,
        size: 40.0,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
