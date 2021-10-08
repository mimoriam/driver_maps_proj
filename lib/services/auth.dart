// State:

// Screens:

// Models:

// Services:

// Firebase stuff:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom:
import 'package:flutter/foundation.dart';

class Auth {
  final FirebaseAuth auth;

  Auth({required this.auth});

  Stream<User?> get user => auth.authStateChanges();

  Future<String?> createAccount(
      {required String displayName, required String email, required String password}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (!auth.currentUser!.emailVerified) {
        await auth.currentUser!.sendEmailVerification();
      }

      // saveUserToDB(displayName: displayName, provider: 'email');
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        print('Invalid email.');
      }
      return "Error";
    } catch (e) {
      print(e);
      return "Error";
    }
  }

  /* signIn provider returns the following data:
  User(displayName: null, email: test1@test.com, emailVerified: false, isAnonymous: false,
  metadata: UserMetadata(creationTime: 2021-05-19 19:54:42.010, lastSignInTime: 2021-05-19 19:54:42.010), phoneNumber: null, photoURL: null,
  providerData,
  [UserInfo(displayName: null, email: test1@test.com, phoneNumber: null, photoURL: null, providerId: password, uid: test1@test.com)],
  refreshToken: , tenantId: null, uid: t5m0tmuUUaZIOHsqGDRBGA6xdnZ2)
   */

  Future<String?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (!auth.currentUser!.emailVerified) {
        await auth.currentUser!.sendEmailVerification();
      }

      // saveUserToDB(provider: 'email');
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      } else if (e.code == 'invalid-email') {
        print('Invalid email.');
      }
      return e.message;
    }
  }

/* Google Provider returns the following data:
User(displayName: Sophisticated Hum, email: mimoriam420@gmail.com, emailVerified: true, isAnonymous: false,
metadata: UserMetadata(creationTime: 2021-05-13 12:30:04.379, lastSignInTime: 2021-05-18 16:36:48.940),
phoneNumber: , photoURL: https://lh3.googleusercontent.com/a-/AOh14GhXuM1gnjfjTmiFAgRoBNRY09YcsgwWlUrnfDoq=s96-c,
providerData,
[UserInfo(displayName: Sophisticated Hum, email: mimoriam420@gmail.com, phoneNumber: , photoURL: https://lh3.googleusercontent.com/a-/AOh14GhXuM1gnjfjTmiFAgRoBNRY09YcsgwWlUrnfDoq=s96-c, providerId: google.com, uid: 106325065002315642440)],
refreshToken: , tenantId: null, uid: IbWPRZjnI6bUkJb2MarPqlZgV2R2)
 */

  // Future<void> signInWithGoogle() async {
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //
  //   final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  //   UserCredential userCredential;
  //
  //   if (kIsWeb) {
  //     var googleProvider = GoogleAuthProvider();
  //     userCredential = await auth.signInWithPopup(googleProvider);
  //   } else {
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     userCredential = await auth.signInWithCredential(credential);
  //   }
  //
  //   saveUserToDB(provider: 'google');
  // }

  Future<String?> signOut() async {
    try {
      await auth.signOut();
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({required String email}) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<String?> deleteAccount() async {
    if (auth.currentUser != null) {
      try {
        await FirebaseAuth.instance.currentUser!.delete();

        return "Success";
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          print('The user must re-authenticate before this operation can be executed.');
        }
      }
    } else {
      return "You must be logged in first!";
    }
  }
}

// Future<void> saveUserToDB({String? displayName, required String provider}) async {
//   FirebaseAuth auth = FirebaseAuth.instance;
//   CollectionReference<Map<String, dynamic>> users = FirebaseFirestore.instance.collection('users');
//
//   if (provider == "google") {
//     var userData = {
//       'name': auth.currentUser!.displayName,
//       'provider': 'google',
//       'photoURL': auth.currentUser?.photoURL,
//       'email': auth.currentUser!.email,
//       'emailVerified': true,
//       'metadata': {
//         "creationTime": auth.currentUser!.metadata.creationTime,
//         "lastSignInTime": auth.currentUser!.metadata.lastSignInTime
//       },
//     };
//
//     users.doc(auth.currentUser!.uid).get().then(
//           (DocumentSnapshot<Map<String, dynamic>> documentSnapshot) async {
//         if (documentSnapshot.exists) {
//           print("Document exists on the DB! Updating...");
//           await documentSnapshot.reference.update(userData);
//         } else {
//           print("Document doesn't exist on the DB! Adding...");
//           await documentSnapshot.reference.set(userData);
//         }
//       },
//     );
//   } else if (provider == "email") {
//     if (displayName != null) {
//       // SharedPreferences prefs = await SharedPreferences.getInstance();
//       // prefs.setString("name", displayName);
//
//       auth.currentUser!.updateProfile(displayName: displayName);
//
//       var userData = {
//         'name': auth.currentUser!.displayName,
//         'provider': 'email',
//         'photoURL': auth.currentUser?.photoURL,
//         'email': auth.currentUser!.email,
//         'emailVerified': auth.currentUser!.emailVerified,
//         'metadata': {
//           "creationTime": auth.currentUser!.metadata.creationTime,
//           "lastSignInTime": auth.currentUser!.metadata.lastSignInTime
//         },
//       };
//       users.doc(auth.currentUser!.uid).get().then(
//             (DocumentSnapshot<Map<String, dynamic>> documentSnapshot) async {
//           if (documentSnapshot.exists) {
//             print("Document exists on the DB! Updating...");
//             await documentSnapshot.reference.update(userData);
//           } else {
//             print("Document doesn't exist on the DB! Adding...");
//             await documentSnapshot.reference.set(userData);
//           }
//         },
//       );
//     } else {
//       var userData = {
//         'name': auth.currentUser!.displayName,
//         'provider': 'email',
//         'photoURL': auth.currentUser?.photoURL,
//         'email': auth.currentUser!.email,
//         'emailVerified': auth.currentUser!.emailVerified,
//         'metadata': {
//           "creationTime": auth.currentUser!.metadata.creationTime,
//           "lastSignInTime": auth.currentUser!.metadata.lastSignInTime
//         },
//       };
//       users.doc(auth.currentUser!.uid).get().then(
//             (DocumentSnapshot<Map<String, dynamic>> documentSnapshot) async {
//           if (documentSnapshot.exists) {
//             print("Document exists on the DB! Updating...");
//             await documentSnapshot.reference.update(userData);
//           } else {
//             print("Document doesn't exist on the DB! Adding...");
//             await documentSnapshot.reference.set(userData);
//           }
//         },
//       );
//     }
//   } else {}
// }