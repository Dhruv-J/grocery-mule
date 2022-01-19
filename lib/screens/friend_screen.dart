import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:grocery_mule/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_mule/classes/data_structures.dart';

class FriendScreen extends StatefulWidget {
  static String id = 'friend_screen';

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> with SingleTickerProviderStateMixin {
  String search_query;
  int num_requests;
  List<String> friend_uuids;
  @override
  void initState() {
    super.initState();
    num_requests = 0;
    friend_uuids = <String>['placeholder'];
  }
  Stream<QuerySnapshot> getData() {
    CollectionReference user_collection = FirebaseFirestore.instance.collection('updated_users_test');
    DocumentSnapshot user_snapshot;
    user_collection.doc('yTWmoo2Qskf3wFcbxaJYUt9qrZM2').get().then((value) => user_snapshot);
    if(user_snapshot != null) {
      friend_uuids = (user_snapshot['friends'] as Map<String, dynamic>).keys;
    }
    return user_collection.where('uuid', whereIn: friend_uuids).snapshots();
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
            ),
            Container(
              child: StreamBuilder(
                stream: getData(),
                builder: (context, AsyncSnapshot<QuerySnapshot> listsnapshot) {
                  List<QueryDocumentSnapshot> snapshot_data = <QueryDocumentSnapshot>[];
                  if (listsnapshot.hasData) {
                    snapshot_data = listsnapshot.data.docs;
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(2),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot_data.length,
                    itemBuilder: (context, int index) {
                      return Container(
                        child: Row(
                          children: <Widget>[
                            Column(
                              children: [
                                Text(snapshot_data[index]['first_name']+' '+snapshot_data[index]['last_name']),
                                SizedBox(height: 1.0,),
                                Text(snapshot_data[index]['email']),
                              ],
                            ),
                            /*Row(
                              children: <Widget>[
                                Text(snapshot_data[index]['first_name']+' '+snapshot_data[index]['last_name']),
                              ],
                            ),
                            SizedBox(
                              height: 1.0,
                            ),
                            Row(
                              children: <Widget>[
                                Text(snapshot_data[index]['email']),
                              ],
                            ),*/
                          ],
                        ),
                      );
                    },
                  );
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