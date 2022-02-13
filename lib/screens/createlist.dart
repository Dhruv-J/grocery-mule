import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_mule/components/rounded_ button.dart';
import 'package:grocery_mule/providers/cowboy_provider.dart';
import 'package:grocery_mule/screens/editlist.dart';
import 'dart:async';
import 'package:grocery_mule/screens/lists.dart';
import 'package:provider/provider.dart';
import 'package:grocery_mule/providers/cowboy_provider.dart';
import 'package:grocery_mule/providers/shopping_trip_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:number_inc_dec/number_inc_dec.dart';

typedef StringVoidFunc = void Function(String,int);

class CreateListScreen extends StatefulWidget {
  final _auth = FirebaseAuth.instance;
  final User curUser = FirebaseAuth.instance.currentUser;
  static String id = 'create_list_screen';
  String trip_uuid;
  String initTitle;
  String initDescription;
  DateTime initDate;
  bool newList;
  //createList has the ids
  //when createList has a list that's already filled
  //keep a field of the original id, but generate a new id
  //in the return variable
  CreateListScreen(bool newList) {
    this.newList = newList;
  }

  @override
  _CreateListsScreenState createState() => _CreateListsScreenState();
}

class _CreateListsScreenState extends State<CreateListScreen> {
  final _auth = FirebaseAuth.instance;
  final User curUser = FirebaseAuth.instance.currentUser;
  bool newList;
  //////////////////////
  var _tripTitleController;
  var _tripDescriptionController;
  final String hostUUID = FirebaseAuth.instance.currentUser.uid;
  String hostFirstName = FirebaseAuth.instance.currentUser.displayName;
  //Map<String,Item_front_end> frontend_list = {}; // name to frontend item
  bool isAdd = false;
  bool delete_list = false;
  bool invite_guest = false;
  @override
  void initState() {
    _tripTitleController = TextEditingController()..text = widget.initTitle;
    _tripDescriptionController = TextEditingController()..text = widget.initDescription;
    newList = widget.newList;
    //test code
    context.read<ShoppingTrip>().addBeneficiary('praf');
    context.read<ShoppingTrip>().addBeneficiary('harry');

    // full_list = trip.beneficiaries;
    //end test code
    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: context.read<ShoppingTrip>().date,
        firstDate: DateTime(2022),
        lastDate: DateTime(2050),
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light().copyWith(
                primary: const Color(0xFFbc5100),
              ),
            ),
            child: child,
          );
        }
    );
    if (picked != null && picked != context.read<ShoppingTrip>().date) {
      context.read<ShoppingTrip>().editTripDate(picked);
    }
  }

  void updateGridView(bool new_trip) async {
    try {
      // ListData data = new ListData(tripTitle, tripDescription, tripDate, unique_id);
      // print('updateGridView DatabaseServiceapple count: '+trip.items['apple'].quantity.toString());
      if(new_trip) {
        // await DatabaseService(uuid: trip.uuid).createShoppingTrip(trip);
        // await DatabaseService(uuid: curUser.uid).addTripToUser(curUser.uid,trip.uuid);
      } else {
        // await DatabaseService(uuid: trip.uuid).updateShoppingTrip(trip);
      }
    } catch (e) {
      print('error in updateGridView: '+e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    String hostUUID = context.read<Cowboy>().uuid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create List'),
        backgroundColor: const Color(0xFFbc5100),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
              padding: const EdgeInsets.all(25),
              children: [
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'List Name',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          child: TextField(
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black),
                              controller: _tripTitleController,
                              onChanged: (value){
                                context.read<ShoppingTrip>().editTripTitle(value);
                              }

                          ),
                        )
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 40,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Trip',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("${context.read<ShoppingTrip>().date.toLocal()}".split(' ')[0]),
                      SizedBox(
                        height: 20.0,
                      ),
                      RoundedButton(
                        onPressed: () => _selectDate(context),
                        title: 'Select Date',
                      ),
                    ],
                  ),
                ]),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          child: TextField(
                              keyboardType: TextInputType.emailAddress,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black),
                              controller: _tripDescriptionController,
                              onChanged: (value){
                                context.read<ShoppingTrip>().editTripDescription(value);
                              }
                          ),
                        )
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 40,
                ),

                Container(
                  height: 70,
                  width: 5,
                  child: RoundedButton(
                    onPressed: () {
                      if(context.read<ShoppingTrip>().title != '') {
                        //frontend_list.forEach((name, fe_item) {
                          // trip.items[fe_item.item.name] = Item.withSubitems(fe_item.item.name, fe_item.item.quantity, fe_item.item.subitems);
                          //context.read<ShoppingTrip>().addItemDirect(fe_item.item);
                        //});
                        // print('item: '+trip.items['apple'].quantity.toString());
                        updateGridView(newList);
                        Navigator.pop(context);
                        //Navigator.pushNamed(context, ListsScreen.id);
                        if(newList)
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditListScreen(context.read<Cowboy>().uuid)));
                      } else {
                        // print("triggered");
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("List name cannot be empty"),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    title: "Create List",
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  height: 70,
                  width: 150,
                  child: RoundedButton(
                    onPressed: () async {
                      await check_delete(context);
                      if(delete_list) {
                        context.read<Cowboy>().removeTrip(context.read<ShoppingTrip>().uuid);
                        Navigator.of(context).popUntil((route){
                          return route.settings.name == ListsScreen.id;
                        });
                        Navigator.pushNamed(context, ListsScreen.id);
                      }
                    },
                    title: "Delete List",
                  ),
                )
              ],
            ),
        ),
      ),
    );
  }

  check_delete(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this list?"),
          actions: <Widget>[
            FlatButton(
                onPressed: () => {
                  delete_list = true,
                  Navigator.of(context).pop(),
                  },
                child: const Text("DELETE")
            ),
            FlatButton(
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