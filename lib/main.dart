import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing
import 'package:xml/xml.dart' as xml;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Dark mode for modern look
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
  int? _statusCode;
  bool _isLoading = false; // Track loading state

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _responseText = "Fetching data...";
      _statusCode = null;
    });

    final url = Uri.parse('https://bb50-125-18-213-98.ngrok-free.app/hello/hi'); // Your MuleSoft API

    try {
      final response = await http.get(url);
      setState(() {
        _statusCode = response.statusCode;
      });

      if (response.statusCode == 200) {
        String contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/json')) {
          final jsonResponse = jsonDecode(response.body);
          setState(() {
            _responseText = jsonResponse['message'] ?? "No message found";
          });

        } else if (contentType.contains('application/xml') || contentType.contains('text/xml')) {
          final document = xml.XmlDocument.parse(response.body);
          final message = document.findAllElements('message').isNotEmpty
              ? document.findAllElements('message').single.text
              : "No message found in XML";
          setState(() {
            _responseText = message;
          });

        } else {
          setState(() {
            _responseText = response.body.isNotEmpty ? response.body : "Empty response";
          });
        }

      } else {
        setState(() {
          _responseText = "Error ${response.statusCode}: ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        _responseText = "Network Error: $e";
        _statusCode = null;
      });
    }

    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MuleSoft API Fetch'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _isLoading
                ? CircularProgressIndicator() // Show loader when fetching
                : Column(
              children: [
                Text(
                  _responseText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                if (_statusCode != null) // Show status code if available
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "Status Code: $_statusCode",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : fetchData, // Disable when loading
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Fetch Data"),
            ),
          ],
        ),
      ),
    );
  }
}
