import 'package:flutter/material.dart';
import 'dart:math';

class ConnectScreen extends StatefulWidget {
  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<String> users = ["Alice", "Bob", "Charlie", "Diana", "Eve"];
  String connectedUser = "";

  void _connect() {
    // Simulate connecting to a random user
    setState(() {
      connectedUser = users[Random().nextInt(users.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              connectedUser.isEmpty
                  ? "Connect with a random user!"
                  : "Connected to: $connectedUser",
              style: TextStyle(fontSize: 24, textAlign: TextAlign.center),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _connect, child: Text('Connect')),
          ],
        ),
      ),
    );
  }
}
