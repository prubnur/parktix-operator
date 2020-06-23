import 'package:flutter/material.dart';
import 'package:parktixspaceadmin/ui/entry.dart';
import 'package:parktixspaceadmin/ui/exit.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("ParkTix-O", style: TextStyle(fontSize: 30),),
            centerTitle: false,
            bottom: TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.transit_enterexit), text: "Entry",),
                  Tab(icon: Icon(Icons.exit_to_app), text: "Exit",),
                ]
            ),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.account_circle, size: 30,), onPressed: () {
//                Navigator.push(context, MaterialPageRoute(builder: (context) => User()));
              })
            ],
          ),
          body: TabBarView(
              children: [
                Entry(),
                Exit()
              ]
          ),
        )
    );
  }
}
