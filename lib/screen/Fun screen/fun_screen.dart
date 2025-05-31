import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FunScreen extends StatefulWidget {
  @override
  _FunScreenState createState() => _FunScreenState();
}

class _FunScreenState extends State<FunScreen> {
  String _joke = "Press the button to get a joke!";

  Future<void> _fetchJoke() async {
    final response = await http.get(
      Uri.parse('https://official-joke-api.appspot.com/random_joke'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _joke = "${data['setup']} - ${data['punchline']}";
      });
    } else {
      setState(() {
        _joke = "Failed to load joke.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fun Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _joke,
              style: TextStyle(fontSize: 24, textAlign: TextAlign.center),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchJoke, child: Text('Get a Joke')),
          ],
        ),
      ),
    );
  }
}
