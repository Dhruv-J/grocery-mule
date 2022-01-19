import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_mule/classes/ListData.dart';
import 'package:grocery_mule/classes/data_structures.dart';

class DatabaseService {
  final String uuid;
  DatabaseService({this.uuid});

  final CollectionReference userTestingCollection = FirebaseFirestore.instance.collection('users_test');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('updated_users_test');
  final CollectionReference tripCollection = FirebaseFirestore.instance.collection('shopping_trips_test');

  Future createShoppingTrip(ShoppingTrip new_trip) async{
    return await tripCollection.doc(new_trip.uuid).set({
      'uuid': new_trip.uuid,
      'date': new_trip.date,
      'title': new_trip.title,
      'description': new_trip.description,
      'host': new_trip.host,
      'beneficiaries': new_trip.beneficiaries,
      'items': new_trip.getItemsMap(),
      'receipt:': new_trip.receipt,
    });
  }
  Future updateShoppingTrip(ShoppingTrip new_trip) async{
    return await tripCollection.doc(new_trip.uuid).update({
      'date': new_trip.date,
      'title': new_trip.title,
      'description': new_trip.description,
      'host': new_trip.host,
      'beneficiaries': new_trip.beneficiaries,
      'items': new_trip.getItemsMap(),
      'receipt:': new_trip.receipt,
    });
  }
  Future updateUserData(Cowboy new_cowboy) async{
    print(uuid);
    return await userCollection.doc(uuid).update({
      'first_name': new_cowboy.first_name,
      'last_name': new_cowboy.last_name,
      'email': new_cowboy.email,
    });
  }
  Future initializeUserData(Cowboy new_cowboy) async{
    return await userCollection.doc(uuid).set({
      'uuid': new_cowboy.uuid,
      'first_name': new_cowboy.first_name,
      'last_name': new_cowboy.last_name,
      'email': new_cowboy.email,
      'shopping_trips': new_cowboy.shopping_trips,
      'friends': new_cowboy.friends,
      'requests': new_cowboy.requests,
    });
  }
  Future addTripToUser(String user_uuid, String trip_uuid) async{
    List<String> temp_list = [trip_uuid];
    return await tripCollection.doc(user_uuid).update({
      'shopping_trips': FieldValue.arrayUnion(temp_list),
    });
  }
  Future removeTripFromUser(String user_uuid, String trip_uuid) async{
    return await userCollection.doc(user_uuid).update({
      'shopping_trips': FieldValue.arrayRemove({}.remove(trip_uuid)),
    });
  }
  Future sendFriendRequest(String friend_uuid, String requester_uuid) async{
    List<String> temp_list = [requester_uuid];
    return await userCollection.doc(friend_uuid).update({
      'requests': FieldValue.arrayUnion(temp_list),
    });
  }
  Future acceptFriendRequest(String friend_uuid, String requester_uuid, String requester_name) async{
    List<String> request_list = [requester_uuid];
    return await userCollection.doc(friend_uuid).update({
      'requests': FieldValue.arrayRemove(request_list),
      'friends.$requester_uuid': requester_name,
    });
  }
  Future denyFriendRequest(String friend_uuid, String requester_uuid) async{
    List<String> request_list = [requester_uuid];
    return await userCollection.doc(friend_uuid).update({
      'requests': FieldValue.arrayRemove(request_list),
    });
  }
  Future removeFriend(String friend_uuid, String toremove_uuid) async{
    return await userCollection.doc(friend_uuid).update({
      'friends': FieldValue.arrayRemove({}.remove(toremove_uuid)),
    });
  }
}