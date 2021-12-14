import 'dart:convert';

import 'package:bebba/constants.dart';
import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/state_manager/state_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'otp.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _State createState() => _State();
}

class _State extends State<Login> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final stateManager = StateManager();

  @override
  void initState() {
    super.initState();
    stateManager.setCurrentState(States.LOGIN);
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
                'Sign in',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _countryCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Country code',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Phone number',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: RaisedButton(
                textColor: Colors.white,
                color: Colors.blue,
                child: const Text('Login'),
                onPressed: () {
                  _handleLogin();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    final response = await http.post(
      Uri.parse(LOGIN),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'country_code': _countryCodeController.text,
          'phone_number': _phoneNumberController.text,
        },
      ),
    );

    await LocalDatabase.insertUser(
        _countryCodeController.text, _phoneNumberController.text);
    if (response.statusCode == 200) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const OTP()));
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const OTP()));
      Fluttertoast.showToast(
          msg: "Wrong phone number ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 3);
    }
  }
}
