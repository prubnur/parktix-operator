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
                  print(result.rawContent);
                  if (result!=null && result.rawContent.toString().isNotEmpty) {
                    l = result.rawContent.split("#");
                  }
                });
                if (l!=null && l[0] == 'ParkTix') {
                  if (l != null && l.length > 2 && l[1] != null &&
                      l[2] != null && l[3] != null) {
                    var docRef = ref.child(l[1]).child(l[2]);
                    if (l[3] == 'en') {
                      docRef.update({
                        'status': 'PENDING',
                        'token': uuid.v4(),
                      });
                      setState(() {
                        flag = true;
                      });
                    }
                    else if (l[3] == 'ex') {
                      docRef.once().then((value) {
                        if (value.value['token'] == l[4]) {
                          docRef.update({
                            'status': 'READY',
                            'token': null
                          });
                          setState(() {
                            flag = true;
                          });
                        }
                        else {
                          invalidQR();
                        }
                      });
                    }
                    else {
                      invalidQR();
                    }
                  }
                  else {
                    invalidQR();
                  }
                }
                else {
                  invalidQR();
                }
              },
            ),
            Divider(),
            l!=null && l[0] == 'ParkTix' ? Text(l[1]) : Text(""),
            Divider(),
            l!=null && l[0] == 'ParkTix' ? Text(l[2]) : Text(""),
            Divider(),
            l!=null && l[0] == 'ParkTix' ? Text(l[3] == 'en' ? 'Entry' : 'Exit') : Text(""),
            Divider(),
            flag==true ? Icon(Icons.check) : Icon(Icons.clear),
            Divider(),
            l!=null && l[0]=='ParkTix' && l[2] == 'ex' ? Text(l[4]) : Text(""),
            Divider(),
          ],
        ),
      ),
    );
  }

  void invalidQR() {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Text("Error"),
          content: Text("Invalid QR code"),
          actions: <Widget>[
            FlatButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"))
          ],
        )
    );
  }
}
