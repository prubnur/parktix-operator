import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  var result;
  List<String> l;

  var ref = FirebaseDatabase.instance.reference().child('vehicles');
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
                    l = result.rawContent.split("#");
                  }
                });
                if (l!=null && l.length > 2 && l[0]!=null && l[1]!=null && l[2]!=null) {
                  var docRef = ref.child(l[0]).child(l[1]);
                  if (l[2]=='en') {
                    docRef.update({
                      'status': 'PENDING',
                      'token': uuid.v4(),
                    });
                    setState(() {
                      flag = true;
                    });
                  }
                  else if (l[2]=='ex') {
                    docRef.once().then((value) {
                      if (value.value['token'] == l[3]) {
                        docRef.update({
                          'status': 'READY',
                          'token': null
                        });
                        setState(() {
                          flag = true;
                        });
                      }
                      else {
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
                      }
                    });
                  }
                  else {
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
                  }
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
            flag==true ? Icon(Icons.check) : Icon(Icons.clear),
            Divider(),
            l!=null && l.length > 0 && l[2] == 'ex' ? Text(l[3]) : Text(""),
            Divider(),
          ],
        ),
      ),
    );
  }
}
