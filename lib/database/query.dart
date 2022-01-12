import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_mule/classes/data_structures.dart';

class UserQuery {
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('updated_users_test');
  final CollectionReference uuidCollection = FirebaseFirestore.instance.collection('email_uuid_table');

  String user_uuid;
  String user_email;

  UserQuery(this.user_uuid, this.user_email);

  Future<String> getUUIDByEmail() async {
    String _uuid;
    DocumentSnapshot snapshot = await uuidCollection.doc(user_email).get();
    _uuid = snapshot['uuid'];
    return _uuid;
  }

  Future<Cowboy> getUserByUUID() async {
    Cowboy _cowboy;
    DocumentSnapshot snapshot = await userCollection.doc(user_uuid).get();
    _cowboy = new Cowboy(snapshot['uuid'], snapshot['first_name'], snapshot['last_name'], snapshot['email']);
    return _cowboy;
  }
}