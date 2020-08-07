import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Entry extends StatefulWidget {
  @override
  _EntryState createState() => _EntryState();
}

class _EntryState extends State<Entry> with AutomaticKeepAliveClientMixin {

  var result;
  List<String> l;

  String regno;
  String phone;
  int amount;
  String locID;
  String locName;
  
  final auth = FirebaseAuth.instance;

  var ref = FirebaseDatabase.instance.reference().child('vehicles');
  
  var rootRef = FirebaseDatabase.instance.reference();
  
  bool flag = false;

  Uuid uuid = Uuid();

  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }
  
  getUser() async {
    FirebaseUser user = await auth.currentUser();
    rootRef.child('operators').child(user.phoneNumber).once().then((value) {
      rootRef.child('locations').child(value.value).once().then((val) {
        amount = val.value['price'];
        locID = val.key;
        locName = val.value['name'];
      });
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !isLoading ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            flag ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.check, size: 80,),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                regno!=null ? Text(regno, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300)) : Text(""),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                l!=null && l[0] == 'ParkTix' ? Text(l[3] == 'en' ? 'Entry' : 'Exit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300)) : Text(""),
              ],
            ) : Icon(Icons.clear, size: 80,),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15,),
            FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              label: Text("Scan Entry Code"),
              onPressed: () async {
                setState(() {
                  flag = false;
                  l=null;
                  regno = null;
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
                      String temp=null;
                      await docRef.once().then((value) {
                        if (value.value!=null && value.value["status"]=="READY") {
                          temp = value.value['regno'];
                          setState(() {
                            regno = temp;
                          });
                        }
                      });
                      if (temp!=null) {
                        int f=1;
                        await rootRef.child('allowed_vehicles').child(locID).once().then((value) {
                          Map<String, dynamic> updates = {};
                          var date = DateFormat('dd-MM-yyyy').format(DateTime.now());
                          if (value.value!=null && value.value[l[1]]!=null && value.value[l[1]][regno]!=null) {
                            var newKey = rootRef.child('logs').child(locID).push().key;
                            debugPrint(temp);
                            updates['/logs/' + locID + '/' + newKey] = {
                              'vregno': regno,
                              'entryts': DateTime.now().millisecondsSinceEpoch,
                              'status': 'ENTERED',
                            };
                            updates['/visits/' + l[1] + '/' + newKey] = {
                              'date': date,
                              'locID': locID,
                              'locName': locName,
                              'status': 'ENTERED',
                              'entryts': DateTime.now().millisecondsSinceEpoch,
                              'regno': regno
                            };
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/status'] = "PENDING";
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/token'] = uuid.v4();
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/amount'] = amount;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/locID'] = locID;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/locName'] = locName;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/logID'] = newKey;
                          }
                          else if (value.value!=null && value.value['visitors']!=null &&
                              value.value['visitors'][date]!=null &&
                              value.value['visitors'][date][l[1]]!=null &&
                              value.value['visitors'][date][l[1]][regno]!=null) {
                            var newKey = value.value['visitors'][date][l[1]][regno]['vid'];

                            updates['/allowed_vehicles/' + locID + '/visitors/' + date + '/' + l[1] + '/' + regno] = null;

                            updates['/logs/' + locID + '/' + newKey] = {
                              'vregno': regno,
                              'entryts': DateTime.now().millisecondsSinceEpoch,
                              'status': 'ENTERED',
                              'oneTimeVisit': true
                            };

                            updates['/visits/' + l[1] + '/' + newKey + '/status'] = 'ENTERED';
                            updates['/visits/' + l[1] + '/' + newKey + '/entryts'] = DateTime.now().millisecondsSinceEpoch;

                            updates['/vehicles/' + l[1] + '/' + l[2] + '/status'] = "PENDING";
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/token'] = uuid.v4();
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/amount'] = amount;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/locID'] = locID;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/locName'] = locName;
                            updates['/vehicles/' + l[1] + '/' + l[2] + '/logID'] = newKey;
                          }
                          else {
                            invalidQR();
                            f=0;
                          }
                          if (f==1) {
                            rootRef.update(updates).then((value) {
                              setState(() {
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
                        });
                      }
                      else {
                        invalidQR();
                      }
//                      docRef.update({
//                        'status': 'PENDING',
//                        'token': uuid.v4(),
//                        'amount': amount,
//                        'locID': locID,
//                        'locName': locName
//                      }).then((value) {
//                        setState(() {
//                          flag = true;
//                        });
//                      },
//                      onError: (error) {
//                        showDialog(
//                            context: context,
//                            child: AlertDialog(
//                              title: Text("Error"),
//                              content: Text(error.toString()),
//                              actions: <Widget>[
//                                FlatButton(
//                                    onPressed: () => Navigator.pop(context),
//                                    child: Text("OK"))
//                              ],
//                            )
//                        );
//                      });
                    }
                    else if (l[3] == 'ex') {
                      showDialog(
                          context: context,
                          child: AlertDialog(
                            title: Text("Error"),
                            content: Text("This is an exit code!"),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"))
                            ],
                          )
                      );
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
      ) : Center(child: CircularProgressIndicator(),),
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
