import 'package:flutter/material.dart';
import 'dart:async';

// State:
import 'package:provider/provider.dart';
import 'package:driver_maps_proj/state/theme_state.dart';

// Screens:
import 'package:driver_maps_proj/screens/mymap.dart';

// Models:

// Services:
import 'package:driver_maps_proj/services/auth.dart';

// Firebase stuff:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom:
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

// Entry Point:
class MyHomePage extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const MyHomePage({required this.auth, required this.firestore});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    _requestPermission();
    location.changeSettings(interval: 300, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
    super.initState();
  }

  void _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc(widget.auth.currentUser!.email).set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': widget.auth.currentUser!.displayName
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance.collection('location').doc(widget.auth.currentUser!.email).set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': widget.auth.currentUser!.displayName
      }, SetOptions(merge: true));
    });
  }

  void _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  void _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
          actions: [
            IconButton(
              onPressed: () async {
                final String? returnValue = await Auth(auth: widget.auth).signOut();
                if (returnValue == "Success") {}
              },
              icon: const Icon(Icons.add_to_home_screen),
            )
          ],
        ),
        body: Column(
          children: [
            TextButton(
              onPressed: () {
                _getLocation();
              },
              child: const Text('Add location'),
            ),
            TextButton(
              onPressed: () {
                _listenLocation();
              },
              child: const Text('Enable live location'),
            ),
            TextButton(
              onPressed: () {
                _stopListening();
              },
              child: const Text("Stop live location"),
            ),
            Expanded(
                child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('location').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data!.docs[index]['name'].toString()),
                        subtitle: Row(
                          children: [
                            Text(snapshot.data!.docs[index]['latitude'].toString()),
                            const SizedBox(
                              width: 20,
                            ),
                            Text(snapshot.data!.docs[index]['longitude'].toString()),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => MyMap(snapshot.data!.docs[index].id)));
                          },
                        ),
                      );
                    });
              },
            )),
          ],
        ));
  }
}
