import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  var result;
  List<String> l;

  var db = Firestore.instance;
  bool flag = false;

  Uuid uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              label: Text("Scan"),
              onPressed: () async {
                setState(() {
                  flag = false;
                });
                var temp = await BarcodeScanner.scan();
                setState(() {
                  result = temp;
                  if (result!=null && result.rawContent.toString().isNotEmpty) {
                    l = result.rawContent.split(":");
                  }
                });
                if (l!=null && l.length > 2 && l[0]!=null && l[1]!=null && l[2]!=null) {
                  var docRef = db.collection('users').document(l[0]).collection('vehicles').document(l[1]);
                  if (l[2]=='en') {
                    docRef.updateData({
                      'status': 'PENDING',
                      'token': uuid.v4(),
                    });
                  }
                  else if (l[2]=='ex') {
                    db.runTransaction((transaction) {
                      return transaction.get(docRef).then((snap) {
                        if (snap.data['token'] != l[3]) {
                          throw "Invalid QR Code! Token does not match!";
                        }
                        transaction.update(docRef, {
                          'status': 'READY',
                          'token': null,
                        });
                      });
                    }).catchError((error) {
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          title: Text("Error"),
                          content: Text("Invalid QR code"),
                          actions: <Widget>[
                            FlatButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
                          ],
                        )
                      );
                    });
                  }
                  setState(() {
                    flag = true;
                  });
                }
              },
            ),
            Divider(),
            l!=null && l.length > 0 && l[0] != null ? Text(l[0]) : Text(""),
            Divider(),
            l!=null && l.length > 0 && l[1] != null ? Text(l[1]) : Text(""),
            Divider(),
            l!=null && l.length > 0 && l[2] != null ? Text(l[2] == 'en' ? 'Entry' : 'Exit') : Text(""),
            Divider(),
            flag==true ? Icon(Icons.check) : Text(""),
            Divider(),
            l!=null && l.length > 0 && l[2] == 'ex' ? Text(l[3]) : Text(""),
            Divider(),
          ],
        ),
      ),
    );
  }
}
