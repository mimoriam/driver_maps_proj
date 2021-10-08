import 'package:driver_maps_proj/screens/home_screen.dart';
import 'package:flutter/material.dart';

// State:

// Screens:

// Models:

// Services:
import '../services/auth.dart';

// Firebase stuff:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom:
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'non_login_home_screen.dart';

class LoginPage extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const LoginPage({
    required this.auth,
    required this.firestore,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: Builder(
            builder: (BuildContext context) {
              return SingleChildScrollView(
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        child: const Text("Click here to check the map routes!"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NonLoginHomePage(auth: _auth, firestore: _firestore),
                            ),
                          );
                        },
                      ),
                      FormBuilderTextField(
                        name: 'email',
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(context),
                          FormBuilderValidators.email(context),
                          FormBuilderValidators.minLength(context, 6),
                        ]),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          labelStyle: const TextStyle(),
                        ),
                      ),
                      FormBuilderTextField(
                        name: 'password',
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(context),
                          FormBuilderValidators.minLength(context, 6),
                        ]),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          labelStyle: const TextStyle(),
                        ),
                      ),
                      ElevatedButton(
                        child: const Text("Sign In"),
                        onPressed: () async {
                          final String? returnValue = await Auth(auth: widget.auth).signIn(
                            email: _formKey.currentState!.fields['email']!.value,
                            password: _formKey.currentState!.fields['password']!.value,
                          );
                          if (returnValue == "Success") {
                            _formKey.currentState?.reset();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyHomePage(auth: _auth, firestore: _firestore),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(returnValue!),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
