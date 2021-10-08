import 'package:driver_maps_proj/state/root_state.dart';
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
  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    await _requestPermission();
    location.changeSettings(interval: 300, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
    super.didChangeDependencies();
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('TextField in Dialog'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  Provider.of<RootStateProvider>(context).changeNames(value);
                });
              },
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Text Field in Dialog"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
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

  Future<void> _requestPermission() async {
    // var status = await Permission.location.request();
    if (await Permission.location.request().isGranted) {
      print("DONE!!!!!");
    } else if (await Permission.location.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (Provider.of<RootStateProvider>(context).name == "Null" ||
    //     Provider.of<RootStateProvider>(context).name == "null") {
    //   Future.delayed(Duration.zero, () => _displayTextInputDialog(context));
    // }
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
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: FormBuilder(
          //     key: _formKey,
          //     child: FormBuilderTextField(
          //       name: 'NAME',
          //       decoration: InputDecoration(
          //         labelText: Provider.of<RootStateProvider>(context).name,
          //         border: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(20.0),
          //         ),
          //         labelStyle: const TextStyle(),
          //       ),
          //     ),
          //   ),
          // ),
          // ElevatedButton(
          //   child: const Text("Change names"),
          //   onPressed: () async {
          //     Provider.of<RootStateProvider>(context, listen: false)
          //         .changeNames(_formKey.currentState!.fields['NAME']!.value);
          //     await FirebaseFirestore.instance
          //         .collection('location')
          //         .doc(widget.auth.currentUser!.email)
          //         .update({'name': Provider.of<RootStateProvider>(context, listen: false).name});
          //     FocusScope.of(context).unfocus();
          //     _formKey.currentState!.reset();
          //   },
          // ),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
