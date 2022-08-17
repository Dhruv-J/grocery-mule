import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

final CollectionReference userCollection = FirebaseFirestore.instance.collection('beta_users');
final CollectionReference tripCollection = FirebaseFirestore.instance.collection('beta_trips');

CollectionReference _itemCollection(String tripUUID) {
  return tripCollection.doc(tripUUID).collection('subitems');
}

// reference can be used for stream, snapshot, or future
DocumentReference _tripDocReference(String tripUUID) {
  return tripCollection.doc(tripUUID);
}

// stream of fields in a singular trip document
Stream<DocumentSnapshot> _tripStream(String tripUUID) {
  return _tripDocReference(tripUUID).snapshots();
}

// document snapshot of a single trip
Future<DocumentSnapshot<Object?>> tripDocSnapshot(String tripUUID) {
  return _tripDocReference(tripUUID).get();
}

deleteTripDB(String tripUUID, List<String> beneficiaries) async {
  QuerySnapshot items_snapshot =
  await tripCollection.doc(tripUUID).collection('items').get();
  items_snapshot.docs.forEach((item_doc) {
    item_doc.reference.delete();
  });
  beneficiaries.forEach((bene) {
    userCollection
        .doc(bene)
        .collection('shopping_trips')
        .doc(tripUUID)
        .delete();
  });
  tripCollection.doc(tripUUID).delete();
}

removeBeneficiaries(List<String> bene_uuids, String tripUUID) async {
  await removeBeneficiariesFromItems(bene_uuids, tripUUID);
  await tripCollection.doc(tripUUID).update({'beneficiaries': FieldValue.arrayRemove(bene_uuids)});
  bene_uuids.forEach((String bene_uuid) async {
    await userCollection.doc(bene_uuid).collection('shopping_trips').doc(tripUUID).delete();
  });
}

removeBeneficiariesFromItems(List<String> bene_uuids, String tripUUID) async {
  QuerySnapshot items_shot =
  await tripCollection.doc(tripUUID).collection('items').get();
  List<String> itemUUID = [];
  if (items_shot.docs != null && items_shot.docs.isNotEmpty) {
    items_shot.docs.forEach((item_uuid) {
      if (item_uuid.id.trim() != 'tax' && item_uuid.id.trim() != 'add. fees') {
        itemUUID.add(item_uuid.id.trim());
      }
    });
  }
  itemUUID.forEach((item) async {
    DocumentSnapshot item_shot = await tripCollection.doc(tripUUID).collection('items').doc(item).get();
    int newtotal = 0;
    Map<String, int> bene_items = <String, int>{};
    (item_shot['subitems'] as Map<String, dynamic>).forEach((uuid, quantity) {
      bene_items[uuid] = int.parse(quantity.toString());
      if (!bene_uuids.contains(uuid)) {
        newtotal += int.parse(quantity.toString());
      }
    });
    bene_uuids.forEach((bene_uuid) {
      bene_items.remove(bene_uuid);
    });
    await tripCollection.doc(tripUUID).collection('items').doc(item)
        .update({'quantity': newtotal, 'subitems': bene_items});
  });
}

addBeneficiaries(List<String> addList, String tripUUID, DateTime date) async {
  addList.forEach((String bene_uuid) async {
    await userCollection.doc(bene_uuid).collection('shopping_trips').doc(tripUUID).set({'date': date});
  });
  await tripCollection
      .doc(tripUUID)
      .update({'beneficiaries': FieldValue.arrayUnion(addList)});
  //add bene to every item document
  QuerySnapshot items_shot =
  await tripCollection.doc(tripUUID).collection('items').get();
  List<String> itemUUID = [];
  if (items_shot.docs != null && items_shot.docs.isNotEmpty) {
    items_shot.docs.forEach((item_uuid) {
      if (item_uuid.id.trim() != 'tax' &&
          item_uuid.id.trim() != 'add. fees') {
        itemUUID.add(item_uuid.id.trim());
      }
    });
  }
  itemUUID.forEach((item) async {
    Map<String, int> bene_items = <String, int>{};
    //add back previous user
    addList.forEach((bene_uuid) async {
      // bene_items[bene_uuid] = 0;
      await tripCollection.doc(tripUUID).collection('items').doc(item).update({'subitems.$bene_uuid': 0});
    });
    print(tripUUID);
  });
}

// get title from trip snapshot
String getTitle(DocumentSnapshot tripSnapshot) {
  if (tripSnapshot['title']==null) {
    // FDNE = field does not exist
    throw Exception('FDNE');
  } else {
    return tripSnapshot['title']!.toString();
  }
}

// get description from trip snapshot
String getDescription(DocumentSnapshot tripSnapshot) {
  if (tripSnapshot['description']==null) {
    throw Exception('FDNE');
  } else {
    return tripSnapshot['description']!.toString();
  }
}

// get date from trip snapshot
DateTime getDate(DocumentSnapshot tripSnapshot) {
  if (tripSnapshot['date']==null) {
    throw Exception('FDNE');
  } else {
    return tripSnapshot['date']!.toDate();
  }
}

// get benes from trip snapshot
List<String> getBeneficiaries(DocumentSnapshot tripSnapshot) {
  if (tripSnapshot['beneficiaries']==null) {
    throw Exception('FDNE');
  } else {
    List<String> benes = [];
    (tripSnapshot['beneficiaries'] as List<dynamic>).forEach((dynamicBene) {
      benes.add(dynamicBene.toString());
    });
    return benes;
  }
}