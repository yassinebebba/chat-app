import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/chat_page.dart';
import 'package:flutter/material.dart';

class ContactWidget extends StatelessWidget {
  Map<String, dynamic> meta;

  ContactWidget({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(meta: {
                  'countryCode': meta['countryCode'],
                  'phoneNumber': meta['phoneNumber'],
                  'name': meta['name'],
                  'channel': meta['channel'],
                  'streamController': meta['streamController'],
                  'internalStreamController': meta['internalStreamController'],
                }),
              ),
            ),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => _options(context),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    title: Text(meta['name']),
                    subtitle: Text(
                      meta['lastMessage'],
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _options(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${meta['name']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text('Are you sure you want to delete this contact?'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            await LocalDatabase.deleteContactByPhoneNumber(meta['countryCode'], meta['phoneNumber']);
            await meta['refreshHome']();
            Navigator.of(context).pop();
          },
          child: const Text('Confirm'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
