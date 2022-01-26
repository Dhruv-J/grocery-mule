import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_mule/components/rounded_ button.dart';
import 'package:grocery_mule/constants.dart';
import 'package:grocery_mule/screens/createlist.dart';
import 'package:grocery_mule/screens/friend_screen.dart';
import 'package:grocery_mule/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grocery_mule/classes/data_structures.dart';
import 'package:grocery_mule/database/updateListData.dart';
import 'package:grocery_mule/database/query.dart';
import 'package:grocery_mule/screens/user_info.dart';
import 'package:async/async.dart';

import 'editlist.dart';



class ListsScreen extends StatefulWidget {
  final _auth = FirebaseAuth.instance;
  final User curUser = FirebaseAuth.instance.currentUser;
  static String id = 'lists_screen';

  @override
  _ListsScreenState createState() => _ListsScreenState();
}


class _ListsScreenState extends State<ListsScreen> {

  final _auth = FirebaseAuth.instance;
  final User curUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  /*
  Future<Stream<List<QuerySnapshot<Object>>>> getData()  {
    //get snapshot of the user
    //Stream host_info = FirebaseFirestore.instance.collection('updated_users_test').doc(curUser.uid).snapshots();
    //snapshot of shopping trips belongs to the user
    //List list_id = await host_info.elementAt(5);
    // List<String> master_list = await host_info.['shopping_trips'];
    //print(list_id);
    //Stream host_lists = await FirebaseFirestore.instance.collection('shopping_trips_test').where('host',isEqualTo:curUser.uid).snapshots();
    //List<Stream> masterlist = [];
    //list_id.forEach((id) {
    //  Stream temp = FirebaseFirestore.instance.collection('shopping_trips_test').doc(id).snapshots();
    //  masterlist.add(temp);
    //});
    Stream host_lists = FirebaseFirestore.instance.collection('shopping_trips_test').where('host', isEqualTo: curUser.uid).snapshots();
    Stream bene_lists = FirebaseFirestore.instance.collection('shopping_trips_test').where('beneficiaries', arrayContains: curUser.uid).snapshots();
    return StreamZip([host_lists,bene_lists]);
    //return StreamZip([host_lists]);
  }
  */
  Stream<List<QuerySnapshot>> getData() {
    Stream host_lists = FirebaseFirestore.instance.collection('shopping_trips_test').where('host', isEqualTo: curUser.uid).snapshots();
    Stream bene_lists = FirebaseFirestore.instance.collection('shopping_trips_test').where('beneficiaries', arrayContains: curUser.uid).snapshots();
    /*UserQuery testie = new UserQuery('AU8H9TXaKHckfCKIjyDBWFqQRGf2', 'sharmaprafull76@gmail.com');
    String uuid;
    testie.getUUIDByEmail().then((value)=> uuid=value);
    print(uuid);
    testie.getUserByUUID().then((value) => print(value.first_name));*/
    return StreamZip([host_lists, bene_lists]);
  }



  @override
  Widget build(BuildContext context) {
    print('pulling data');
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Grocery Lists'),
            backgroundColor: const Color(0xFFbc5100),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: const Color(0xFFbc5100),
                  ),
                  child: Text(
                    'Menu Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20
                    ),
                  ),
                ),
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
                  title: const Text('Log Out'),
                  onTap: () async {
                    var currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      await _auth.signOut();
                      print('User signed out');
                    }
                    //Navigator.pop(context);
                    Navigator.of(context).popUntil((route){
                      return route.settings.name == WelcomeScreen.id;
                    });
                    Navigator.pushNamed(context, WelcomeScreen.id);
                  },
                ),
              ],
            ),
          ),

          body: StreamBuilder(
              stream: getData(),
              //FirebaseFirestore.instance.collection('shopping_trips_test').where('uuid', isEqualTo: FirebaseAuth.instance.currentUser.uid).snapshots(),
              // FirebaseFirestore.instance.collection('shopping_trips_test').where('beneficiaries', arrayContains: FirebaseAuth.instance.currentUser.uid).snapshots()
              builder: (context, AsyncSnapshot<List<QuerySnapshot>> listSnapshot) {
                var streamSnapshot;
                if(listSnapshot.data != null) {
                  List streamSnapshotData = listSnapshot.data.toList();
                  // print(streamSnapshotData);
                  streamSnapshotData[0].docs.addAll(streamSnapshotData[1].docs);
                  streamSnapshot = streamSnapshotData[0];
                }
                if(streamSnapshot == null) return CircularProgressIndicator();
                return SafeArea(
                  child: Scrollbar(
                  isAlwaysShown: true,
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: streamSnapshot.size,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 7),
                    itemBuilder: (context, int index) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFf57f17),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFffab91),
                              blurRadius: 3,
                              offset: Offset(3, 6), // Shadow position
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            '\n${streamSnapshot.docs[index]['title']}\n'
                                '${streamSnapshot.docs[index]['description']}\n\n'
                                '${(streamSnapshot.docs[index]['date'] as Timestamp).toDate().month}'+
                                '/'+
                                '${(streamSnapshot.docs[index]['date'] as Timestamp).toDate().day}'+
                                '/'+
                                '${(streamSnapshot.docs[index]['date'] as Timestamp).toDate().year}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          onTap: () async {
                            ShoppingTrip cur_trip = new ShoppingTrip(streamSnapshot.docs[index]['title'],
                                (streamSnapshot.docs[index]['date'] as Timestamp).toDate(),
                                streamSnapshot.docs[index]['description'],
                                curUser.uid, []);
                            cur_trip.uuid = streamSnapshot.docs[index]['uuid'];
                            streamSnapshot.docs[index]['items'].forEach((name, item) {
                              print(item.runtimeType);
                              Item temp_item = Item.withSubitems(item['name'], item['quantity'], item['beneficiaries']);
                              cur_trip.items[temp_item.name] = temp_item;
                            });
                            // print("lists.dart method (uuid): "+cur_trip.uuid);
                            //check if the curData's field is null, if so, set flag
                            //print("rig rag shig shag: "+cur_trip.uuid);
                            /*final updated_trip =*/ await Navigator.push(context,MaterialPageRoute(builder: (context) => EditListScreen(cur_trip)));
                            /*
                            if (updated_trip != null) {
                              updateGridView(updated_trip, false);
                            } else {
                              print('no changes made to be saved!');
                            }
                            */

                          },
                        ),
                      );
                    },
                  ),
                  ),
                );
              }
          ),

          floatingActionButton: Container(
            height: 80,
            width: 80,
            child: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateListScreen(new ShoppingTrip('', new DateTime.now(), '', curUser.uid, []),true))
                );

              },
            ),
          ),
        ),
    );
  }
}