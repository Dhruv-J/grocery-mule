import 'dart:collection';
import 'dart:convert';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:grocery_mule/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendScreen extends StatefulWidget {
  static String id = 'friend_screen';

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> with SingleTickerProviderStateMixin {
  String search_query;
  int num_requests;
  List<String> friend_uuids;
  Stream<QuerySnapshot> friendData;
  @override
  void initState() {
    super.initState();
    num_requests = 0;
    friend_uuids = <String>['placeholder'];
    friendData = getData();
  }
  Stream<QuerySnapshot> getData() {
    CollectionReference user_collection = FirebaseFirestore.instance.collection('updated_users_test');
    Map<String, dynamic> temp_map;
    List<String> temp_list = <String>['placeholder'];
    int count = 0;
    user_collection.doc('yTWmoo2Qskf3wFcbxaJYUt9qrZM2').get().then((value) => {
      if(value.data() != null) {
        print(value['friends']),
        temp_map = new Map<String, dynamic>.from(value['friends']),
        temp_map.keys.forEach((friend_uuid) {
          print(friend_uuid);
          temp_list.add(friend_uuid);
          count++;
        }),
        this.friend_uuids = temp_list,
        print(this.friend_uuids.length),
      },
    });
    print('friend_screen friends list length: '+friend_uuids.length.toString());
    if(friend_uuids.length>10) {
      return user_collection.where('uuid', whereIn: friend_uuids.sublist(1, 11)).snapshots();
    } else {
      return user_collection.where('uuid', whereIn: friend_uuids).snapshots();
    }
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('cowamigos'),
        centerTitle: true,
        backgroundColor: const Color(0xFFbc5100),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Container(
                    child: TextField(
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.left,
                      onChanged: (value) {
                        search_query = value;
                      },
                      decoration: kTextFieldDecoration.copyWith(
                        hintText: 'search by email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepOrangeAccent, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepOrangeAccent, width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                        hintStyle: TextStyle(
                          fontSize: 20.0,
                          height: 0.85,
                        ),
                      ),
                    ),
                    height: 37.0,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                  tooltip: 'search',
                ),
                Badge(
                  badgeContent: Text(num_requests.toString()),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.deepOrangeAccent),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    onPressed: () {},
                    child: Text('Requests'),
                  ),
                ),
              ], // end of row children
            ), // search bar and request button
            SizedBox(
              height: 12.0,
            ),
            Row(), // row for search results // conditional
            SizedBox(
              height: 24.0,
              child: Text('Friends'),
            ),
            Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: friendData,
                builder: (context, AsyncSnapshot<QuerySnapshot> listsnapshot) {
                  if (listsnapshot.connectionState == ConnectionState.done) {
                    List<QueryDocumentSnapshot> snapshot_data = <QueryDocumentSnapshot>[];
                    if (listsnapshot.hasData) {
                      snapshot_data = listsnapshot.data.docs;
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(2),
                      // scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: snapshot_data.length,
                      itemBuilder: (context, int index) {
                        return Container(
                          child: Row(
                            children: <Widget>[
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(snapshot_data[index]['first_name']+' '+snapshot_data[index]['last_name']),
                                  SizedBox(height: 1.0,),
                                  Text(snapshot_data[index]['email']),
                                  // Text('cringelord'),
                                ],
                              ),
                            ],
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.deepOrange),
                            borderRadius: BorderRadius.all(Radius.circular(6.0)),
                          ),
                        );
                      },
                    );
                  }
                  return CircularProgressIndicator();
                }
              ),
            ), // container for listview of friends list
          ],
        ),
      ),
    );
    throw UnimplementedError();
  }
}