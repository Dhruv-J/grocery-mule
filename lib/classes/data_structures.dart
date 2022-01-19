import 'package:uuid/uuid.dart';
import 'package:grocery_mule/database/query.dart';

class ShoppingTrip {
  String uuid;
  String title;
  DateTime date;
  String description;
  String host;
  List<String> beneficiaries;
  Map<String, Item> items; // name to item
  Receipt receipt;

  ShoppingTrip(this.title, this.date, this.description, this.host, this.beneficiaries) {
    var uuider = Uuid();
    uuid = uuider.v4();
    items = <String, Item>{};
  }
  ShoppingTrip.withUUID(this.uuid, this.title, this.date, this.description, this.host, this.beneficiaries) {
    items = <String, Item>{};
  }
  ShoppingTrip.withMetadata(this.title, this.date, this.description, this.host) {
    var uuider = Uuid();
    uuid = uuider.v4();
    items = <String, Item>{};
    beneficiaries = <String>[];
    items = <String, Item>{};
  }

  addBeneficary(String bene_uuid) {
    beneficiaries.add(bene_uuid);
    items.forEach((name, item) {
      item.addBeneficiary(bene_uuid);
    });
  }
  removeBeneficiary(String bene_uuid) {
    beneficiaries.remove(bene_uuid);
    items.forEach((name, item) {
      item.removeBeneficiary(bene_uuid);
    });
  }

  addItem(String name,[int quantity=0]) {
    Item new_item = Item(name, quantity, beneficiaries);
    items[name] = new_item;
  }
  addItemDirect(Item item) {
    items[item.name] = item;
  }
  removeItem(String name) {
    items.remove(name);
  }

  addReceipt(Receipt receipt) {
    this.receipt = receipt;
    // TODO when ML layer comes in, addReceipt can be the trigger to compute and send out venmos
  }

  Map<String, Map<String,dynamic>> getItemsMap() {
    Map<String, Map<String,dynamic>> ret_map = <String, Map<String,dynamic>>{};
    items.forEach((name, item) {
      ret_map[name] = item.toMap();
    });
    return ret_map;
  }
}

class Cowboy {
  String uuid;
  String first_name;
  String last_name;
  String email;
  List<String> shopping_trips;
  Map<String, String> friends; // uuid to first name
  List<String> requests; // uuid to first_last

  Cowboy(this.uuid, this.first_name, this.last_name, this.email) {
    shopping_trips = <String>[];
    friends = <String, String>{};
    requests = <String>[];
  }

  addTrip(String trip_uuid) {
    // only called upon setup by system during trip creation or list share
    shopping_trips.add(trip_uuid);
  }
  removeTrip(String trip_uuid) {
    // only called upon cleanup by system after venmos are sent out or if user gets booted
    shopping_trips.remove(trip_uuid);
  }

  addFriend(String email) {
    UserQuery querier = new UserQuery('', email);
    String friend_uuid;
    querier.getUUIDByEmail().then((value) => friend_uuid=value);
    querier.user_uuid = friend_uuid;
    querier.getUserByUUID().then((value) => friends[friend_uuid]=value.first_name);
  }
  removeFriend(String uuid) {
    // remember to run a check that all lists have been deleted
    friends.remove(uuid);
  }
}

class Item {
  String name;
  int quantity;
  Map<String, int> subitems; // uuid to individual quantity needed

  Item(this.name, this.quantity, List<String> beneficiaries) {
    subitems = <String, int>{};
    beneficiaries.forEach((beneficiary) {
      subitems[beneficiary] = 0;
    });
  }
  Item.withSubitems(this.name, this.quantity, this.subitems);

  addBeneficiary(String beneficiary) {
    subitems[beneficiary] = 0;
  }
  removeBeneficiary(String beneficiary) {
    subitems.remove(beneficiary);
  }

  incrementBeneficiary(String beneficiary) {
    subitems[beneficiary]++;
  }
  decrementBeneficiary(String beneficiary) {
    subitems[beneficiary]--;
  }

  Map<String,dynamic> toMap() {
    return {
      "name": name,
      "quantity": quantity,
      "subitems": subitems,
    };
  }
}

class Receipt {
  List<ReceiptItem> items;
  double final_total;
  double final_tax;

  Receipt(this.items, this.final_total, this.final_tax);
}

class ReceiptItem {
  String name;
  double price;
  int quantity;
  double total_price;

  ReceiptItem(this.name, this.price, this.quantity) {
    total_price = price*quantity;
  }
}