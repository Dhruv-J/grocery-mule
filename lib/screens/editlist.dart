import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_mule/components/rounded_ button.dart';
import 'package:grocery_mule/constants.dart';
import 'dart:async';
import 'package:grocery_mule/screens/lists.dart';
import 'package:grocery_mule/classes/ListData.dart';
import 'package:grocery_mule/classes/data_structures.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:number_inc_dec/number_inc_dec.dart';

import 'createlist.dart';
typedef StringVoidFunc = void Function(String,int);

class EditListScreen extends StatefulWidget {
  static String id = 'edit_list_screen';
  String trip_uuid;
  String initTitle;
  String initDescription;
  DateTime initDate;

  //createList has the ids
  //when createList has a list that's already filled
  //keep a field of the original id, but generate a new id
  //in the return variable
  EditListScreen(ShoppingTrip trip) {
    initTitle = trip.title;
    initDescription = trip.description;
    initDate = trip.date;
    trip_uuid = trip.uuid;
    print("createlist.dart constructor (title): "+initTitle);
  }

  @override
  _EditListsScreenState createState() => _EditListsScreenState();
}
class Item_front_end {
  int expand;
  Item item;
  Item_front_end(String name, List<String> members){  //pass in list of beneficiaries, food
    expand = 0;
    item = Item(name, 0, members);
  }
}
class _EditListsScreenState extends State<EditListScreen> {
  ShoppingTrip trip;
  var _tripTitleController;
  var _tripDescriptionController;
  final String uuid = FirebaseAuth.instance.currentUser.uid;
  Map<String,Item_front_end> frontend_list = {}; // name to frontend item

  bool isAdd = false;
  bool invite_guest = false;
  Future<void> delete(String tripID) async{
    await FirebaseFirestore.instance
        .collection('shopping_trips_test')
        .doc(tripID)
        .delete()
        .then((value) => print('deleted'))
        .catchError((error)=>print("failed"))
    ;

  }
  @override
  void initState() {
    // TODO: implement initState
    _tripTitleController = TextEditingController()..text = widget.initTitle;
    _tripDescriptionController = TextEditingController()..text = widget.initDescription;
    trip = ShoppingTrip.withUUID(widget.trip_uuid, widget.initTitle, widget.initDate, widget.initDescription, uuid, []);

    //test code
    trip.beneficiaries.add("Praf");
    trip.beneficiaries.add("Dhruv");

    List<String> full_list = trip.beneficiaries;
    full_list.add(trip.host);
    // TODO swap out with sample item once items update properly
    frontend_list = {'apple': Item_front_end('apple', full_list)};

    //end test code
    super.initState();
  }

  void auto_collapse(String ignore){
    frontend_list.forEach((key, item) {
      if(key != ignore)
        item.expand =0;
    });
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: trip.date,
        firstDate: DateTime(2021),
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
    if (picked != null && picked != trip.date)
      setState(() {
        trip.date = picked;
      });
  }

  void add_item(String name){
    List<String> full_list = trip.beneficiaries;
    full_list.add(trip.host);
    Item_front_end new_item = new Item_front_end(name,full_list);
    if(frontend_list[name] == null) {
      setState(() {
        frontend_list[name] = new_item;
        //trip.addItemDirect(new_item.item);
      });
    }
    else
      print("item already exists");
  }

  void delete_item(String name){
    if(frontend_list[name] != null) {
      setState(() {
        frontend_list.remove(name);
        trip.removeItem(name);
      });
    }
  }

  Widget simple_item(Item_front_end front_item){
    String name = front_item.item.name;
    int quantity = 0;
    front_item.item.subitems.forEach((name, count) {
      quantity = quantity + count;
    });

    return Dismissible(
      key: Key(name),
      onDismissed: (direction) {
        // Remove the item from the data source.
        setState(() {
          delete_item(name);
        });
      },
      confirmDismiss: (DismissDirection direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text("Are you sure you wish to delete this item?"),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("DELETE")
                ),
                FlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Theme.of(context).primaryColorDark,
        ),

        child: (
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  child: Text(
                    '$name',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                ),
                Container(
                  child: Text(
                    'x$quantity',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                    child: IconButton(
                        icon: const Icon(Icons.expand_more_sharp),
                        onPressed:
                            () =>(
                            setState(() {
                              front_item.expand = 1;
                              auto_collapse(front_item.item.name);
                            }))
                    )
                ),
              ],
            )),
      ),
      background: Container(color: Colors.red),
    );
  }

  Widget indie_item(String name, int number,StringVoidFunc callback){
    return Container(
      color: Theme.of(context).primaryColorLight,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              child: Text(
                '$name',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),

              padding: EdgeInsets.all(20),
            ),
            Container(
              child:
              NumberInputWithIncrementDecrement(
                initialValue: number,
                controller: TextEditingController(),
                onIncrement: (num newlyIncrementedValue) {
                  callback(name,newlyIncrementedValue);
                },
                onDecrement: (num newlyDecrementedValue) {
                  callback(name,newlyDecrementedValue);
                },
              ),
              height: 60,
              width: 105,

            ),
          ]
      ),

    );
  }

  Widget expanded_item(Item_front_end front_item){
    String name = front_item.item.name;
    int quantity = 0;
    front_item.item.subitems.forEach((key, value) {
      quantity = quantity + value;
      front_item.item.quantity = quantity;
    });
    void updateUsrQuantity(String name, int number){
      setState(() {
        front_item.item.subitems[name] = number;
        // trip.addItemDirect(front_item.item);
      });
    };
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Theme.of(context).primaryColorDark,
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                child: Text(
                  '$name',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                padding: EdgeInsets.all(20),
              ),
              Container(
                child: Text(
                  'x$quantity',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                  child: IconButton(
                      icon: const Icon(Icons.expand_less_sharp),
                      onPressed:
                          () =>(
                          setState(() {front_item.expand = 0;}))
                  )
              ),
            ],
          ),
          for(var entry in front_item.item.subitems.entries)
            indie_item(entry.key,entry.value,updateUsrQuantity)
        ],
      ),
    );
  }
  Widget single_item(Item_front_end test){
    return (
        (test.expand == 1)?expanded_item(test)
            : simple_item(test)
    );
  }

  Widget create_item(){
    String food = '';
    auto_collapse(food);
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.amberAccent
      ),

      child: (
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                child: Text(
                  'Enter Item',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                padding: EdgeInsets.all(20),
              ),
              Container(
                height: 45,
                width: 100,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'EX: Apple',
                  ),
                  onChanged: (text) {
                    food = text;
                  },
                ),
              ),
              Container(
                  child: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed:
                          () {
                        if (food != '')
                          setState(() {
                            add_item(food);
                            isAdd = false;
                          });
                      }
                  )
              ),
              Container(
                  child: IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed:
                          () =>(
                          setState(() {isAdd = false; }))
                  )
              ),
            ],
          )),
    );
  }
  void handleClick(int item) {
    switch (item) {

      case 1:
      Navigator.push(context,MaterialPageRoute(builder: (context) => CreateListScreen(trip,false)));
    }
  }

  @override
  Widget build(BuildContext context) {
    String host_uuid = trip.host;
    List<String> full_list = trip.beneficiaries;
    full_list.add(host_uuid);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Edit grocery items'),
        backgroundColor: const Color(0xFFbc5100),
          actions: <Widget>[
            PopupMenuButton<int>(
          onSelected: (item) => handleClick(item),
          itemBuilder: (context) => [
            PopupMenuItem<int>(value: 1, child: Text('Trip Settings')),
          ],
        ),
          ],
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
                        'Host',
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
                      Text(
                        'Harry',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
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
                        'Beneficiaries',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for(String name in full_list)
                        if(name != full_list[0])
                          Container(
                            child: Text(
                              '$name ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),

                      //TODO: Add users to list of beneficiaries when + button is pressed
                      Container(
                          child: IconButton(icon: const Icon(Icons.add_circle))),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 60,
                child: Divider(
                  color: Colors.black,
                  thickness: 1.5,
                  indent: 75,
                  endIndent: 75,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    child: Text(
                      'Add Item',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                      child: IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () {
                          setState(() {
                            isAdd = true;
                          });
                        },
                      )
                  ),
                ],
              ),
              if(isAdd)
                create_item(),
              //single_item(grocery_list[1]),

              for(var key in frontend_list.keys.toList().reversed)
                single_item(frontend_list[key]),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 70,
                    width: 150,
                    child: RoundedButton(
                      onPressed: () {

                      },
                      title: "Master List",
                    ),
                  ),
                  Container(
                    height: 70,
                    width: 150,
                    child: RoundedButton(
                      onPressed: () {
                        //go master list page
                      },
                      title: "Personal List",
                    ),
                  )
                ],
              ),
              Container(
                height: 70,
                width: 5,
                child: RoundedButton(
                  onPressed: () {
                    if(trip.title != '') {
                      frontend_list.forEach((name, fe_item) {
                        // trip.items[fe_item.item.name] = Item.withSubitems(fe_item.item.name, fe_item.item.quantity, fe_item.item.subitems);
                        trip.addItemDirect(fe_item.item);
                      });
                      // print('item: '+trip.items['apple'].quantity.toString());
                      //Navigator.pop(context, trip);
                      //Navigator.popUntil(context, ModalRoute.withName(ListsScreen.id));
                      //Navigator.of(context).popUntil((route){return route.settings.name == ListsScreen.id;});
                      //Navigator.pushNamed(context, ListsScreen.id);
                      Navigator.pop(context, trip);
                    }else{
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
                  title: "Update List",
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

}