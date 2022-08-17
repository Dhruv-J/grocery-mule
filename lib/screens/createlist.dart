import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_mule/components/header.dart';
import 'package:grocery_mule/constants.dart';
import 'package:grocery_mule/dev/db_ops.dart';
import 'package:grocery_mule/providers/cowboy_provider.dart';
import 'package:grocery_mule/screens/editlist.dart';
import 'package:grocery_mule/screens/lists.dart';
import 'package:grocery_mule/theme/colors.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../components/text_buttons.dart';
import '../components/text_fields.dart';
import '../theme/text_styles.dart';

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
  late String name;

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
          name = snapshot.data!['first_name'];
          return Text(
            '${snapshot.data!['first_name']} ',
            style: TextStyle(fontSize: 20, color: Colors.red),
          );
        });
  }

  String getName() {
    return name;
  }
}

class CreateListScreen extends StatefulWidget {
  final _auth = FirebaseAuth.instance;
  static String id = 'create_list_screen';

  late String tripUUID;
  String title = '';
  String description = '';
  DateTime date = DateTime.utc(1969, 7, 20); // moon landing date as a checker
  List<String> beneficiaries = [];
  bool newList = false;

  //createList has the ids
  //when createList has a list that's already filled
  //keep a field of the original id, but generate a new id
  //in the return variable
  CreateListScreen(bool newList, String tripUuid) {
    this.tripUUID = tripUuid;
    if(tripUuid=='dummy') {
      this.newList = true;
    }
  }

  @override
  _CreateListScreenState createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  TextEditingController _tripTitleController = TextEditingController();
  TextEditingController _tripDescriptionController = TextEditingController();
  final String hostUUID = FirebaseAuth.instance.currentUser!.uid;

  bool isAdd = false;
  bool delete_list = false;
  bool invite_guest = false;
  bool tripCreated = false;

  List<String> addedBeneficiaries = [];
  List<String> removedBeneficiaries = [];
  Map<String, String> friendsName = {};

  late Future<DocumentSnapshot> tripFuture;

  @override
  void initState() {
    tripFuture = tripDocSnapshot(widget.tripUUID);
    _tripTitleController = TextEditingController(text: '');
    _tripDescriptionController = TextEditingController(text: '');
    if (widget.tripUUID == "dummy") {
      widget.date = DateTime.now();
    }
    super.initState();
  }

  Future<void> total_expenditure(String uid) async {
    double trip_total = 0;
    Map<String, double> total_per_user = {};
    widget.beneficiaries.forEach((uid) {
      total_per_user[uid] = 0;
    });
    QuerySnapshot items =
        await tripCollection.doc(uid).collection('items').get();
    items.docs.forEach((doc) {
      if (doc['uuid'] != 'tax' && doc['uuid'] != 'add. fees') {
        Map<String, dynamic> curSubitems = doc
            .get(FieldPath(['subitems'])); // get map of subitems for cur item
        double unit_price = doc['price'] / doc['quantity'];

        curSubitems.forEach((key, quantity) {
          // add item name & quantity if user UUIDs match & quantity > 0
          if (curSubitems[key] > 0) {
            total_per_user[key] = total_per_user[key]! + quantity * unit_price;
          }
        });
      } else {
        double unit_price =
            double.parse(doc['price'].toString()) / widget.beneficiaries.length;
        widget.beneficiaries.forEach((key) {
          total_per_user[key] = total_per_user[key]! + unit_price;
        });
      }
    });
    widget.beneficiaries.forEach((uid) async {
      DocumentSnapshot user = await userCollection.doc(uid).get();
      double cur_total = double.parse(user['total expenditure'].toString());
      cur_total += total_per_user[uid]!;
      await userCollection.doc(uid).update({
        'total expenditure': cur_total.toStringAsFixed(2),
      });
    });
    return;
  }

  void _loadTripFields(DocumentSnapshot tripSnapshot) {
    // if title hasn't been updated yet
    if (widget.title=='') {
      try {
        widget.title = getTitle(tripSnapshot);
        _tripTitleController = TextEditingController(text: widget.title);
      } catch(e) {
        print('error getting title: ${e.toString()}');
        widget.title = ' '; // space so that this doesn't keep getting called
      }
    }
    // if description hasn't been updated yet
    if (widget.description=='') {
      try {
        widget.description = getDescription(tripSnapshot);
        _tripDescriptionController = TextEditingController(text: widget.description);
      } catch(e) {
        print('error getting description: ${e.toString()}');
        widget.description = ' '; // space so that this doesn't keep getting called
      }
    }
    // if date hasn't been updated yet
    if (widget.date==DateTime.utc(1969, 7, 20)) {
      try {
        widget.date = getDate(tripSnapshot);
      } catch(e) {
        print('error getting date: ${e.toString()}');
        widget.date = DateTime.now(); // current date so that this doesn't keep getting called
      }
    }
    // if beneficiaries haven't been updated yet
    if (widget.beneficiaries.isEmpty) {
      try {
        widget.beneficiaries = getBeneficiaries(tripSnapshot);
      } catch(e) {
        print('error getting beneficiaries: ${e.toString()}');
        widget.beneficiaries = []; // leave empty in case no beneficiaries
      }
    }
  }

  Future<void> updateGridView(bool new_trip) async {
    if (new_trip) {
      widget.beneficiaries.add(hostUUID);
      // print('selected friends: ${widget.beneficiaries}');

      var tripId = Uuid().v4();
      widget.tripUUID = tripId;
      await context
          .read<Cowboy>()
          .addTrip(context.read<Cowboy>().uuid, tripId, widget.date);
      await tripCollection.doc(tripId).set({
        'uuid': tripId,
        'title': widget.title,
        'date': widget.date,
        'description': widget.description,
        'host': hostUUID,
        'beneficiaries': widget.beneficiaries,
        'lock': false,
      });
      await tripCollection
          .doc(tripId)
          .collection("items")
          .doc("tax")
          .set({'price': "0.00", 'uuid': 'tax', 'name': 'tax'});
      await tripCollection
          .doc(tripId)
          .collection("items")
          .doc("add. fees")
          .set({'price': "0.00", 'uuid': 'add. fees', 'name': 'add. fees'});
      widget.beneficiaries.remove(hostUUID);
      for (var friend in widget.beneficiaries) {
        context.read<Cowboy>().addTrip(friend, tripId, widget.date);
        //addTripToBene(String bene_uuid, String trip_uuid)
      }
      tripCreated = true;
    } else {
      removeBeneficiaries(removedBeneficiaries, widget.tripUUID);
      addBeneficiaries(addedBeneficiaries, widget.tripUUID, widget.date);

      tripCollection.doc(widget.tripUUID).update(
          {'title': widget.title, 'date': widget.date, 'description': widget.description});
      widget.beneficiaries.forEach((user) {
        userCollection
            .doc(user)
            .collection('shopping_trips')
            .doc(widget.tripUUID)
            .update({'date': widget.date});
      });
    }
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: widget.date,
        firstDate: DateTime(2022),
        lastDate: DateTime(2050),
        builder: (context, child) => Theme(
              data: ThemeData().copyWith(
                  colorScheme: ColorScheme.light(
                      primary: appOrange,
                      onPrimary: Colors.white,
                      onSurface: Colors.black)),
              child: child!,
            ));
    if (picked != null && picked != widget.date) {
      setState(() {
        // localTime = picked;
        widget.date = picked;
      });
      // print('local time after date pick: ${widget.date}');
    }
  }

  List<MultiSelectItem<String>> loadFriendsName(QuerySnapshot snapshot) {
    snapshot.docs.forEach((document) {
      friendsName[document['uuid']] = document['first_name'];
    });
    return friendsName.keys
        .toList()
        .map((uid) => MultiSelectItem<String>(uid, friendsName[uid]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: (widget.newList)
              ? const Text(
                  'Create List',
                  style: TextStyle(color: Colors.black),
                )
              : Text(
                  'List Settings',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
          ),
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: appOrange,
        ),
        body: FutureBuilder<DocumentSnapshot>(
            future: tripFuture,
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: const CircularProgressIndicator());
              }
              if (snapshot.data!.exists) {
                // _loadCurrentTrip(snapshot.data!);
                _loadTripFields(snapshot.data!);
                // print('LIST META GOTTEN:\n'
                //     'title: ${widget.title}\n'
                //     'description: ${widget.description}\n'
                //     'date: ${widget.date}\n'
                //     'beneficiaries: ${widget.beneficiaries}\n');
              }

              return Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    // friends card
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      color: appColorLight,
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: StreamBuilder<QuerySnapshot>(
                              stream: userCollection
                                  .where('friends',
                                      arrayContains:
                                          context.read<Cowboy>().uuid)
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text(
                                      'Something went wrong StreamBuilder');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                List<MultiSelectItem<String>> friends = [];
                                //print("first friend: ${snapshot.data!.docs[1].get('uuid')}");

                                snapshot.data!.docs.forEach((document) {
                                  friends.add(MultiSelectItem<String>(
                                      document['uuid'],
                                      document['first_name']));
                                });
                                // print('beneficiaries: ${widget.beneficiaries}');

                                return MultiSelectChipField(
                                  key: GlobalKey(),
                                  items: friends,
                                  initialValue: widget.beneficiaries,
                                  title: Text(
                                    'Friends',
                                    style: appFontStyle.copyWith(
                                        color: Colors.black),
                                  ),
                                  selectedChipColor: dark_beige,
                                  decoration: BoxDecoration(
                                    color: light_cream,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(22)),
                                  ),
                                  onTap: (results) {
                                    // print('new bene results: ${results.toList()}');
                                    // print('old bene results: ${widget.beneficiaries}');
                                    removedBeneficiaries.addAll(widget.beneficiaries.where((beneUUID)
                                      => !results.toList().contains(beneUUID)).toList());
                                    addedBeneficiaries.addAll(results.map((e) => e.toString()).toList().where((beneUUID)
                                      => !widget.beneficiaries.contains(beneUUID)).toList());
                                    print('added beneficiaries: $addedBeneficiaries');
                                    print('removed beneficiares: $removedBeneficiaries');
                                    widget.beneficiaries = results
                                        .map((e) => e.toString())
                                        .toList()
                                        .toSet()
                                        .toList();
                                    // print('updated benes: ${widget.beneficiaries}');
                                  },
                                );
                              }),
                        ),
                      ),
                    ),

                    // trip details
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HomeHeader(
                          title: "Trip Details",
                          color: appOrange,
                          textColor: Colors.white),
                    ),

                    // title editor
                    Row(
                      children: [
                        Expanded(
                          child: TextFields(
                            inSquare: false,
                            controller: _tripTitleController,
                            borderColor: appOrange,
                            context: context,
                            enabled: true,
                            focusColor: Colors.black,
                            helpText: "Trip Name",
                            hintText: "Title",
                            show: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.verified_user_outlined)),
                            icon: Tab(icon: Icon(Icons.abc_outlined)),
                            input: TextInputType.text,
                            secureText: false,
                            onChanged: (value) {
                              widget.title = value;
                            },
                            suffix: Container(),
                            onTap1: () {},
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 10.h,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextFields(
                            inSquare: false,
                            controller: _tripDescriptionController,
                            borderColor: appOrange,
                            context: context,
                            enabled: true,
                            focusColor: Colors.black,
                            helpText: "Description",
                            hintText: "",
                            show: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.verified_user_outlined)),
                            icon: Tab(icon: Icon(Icons.abc_outlined)),
                            input: TextInputType.text,
                            secureText: false,
                            onChanged: (value) {
                              widget.description = value;
                            },
                            suffix: Container(),
                            onTap1: () {},
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 10.h,
                    ),

                    Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //DatePicker(newList, trip_uuid),
                        Row(
                          children: [
                            Text(
                              // 'Date:  ' + '${localTime.toString()}'.split(' ')[0].replaceAll('-', '/'),
                              'Date:  ' + '${widget.date.toString()}'.split(' ')[0].replaceAll('-', '/'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            //SizedBox(width: 5.0,),
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: appOrange,
                              ),
                              onPressed: () {
                                _selectDate(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    )),
                    // create/delete buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 180,
                          height: MediaQuery.of(context).size.height / 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: RectangularTextButton(
                            buttonColor: Colors.green,
                            textColor: Colors.white,
                            onPressed: () async {
                              if (widget.title != '' && widget.title != ' ') {
                                print('beneficiaries: ${widget.beneficiaries}');
                                await updateGridView(widget.newList);
                                Navigator.pop(context);
                                if (widget.newList) {
                                  if (tripCreated) {
                                    // print('SUPER MAX MAX MAX SUPER MAX SUPER MAX');
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => EditListScreen(widget.tripUUID))
                                    );
                                  }
                                }
                              } else {
                                Fluttertoast.showToast(
                                    msg: 'List name cannot be empty');
                              }
                            },
                            text: (widget.newList) ? 'Create List' : 'Save Changes',
                          ),
                        ),
                        Spacer(),
                        Container(
                          width: 180,
                          height: MediaQuery.of(context).size.height / 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: RectangularTextButton(
                            buttonColor: Colors.redAccent,
                            textColor: Colors.white,
                            text: "Delete List",
                            onPressed: () async {
                              await check_delete(context);
                              if (delete_list) {
                                if (!widget.newList) {
                                  // TODO may not need vvv possible to safely delete
                                  await total_expenditure(widget.tripUUID);
                                  deleteTripDB(widget.tripUUID, widget.beneficiaries);
                                }
                                Navigator.of(context).popUntil((route) {
                                  return route.settings.name == ListsScreen.id;
                                });
                                Navigator.pushNamed(context, ListsScreen.id);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          height: 200.0,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }));
  }

  check_delete(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this list?"),
          actions: <Widget>[
            TextButton(
                onPressed: () => {
                      delete_list = true,
                      Navigator.of(context).pop(),
                    },
                child: const Text("DELETE")),
            TextButton(
              onPressed: () => {
                delete_list = false,
                Navigator.of(context).pop(),
              },
              child: const Text("CANCEL"),
            ),
          ],
        );
      },
    );
  }
}
