import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grocery_mule/dev/collection_references.dart';
import 'package:grocery_mule/providers/cowboy_provider.dart';
import 'package:grocery_mule/providers/shopping_trip_provider.dart';
import 'package:grocery_mule/screens/createlist.dart';
import 'package:grocery_mule/screens/email_reauth.dart';
import 'package:grocery_mule/screens/friend_screen.dart';
import 'package:grocery_mule/screens/user_info.dart';
import 'package:grocery_mule/screens/welcome_screen.dart';
import 'package:grocery_mule/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import 'editlist.dart';

class UserName extends StatefulWidget {
  late final String userUUID;
  UserName(String userUUID) {
    this.userUUID = userUUID;
  }

  @override
  _UserNameState createState() => _UserNameState();
}

class _UserNameState extends State<UserName> {
  late String userUUID;
  @override
  void initState() {
    userUUID = widget.userUUID;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: userCollection.doc(userUUID).snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return Text('Howdy ${snapshot.data!['first_name']}!',
              style: TextStyle(fontSize: 25, color: Colors.black));
        });
  }
}

class ListsScreen extends StatefulWidget {
  final _auth = FirebaseAuth.instance;
  final User? curUser = FirebaseAuth.instance.currentUser;
  static String id = 'lists_screen';

  @override
  _ListsScreenState createState() => _ListsScreenState();
}

class ShoppingTripQuery extends StatefulWidget {
  final _auth = FirebaseAuth.instance;
  late String listUUID;

  ShoppingTripQuery(String listUUID, {required Key key}) : super(key: key) {
    this.listUUID = listUUID;
  }

  @override
  _ShoppingTripQueryState createState() => _ShoppingTripQueryState();
}

class _ShoppingTripQueryState extends State<ShoppingTripQuery> {
  late String listUUID;

  @override
  void initState() {
    listUUID = widget.listUUID;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return StreamBuilder<DocumentSnapshot>(
        stream: tripCollection.doc(listUUID).snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(
              elevation: 10,
              color: appColor,
              shadowColor: appOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              child: ListTile(
                title: Container(
                  child: Text(
                    'Loading Title...',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                    ),
                  ),
                ),
                subtitle: Row(children: [
                  Text(
                    'Loading Info...\n\n',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                ]),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditListScreen(listUUID)));
                },
                isThreeLine: true,
              ),
            );
          }
          if (snapshot.data!.data() != null) {
            String desc_short = snapshot.data!['description'];
            String title_short = snapshot.data!['title'];
            if (title_short.length > 30) {
              title_short = title_short.substring(0, 11) + "...";
            }
            if (desc_short.length > 50) {
              desc_short = desc_short.substring(0, 11) + "...";
            }

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
              child: Card(
                elevation: 10,
                color: appColor,
                shadowColor: appOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  title: Container(
                    child: Text(
                      '${title_short}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  subtitle: Row(children: [
                    Text(
                      '${desc_short}\n\n'
                              '${(snapshot.data!['date'] as Timestamp).toDate().month}' +
                          '/' +
                          '${(snapshot.data!['date'] as Timestamp).toDate().day}' +
                          '/' +
                          '${(snapshot.data!['date'] as Timestamp).toDate().year}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                  ]),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditListScreen(listUUID)));
                  },
                  isThreeLine: true,
                ),
              ),
            );
          }
          return Container();
        });
  }
}

class _ListsScreenState extends State<ListsScreen> {
  final _auth = FirebaseAuth.instance;
  final User? curUser = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> personalTrip =
      userCollection.doc(curUser!.uid).snapshots();
  Future<void>? Cowsnapshot;
  List<String> dev = [
    "ZzIAu0Hqzoa0YDerS408uZN5lrf1", // harra
    "GqZ1wHAr3aUPTlz2Z3IkqS3vsk52", // praffa
    "W9J3qDwNQgSBbsDvyT6RZtvbm572", // dhruva
  ];
  @override
  void initState() {
    Cowsnapshot = _loadCurrentCowboy();
    super.initState();
  }

  Future<void> _loadCurrentCowboy() async {
    final DocumentSnapshot<Object?>? snapshot =
        await (_queryCowboy() as Future<DocumentSnapshot<Object?>?>);
    readInData(snapshot!);
    // final Stream<QuerySnapshot<Map<String, dynamic>>> tripstream = userCollection.doc(context.read<Cowboy>().uuid).collection('shopping_trips').snapshots();
  }

  void readInData(DocumentSnapshot snapshot) {
    List<String> shoppingTrips = [];

    List<String> friends = [];
    List<String> requests = [];
    // extrapolating data into provider
    if (!(snapshot['friends'] as List<dynamic>).isEmpty) {
      (snapshot['friends'] as List<dynamic>).forEach((dynamicKey) {
        friends.add(dynamicKey.toString());
      });
    }
    if (!(snapshot['requests'] as List<dynamic>).isEmpty) {
      (snapshot['requests'] as List<dynamic>).forEach((key) {
        requests.add(key.toString().trim());
      });
    }

    // reads and calls method
    context.read<Cowboy>().fillFields(
        snapshot['uuid'].toString(),
        snapshot['first_name'].toString(),
        snapshot['last_name'].toString(),
        snapshot['email'].toString(),
        shoppingTrips,
        friends,
        requests);
    //print(context.read<Cowboy>().shoppingTrips);
  }

  Future<DocumentSnapshot?> _queryCowboy() async {
    if (curUser != null) {
      DocumentSnapshot? tempShot;
      await userCollection.doc(curUser!.uid).get().then((docSnapshot) {
        tempShot = docSnapshot;

        //print('L TYPE: '+docSnapshot.data['']);
      });
      return tempShot;
    } else {
      return null;
    }
  }

  List<String> readInShoppingTripsData(QuerySnapshot tripshot) {
    List<String> shopping_trips = [];
    if (tripshot.docs == null || tripshot.docs.isEmpty) {
      return [];
    }
    tripshot.docs.forEach((element) {
      if (element.id != 'dummy') {
        shopping_trips.add(element.id.trim());
      }
    });
    context.read<Cowboy>().setTrips(shopping_trips);
    return shopping_trips;
  }

  // delete trip from shopping trip collection of all users from current trip
  Future<void> deleteHostTrip(DocumentSnapshot curTrip) async {
    List<dynamic> trip_benes = curTrip["beneficiaries"];
    print("trip benes: " + trip_benes.toString());

    // delete trip items, including dummy, tax, add.fees
    QuerySnapshot items =
        await tripCollection.doc(curTrip["uuid"]).collection('items').get();
    items.docs.forEach((doc) async {
      print(doc["name"]);
      await tripCollection
          .doc(curTrip["uuid"])
          .collection('items')
          .doc(doc["uuid"])
          .delete();
    });

    // remove trip reference for each bene
    trip_benes.forEach((user_uuid) async {
      await userCollection
          .doc(user_uuid)
          .collection('shopping_trips')
          .doc(curTrip["uuid"])
          .delete();
    });
    // delete list document
    await tripCollection.doc(curTrip["uuid"]).delete();
  }

  void deleteBeneTrip(DocumentSnapshot curTrip) async {
    QuerySnapshot items =
        await tripCollection.doc(curTrip["uuid"]).collection('items').get();
    items.docs.forEach((item) async {
      if (item.id != 'add. fees' && item.id != 'tax') {
        DocumentSnapshot subitem = await tripCollection
            .doc(curTrip["uuid"])
            .collection('items')
            .doc(item.id)
            .get();
        Map<String, dynamic> subitems = {};
        (subitem['subitems'] as Map<String, dynamic>).forEach((uid, value) {
          subitems[uid] = int.parse(value.toString());
        });
        print(subitems);
        subitems.remove(curUser!.uid);
        print(subitems);
        await tripCollection
            .doc(curTrip["uuid"])
            .collection('items')
            .doc(item.id)
            .update({'subitems': subitems});
      }
    });
    await tripCollection.doc(curTrip["uuid"]).update({
      'beneficiaries': FieldValue.arrayRemove([curUser!.uid])
    });
  }

  Future<void> removeFriends() async {
    context.read<Cowboy>().friends.forEach((friend_uuid) async {
      await userCollection.doc(friend_uuid).update({
        'friends': FieldValue.arrayRemove([curUser!.uid])
      });
    });
  }

  Future<void> deleteUser() async {
    QuerySnapshot UserTrips = await userCollection
        .doc(curUser!.uid)
        .collection('shopping_trips')
        .get();
    UserTrips.docs.forEach((trip) async {
      await userCollection
          .doc(curUser!.uid)
          .collection('shopping_trips')
          .doc(trip.id)
          .delete();
    });
    userCollection.doc(curUser!.uid).delete();
    Navigator.of(context).popUntil((route) {
      return route.settings.name == WelcomeScreen.id;
    });
    Navigator.pushNamed(context, WelcomeScreen.id);
    context.read<Cowboy>().clearData();
  }

  Future<void> deleteAccountTrips() async {
    QuerySnapshot trips = await userCollection
        .doc(curUser!.uid)
        .collection("shopping_trips")
        .get();
    trips.docs.forEach((trip) async {
      DocumentSnapshot doc = await tripCollection.doc(trip.id).get();
      if (doc["host"] == curUser!.uid) {
        print("HOST of: " + doc["title"]);
        deleteHostTrip(doc);
      } else {
        print("BENE of: " + doc["title"]);
        deleteBeneTrip(doc);
      }
    });
    await removeFriends();
    deleteUser();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> reauthUser() async {
    String curProviderID = FirebaseAuth
        .instance.currentUser!.providerData[0].providerId
        .toString();
    if (curProviderID == "google.com") {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // Obtain the auth details from the request.
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      // Create a new credential.
      final OAuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(googleCredential);
    } else if (curProviderID == "password") {
      Navigator.pushNamed(context, ReauthScreen.id);
    } else if (curProviderID == "apple.com") {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(oauthCredential);
    }
  }

  @override
  Widget build(BuildContext context) {
    //print(context.watch<Cowboy>().shoppingTrips);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: UserName(curUser!.uid),
          backgroundColor: appOrange,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
          ),
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          elevation: 0,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: appOrange,
                ),
                child: Text(
                  'Menu Options',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              // Text(context.watch<Cowboy>().first_name),
              ListTile(
                title: const Text('Cowamigos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, FriendScreen.id);
                },
              ),
              ListTile(
                title: const Text('Edit Profile'),
                onTap: () {
                  //Navigator.pop(context);
                  Navigator.pushNamed(context, UserInfoScreen.id);
                },
              ),
              ListTile(
                title: const Text('Report a 🐞'),
                onTap: () async {
                  Fluttertoast.showToast(
                      msg: 'Google Sign in required to upload bug report');
                  String paypalStr = "https://forms.gle/xHy3ixadwacFuFMi9";
                  Uri paypal_link = Uri.parse(paypalStr);
                  if (await canLaunchUrl(paypal_link)) {
                    launchUrl(paypal_link);
                  }
                },
              ),
              ListTile(
                title: const Text('Feature Request'),
                onTap: () async {
                  String paypalStr =
                      "https://docs.google.com/forms/d/e/1FAIpQLSf7gVxRoyMq0C8tuLMdnw4T2hxr8LUgIbZFFWQv2sJFSafndg/viewform";
                  Uri paypal_link = Uri.parse(paypalStr);
                  if (await canLaunchUrl(paypal_link)) {
                    launchUrl(paypal_link);
                  }
                },
              ),
              ListTile(
                title: const Text('Log Out'), //
                onTap: () async {
                  var currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    //clearUserField();
                    context.read<Cowboy>().clearData();
                    context.read<ShoppingTrip>().clearField();
                    await _auth.signOut();
                    print('User signed out');
                  }
                  //Navigator.pop(context);
                  Navigator.of(context).popUntil((route) {
                    return route.settings.name == WelcomeScreen.id;
                  });
                  Navigator.pushNamed(context, WelcomeScreen.id);
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                onTap: () async {
                  String ppstr = "https://grocerymule.net/privacy.html";
                  Uri pp_link = Uri.parse(ppstr);
                  if (await canLaunchUrl(pp_link)) {
                    launchUrl(pp_link);
                  }
                },
              ),
              ListTile(
                title: const Text('Delete Account'),
                onTap: () async {
                  return showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete your account?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () async {
                                try {
                                  // await reauthUser();
                                  await deleteAccountTrips();
                                  await FirebaseAuth.instance.currentUser!
                                      .delete();
                                  // print(context.read<Cowboy>().uuid),
                                  Navigator.of(context).pop();
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'requires-recent-login') {
                                    // print('The user must reauthenticate before this operation can be executed.');
                                    print("reauth failed");
                                  }
                                }
                                // deleteAccountTrips(),
                                // Navigator.of(context).pop(),
                              },
                              child: const Text("DELETE")),
                          TextButton(
                            onPressed: () => {
                              Navigator.of(context).pop(),
                            },
                            child: const Text("CANCEL"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Object?>>(
            stream: userCollection
                .doc(curUser!.uid)
                .collection('shopping_trips')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong StreamBuilder');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              return SafeArea(
                child: ListView.builder(
                  //scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, int index) {
                    return new ShoppingTripQuery(
                        snapshot.data!.docs.toList()[index].id,
                        key: Key(snapshot.data!.docs.toList()[index].id));
                  },
                ),
                // ),
              );
            }),
        floatingActionButton: Container(
          height: 80,
          width: 80,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            backgroundColor: appOrange,
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateListScreen(true, "dummy")));
            },
          ),
        ),
      ),
    );
  }
}
