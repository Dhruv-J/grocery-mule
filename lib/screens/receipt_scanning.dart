import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_mule/dev/collection_references.dart';
import 'package:grocery_mule/providers/shopping_trip_provider.dart';
import 'package:grocery_mule/theme/colors.dart';
import 'package:grocery_mule/theme/text_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:grocery_mule/painters/text_detector_painter.dart';
import 'package:provider/provider.dart';
import '../components/rounded_ button.dart';
import '../constants.dart';

class DBItemPrice extends StatefulWidget {
  late final String itemUUID;
  DBItemPrice(String itemUUID, [bool spec = false, bool strng = false]) {
    this.itemUUID = itemUUID;
  }

  @override
  _DBItemPriceState createState() => _DBItemPriceState();
}

class _DBItemPriceState extends State<DBItemPrice> {
  late String itemUUID;
  late Stream<DocumentSnapshot> personalshot;

  @override
  void initState() {
    itemUUID = widget.itemUUID;
    personalshot = tripCollection
        .doc(context.read<ShoppingTrip>().uuid)
        .collection('items')
        .doc(itemUUID)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: personalshot,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          return Text(
            '${snapshot.data!['price']} ',
            style: appFontStyle.copyWith(color: Colors.black, fontSize: 15.sp),
          );
        });
  }
}

class ReceiptItem extends StatefulWidget {
  String name = '';
  String price = '0.00';
  String receiptItemUUID = '';

  ReceiptItem(String name, String receiptItemUUID) {
    this.name = name;
    this.receiptItemUUID = receiptItemUUID;
  }

  @override
  _ReceiptItemState createState() => _ReceiptItemState();
}

class _ReceiptItemState extends State<ReceiptItem> {
  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAccept: (String newprice) {
        setState(() {
          context
              .read<ShoppingTrip>()
              .updateItemPrice(widget.receiptItemUUID, double.parse(newprice));
          widget.price = newprice;
          print(widget.name + ', ' + widget.price);
        });
      },
      builder: (BuildContext context, accepted, rejected) {
        return Card(
          child: Container(
            padding: const EdgeInsets.all(4.0),
            height: 40.h,
            child: Row(
              children: [
                Text(
                  '${widget.name}: ',
                  style: appFontStyle.copyWith(
                      color: Colors.white, fontSize: 15.sp),
                ),
                // TODO get price to go as right as possible
                // SizedBox.expand(),
                if (widget.receiptItemUUID != 'dummy') ...[
                  DBItemPrice(widget.receiptItemUUID),
                ]
              ],
            ),
            // decoration: BoxDecoration(
            //   color: Colors.grey[500],
            //   border: Border.all(),
            //   borderRadius: BorderRadius.all(Radius.circular(4.0)),
            // ),
          ),
        );
      },
    );
  }
}

class ReceiptItems extends StatefulWidget {
  late Stream<QuerySnapshot> itemstream;
  List<ReceiptItem> rilist = [];

  ReceiptItems(List<ReceiptItem> rilist, Stream<QuerySnapshot> itemstream) {
    this.rilist = rilist;
    this.itemstream = itemstream;
    // print('got to constructor in ReceiptItems');
  }

  @override
  _ReceiptItemsState createState() => _ReceiptItemsState();
}

class _ReceiptItemsState extends State<ReceiptItems> {
  loadItems(QuerySnapshot snapshot) {
    // print('gpt to loadItems ReceiptItemsState');
    bool add_fees = false;
    widget.rilist = [];
    snapshot.docs.forEach((document) {
      // print('0');
      String item_name = document['name'];
      if (item_name == 'tax') {
        if (add_fees) widget.rilist.insert(widget.rilist.length-1, ReceiptItem(item_name, document['uuid']));
      } else if (item_name == 'add. fees') {
        widget.rilist.add(ReceiptItem(item_name, document['uuid']));
        add_fees = true;
      } else {
        widget.rilist.insert(0, ReceiptItem(item_name, document['uuid']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: widget.itemstream,
        builder: (context, snapshot) {
          // print('build ReceiptItemsState: ${items.length}');
          if (snapshot.hasError) {
            return const Text(
                'Something went wrong with item snapshot in receipt_scanning');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('waiting for snapshot ReceiptItemsState');
            return const CircularProgressIndicator();
          }
          loadItems(snapshot.data!);
          return Container(
            height: 500,
            child: ListView.separated(
              padding: const EdgeInsets.all(4.0),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: widget.rilist.length,
              itemBuilder: (context, index) {
                return widget.rilist[index];
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 4.0);
              },
            ),
          );
        },
      ),
    );
  }
}

class ReceiptPrice extends StatefulWidget {
  String price = '0.00';

  ReceiptPrice(String price) {
    this.price = price;
  }

  @override
  _ReceiptPriceState createState() => _ReceiptPriceState();
}

class _ReceiptPriceState extends State<ReceiptPrice> {
  String val = '0.00';

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: widget.price,
      child: Container(
        padding: const EdgeInsets.all(4.0),
        height: 40.h,
        child: Row(
          children: [
            Text(
              '${widget.price} ',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: beige,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            width: 5.0,
                            color: darker_beige,
                          ),
                        ),
                        content: Container(
                          width: 100,
                          height: 150,
                          child: Column(
                            children: [
                              Text(
                                'Change Price',
                                style: TextStyle(fontSize: 25),
                              ),
                              TextField(
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  val = value;
                                },
                                decoration: InputDecoration(hintText: widget.price),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        widget.price = val;
                                        //price = val;
                                      });
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.done),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.clear),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
              },
              icon: Icon(
                Icons.create_outlined,
                size: 20,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.grey[500],
          // border: Border.all(),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(4.0),
        height: 30.0,
        child: Row(
          children: [
            Text(
              '',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      feedback: Container(
        padding: const EdgeInsets.all(4.0),
        height: 30.0,
        child: Row(
          children: [
            Text(
              '${widget.price}',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          border: Border.all(),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
    );
  }
}

class ReceiptPrices extends StatefulWidget {
  List<ReceiptPrice> rplist = [];

  ReceiptPrices(List<ReceiptPrice> prices) {
    this.rplist = prices;
    // print('initialized prices ReceiptPrices: ${this.prices.length}');
  }

  @override
  _ReceiptPricesState createState() => _ReceiptPricesState();
}

class _ReceiptPricesState extends State<ReceiptPrices> {
  @override
  Widget build(BuildContext context) {
    // print('reached build ReceiptPricesState: ${this.prices.length}');
    return Expanded(
      child: Container(
        height: 500,
        child: ListView.separated(
          padding: const EdgeInsets.all(4.0),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: widget.rplist.length,
          itemBuilder: (context, index) {
            return widget.rplist[index];
            // ReceiptPrice rp = ReceiptPrice(prices[index]);
            // widget.prices[index] = rp.price;
            // return rp;
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: 10.0);
          },
        ),
      ),
    );
  }
}

class ReceiptScanning extends StatefulWidget {
  static String id = 'receipts_scanning';

  @override
  _ReceiptScanningState createState() => _ReceiptScanningState();
}

class _ReceiptScanningState extends State<ReceiptScanning> {
  File? receipt_image;
  //final inputImage;
  List<ReceiptPrice> rplist = [];
  List<ReceiptItem> rilist = [];
  late Stream<QuerySnapshot> itemstream;

  @override
  initState() {
    super.initState();
    itemstream = tripCollection
        .doc(context.read<ShoppingTrip>().uuid)
        .collection('items')
        .snapshots();
  }

  bool isPrice(String text) {
    bool dotXX(String tocheck) {
      if (tocheck.length <= 3) {
        return true;
      }
      String last3 = tocheck.substring(tocheck.length - 3);
      bool dec = true; // decimal
      bool ret = false; // return var, since can't return from forEach
      last3.runes.forEach((charCode) {
        if (dec) {
          if (charCode != 46) {
            // print('incorrectly formatted decimal');
            ret = true;
          }
          dec = false;
        } else {
          if (charCode < 48 || charCode > 57) {
            // not integer ascii value
            ret = true;
          }
        }
      });

      return ret;
    }

    if (!text.contains('.')) {
      return false;
    } else if (dotXX(text)) {
      // checks if last 3 characters are '.XX' where X is an integer
      return false;
    }
    return true;
  }

  Future pickImage(bool gallery) async {
    try {
      XFile? image;
      if (gallery) {
        image = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        image = await ImagePicker().pickImage(source: ImageSource.camera);
      }
      if (image == null) return [];
      final imageTemp = File(image.path);
      setState(() => receipt_image = imageTemp);
      final inputImage = InputImage.fromFile(receipt_image!);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      List<ReceiptPrice> prices = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            if (element.text != null && isPrice(element.text)) {
              // removes dollar sign if it exists
              if (element.text.runes.first == 36) {
                prices.add(ReceiptPrice(element.text.substring(1)));
              } else {
                prices.add(ReceiptPrice(element.text));
              }
            }
          }
        }
      }
      textRecognizer.close();
      setState(() {
        this.rplist = prices;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Receipt Scanning'),
        backgroundColor: light_orange,
      ),
      body: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 8.0,),
              Expanded(
                child: RoundedButton(
                  onPressed: () => pickImage(true),
                  title: "Pick from Gallery",
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8.0,),
              Expanded(
                child: RoundedButton(
                  onPressed: () => pickImage(false),
                  title: "Take Picture",
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8.0,),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Items',
                      style: appFontStyle.copyWith(fontSize: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              rplist.add(ReceiptPrice('0.00'));
                            });
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 30.0,
                            color: appOrange,
                          ),
                          label: Text(
                            'Prices',
                             style: appFontStyle.copyWith(fontSize: 30, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
        Container(
          child: IntrinsicHeight(
            child: Row(
              children: [
                // items
                ReceiptItems(rilist, itemstream),
                VerticalDivider(
                  color: Colors.blueGrey,
                  thickness: 0.7,
                ),
                // prices
                ReceiptPrices(rplist),
              ],
            ),
          ),
        ),
        //receipt_image != null ? Image.file(receipt_image!): Text("no image selected")
      ]),
    );
  }
}
