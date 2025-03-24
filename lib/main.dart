import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing
import 'package:xml/xml.dart' as xml; // For XML parsing

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _responseText = "Press the button to fetch data";

  Future<void> fetchData() async {
    final url = Uri.parse('https://9877-125-18-213-98.ngrok-free.app/hello/hi'); // Your MuleSoft API

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        String contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/json')) {
          // Handle JSON Response
          final jsonResponse = jsonDecode(response.body);
          setState(() {
            _responseText = jsonResponse['message'] ?? "No message found";
          });

        } else if (contentType.contains('application/xml') || contentType.contains('text/xml')) {
          // Handle XML Response
          final document = xml.XmlDocument.parse(response.body);
          final message = document.findAllElements('message').isNotEmpty
              ? document.findAllElements('message').single.text
              : "No message found in XML";
          setState(() {
            _responseText = message;
          });

        } else {
          // Handle Plain Text Response
          setState(() {
            _responseText = response.body.isNotEmpty ? response.body : "Empty response";
          });
        }

      } else {
        setState(() {
          _responseText = "Failed to load data (Error: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _responseText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MuleSoft API Fetch')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _responseText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: Text("Fetch Data"),
            ),
          ],
        ),
      ),
    );
  }
}
