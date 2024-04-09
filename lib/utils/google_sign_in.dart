import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> signInWithGoogle(
    GoogleSignIn googleSignIn, Function fetchHealthData) async {
  try {
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount == null) {
      // User canceled the sign-in process
      return null;
    }

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final String? userId = userCredential.user?.uid;

    if (userId != null && userId.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      fetchHealthData(userId); 
    }

    return userId;
  } catch (error) {
    print("Error signing in with Google: $error");
    return null;
  }
}
