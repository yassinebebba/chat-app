import 'dart:convert';

import 'package:bebba/constants.dart';
import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/home.dart';
import 'package:bebba/state_manager/state_manager.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Contacts extends StatefulWidget {
  @override
  _Contacts createState() => _Contacts();
}

class _Contacts extends State<Contacts> {
  void _getContacts() async {
    List<Contact> contacts = await ContactsService.getContacts(withThumbnails: false);
    List<Map<String, String>> phoneNumbers = [];
    for (int i = 0; i < contacts.length; ++i) {
      List<String> list = contacts[i].phones![0].value!.split(' ');
      Map<String, String> temp = {};
      temp['country_code'] = list[0];
      temp['phone_number'] = list.getRange(1, list.length).join();
      phoneNumbers.add(temp);
    }

    final response = await http.post(
      Uri.parse(CHECK_CONTACT),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'access_token': (await LocalDatabase.getUser())!['access_token'],
          'phone_numbers': phoneNumbers,
        },
      ),
    );
    if (response.statusCode == 200) {
      List<dynamic> phoneNumbers = jsonDecode(response.body)['phone_numbers'];
      List<Contact> temp = [];
      for (int i = 0; i < contacts.length; ++i) {
        List<String> contact = contacts[i].phones![0].value!.split(' ');
        String countryCode = contact[0];
        String phoneNumber = contact.getRange(1, contact.length).join();
        for (int j = 0; j < phoneNumbers.length; ++j) {
          if (phoneNumbers[j]['country_code'] == countryCode && phoneNumbers[j]['phone_number'] == phoneNumber) {
            temp.add(contacts[i]);
          }
        }
      }
      setState(() => _contacts = temp);
    } else {
      Fluttertoast.showToast(msg: "Something went wrong", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 3);
    }
  }

  List<Contact> _contacts = [];

  final stateManager = StateManager();

  @override
  void initState() {
    stateManager.setCurrentState(States.ADD_CONTACT);
    super.initState();
    // WidgetsBinding.instance?.addPostFrameCallback((_) async => _getContacts());
    _getContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.cyan[900],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final item = _contacts[index];
                String name = item.displayName!;
                List<String> number = item.phones![0].value!.split(' ');
                String countryCode = number[0];
                String phoneNumber = number.getRange(1, number.length).join();
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _addContact(name, countryCode, phoneNumber),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      child: Image.asset('assets/images/logo.png'),
                                    ),
                                    title: Text(name),
                                    subtitle: Text(
                                      '$countryCode $phoneNumber',
                                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addContact(String name, String countryCode, String phoneNumber) {
    LocalDatabase.insertContact(name, countryCode, phoneNumber);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Home()),
      (Route<dynamic> route) => false,
    );
  }
}
