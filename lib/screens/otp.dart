import 'dart:convert';

import 'package:bebba/constants.dart';
import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/home.dart';
import 'package:bebba/state_manager/state_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class OTP extends StatefulWidget {
  const OTP({Key? key}) : super(key: key);

  @override
  _State createState() => _State();
}

class _State extends State<OTP> {
  final TextEditingController _otpController = TextEditingController();
  final stateManager = StateManager();

  @override
  void initState() {
    super.initState();
    stateManager.setCurrentState(States.OTP);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bebba'),
        backgroundColor: Colors.cyan[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'OTP verification',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'OTP',
                ),
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: RaisedButton(
                textColor: Colors.white,
                color: Colors.blue,
                child: const Text('Verify'),
                onPressed: () {
                  _handleVerification();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleVerification() async {
    final user = jsonDecode(jsonEncode(await LocalDatabase.getUser()));
    final response = await http.post(
      Uri.parse(VERIFY_OTP),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'country_code': user['country_code'],
          'phone_number': user['phone_number'],
          'otp': int.parse(_otpController.text),
        },
      ),
    );
    if (response.statusCode == 200) {
      await LocalDatabase.authorizeUser(jsonDecode(response.body)['access_token']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),
        (Route<dynamic> route) => false,
      );
    } else {
      Fluttertoast.showToast(msg: "Invalid OTP", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 3);
    }
  }
}
