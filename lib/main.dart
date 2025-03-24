import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing
import 'package:xml/xml.dart' as xml;
import 'package:shared_preferences/shared_preferences.dart'; // For saving last used URL

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _responseText = "Enter an API URL and press Fetch";
  int? _statusCode;
  bool _isLoading = false;
  TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  // Load last used API URL from storage
  Future<void> _loadSavedUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('api_url');
    if (savedUrl != null) {
      _urlController.text = savedUrl;
    }
  }

  // Save entered API URL to storage
  Future<void> _saveUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
  }

  Future<void> fetchData() async {
    String apiUrl = _urlController.text.trim();
    if (apiUrl.isEmpty || Uri.tryParse(apiUrl) == null || !Uri.tryParse(apiUrl)!.isAbsolute) {
      setState(() {
        _responseText = "Invalid URL. Please enter a valid API URL.";
        _statusCode = null;
      });
      return;
    }

    await _saveUrl(apiUrl); // Save API URL for next time

    setState(() {
      _isLoading = true;
      _responseText = "Fetching data...";
      _statusCode = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
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
      _isLoading = false;
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
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "API URL",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            SizedBox(height: 15),
            _isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                Text(
                  _responseText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                if (_statusCode != null)
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
              onPressed: _isLoading ? null : fetchData,
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
