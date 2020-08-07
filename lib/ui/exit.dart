import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

class Exit extends StatefulWidget {
  @override
  _ExitState createState() => _ExitState();
}

class _ExitState extends State<Exit> with AutomaticKeepAliveClientMixin{
  var result;
  List<String> l;

  var ref = FirebaseDatabase.instance.reference().child('vehicles');
  bool flag = false;

  Uuid uuid = Uuid();

  String regno;

  var rootRef = FirebaseDatabase.instance.reference();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            flag ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.check, size: 80,),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                regno!=null ? Text(regno, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300),) : Text(""),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                l!=null && l[0] == 'ParkTix' ? Text(l[3] == 'en' ? 'Entry' : 'Exit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300)) : Text(""),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                l!=null && l[0]=='ParkTix' && l[3] == 'ex' ? Text(l[4], style: TextStyle(fontWeight: FontWeight.w300)) : Text(""),
              ],
            ) : Icon(Icons.clear, size: 80,),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15,),
            FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              label: Text("Scan Exit Code"),
              onPressed: () async {
                setState(() {
                  flag = false;
                  regno = null;
                  l = null;
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
                      showDialog(
                          context: context,
                          child: AlertDialog(
                            title: Text("Error"),
                            content: Text("This is an entry code!"),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"))
                            ],
                          )
                      );
                    }
                    else if (l[3] == 'ex') {
                      docRef.once().then((value) {
                        if (value.value!=null && value.value["status"]=="ACCEPTED" && value.value['token'] == l[4]) {
                          Map<String, dynamic> updates = {};
                          String temp = value.value["regno"];
                          String logID = value.value['logID'];

                          updates['/logs/' + value.value['locID'] + '/' + value.value['logID'] + '/exitts'] = DateTime.now().millisecondsSinceEpoch;
                          updates['/logs/' + value.value['locID'] + '/' + value.value['logID'] + '/status'] = "EXITED";

                          updates['/vehicles/' + l[1] + '/' + l[2] + '/status'] = "READY";
                          updates['/vehicles/' + l[1] + '/' + l[2] + '/token'] = null;
                          updates['/vehicles/' + l[1] + '/' + l[2] + '/amount'] = null;
                          updates['/vehicles/' + l[1] + '/' + l[2] + '/locID'] = null;
                          updates['/vehicles/' + l[1] + '/' + l[2] + '/locName'] = null;
                          updates['/vehicles/' + l[1] + '/' + l[2] + '/logID'] = null;

                          updates['/visits/' + l[1] + '/' + logID + '/exitts'] = DateTime.now().millisecondsSinceEpoch;
                          updates['/visits/' + l[1] + '/' + logID + '/status'] = "EXITED";

                          rootRef.update(updates).then((value) {
                            setState(() {
                              regno = temp;
                              flag = true;
                            });
                          }, onError: (error) {
                            showDialog(
                                context: context,
                                child: AlertDialog(
                                  title: Text("Error"),
                                  content: Text(error.toString()),
                                  actions: <Widget>[
                                    FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK")
                                    )
                                  ],
                                )
                            );
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
