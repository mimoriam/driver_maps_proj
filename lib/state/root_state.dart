import 'package:flutter/material.dart';

// State:

// Screens:
import 'package:driver_maps_proj/screens/home_screen.dart';
import 'package:driver_maps_proj/screens/login_screen.dart';

// Models:

// Services:
import 'package:driver_maps_proj/services/auth.dart';

// Firebase stuff:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom:
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Global state via provider resides here:
class RootStateProvider extends ChangeNotifier {
  String name = "Null";

  void changeNames(String n) async {
    name = n;
    notifyListeners();
  }

}

class Root extends StatefulWidget {
  const Root({Key? key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth(auth: _auth).user,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          print(snapshot.data);

          // If user's Id == null, go to Login Page, otherwise Home:
          if (snapshot.data?.uid == null) {
            return LoginPage(
              auth: _auth,
              firestore: _firestore,
            );
          } else {
            return MyHomePage(
              auth: _auth,
              firestore: _firestore,
            );
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
