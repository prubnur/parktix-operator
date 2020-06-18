import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  var result;
  List<String> l;

  var db = Firestore.instance;
  bool flag = false;

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
                  db.collection('users').document(l[0]).collection('vehicles').document(l[1]).updateData({
                    'status': l[2] == 'en' ? 'PENDING' : 'READY',
                  });
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
            flag==true ? Icon(Icons.check) : Text("")
          ],
        ),
      ),
    );
  }
}
