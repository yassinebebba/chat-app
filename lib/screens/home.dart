import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/add_contact.dart';
import 'package:bebba/state_manager/state_manager.dart';
import 'package:bebba/widgets/contact_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants.dart';

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> with AutomaticKeepAliveClientMixin {
  @override
  bool wantKeepAlive = true;

  List<Map<String, Object?>> _contacts = [];

  Future<void> _getContacts() async {
    List<Map<String, Object?>> contacts = await LocalDatabase.getContacts();
    List<Map<String, Object?>> temp = [];
    for (int i = 0; i < contacts.length; ++i) {
      final lastMessage = await LocalDatabase.getLastMessage(
          contacts[i]['country_code'] as String,
          contacts[i]['phone_number'] as String);
      if (lastMessage != null) {
        temp.add({...contacts[i], 'last_message': lastMessage['content']});
      } else {
        temp.add({...contacts[i], 'last_message': ''});
      }
    }
    setState(() => _contacts = temp);
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.contacts.status;
    if (status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.contacts,
      ].request();
    }
  }

  Future<void> _updateContact(
      String countryCode, String phoneNumber, String message) async {
    for (int i = 0; i < _contacts.length; ++i) {
      if (_contacts[i]['phone_number'] == phoneNumber) {
        setState(() {
          _contacts[i]['last_message'] = message;
          _contacts.insert(0, _contacts[i]);
          _contacts.removeAt(i + 1);
        });
        break;
      }
    }
  }

  late IOWebSocketChannel _channel;
  final streamController = StreamController.broadcast();
  final internalStreamController = StreamController.broadcast();
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> _addPrivateMessage(Map<String, dynamic> data) async {
    Map<String, dynamic> user = (await LocalDatabase.getUser())!;
    if (data['sender_country_code'] != user['country_code'] &&
        data['sender_phone_number'] != user['phone_number']) {
      String senderCO = data['sender_country_code'];
      String senderPN = data['sender_phone_number'];
      String senderName = '$senderCO$senderPN';

      for (int i = 0; i < _contacts.length; ++i) {
        String co = _contacts[i]['country_code'] as String;
        String pn = _contacts[i]['phone_number'] as String;

        if ( '$co$pn' == '$senderCO$senderPN') {
          senderName = _contacts[i]['name'] as String;
          break;
        }
      }
      _channel.sink.add(
        jsonEncode(
          {
            'type': 'message_delivered',
            'sender_country_code': data['receiver_country_code'],
            'sender_phone_number': data['receiver_phone_number'],
            'receiver_country_code': data['sender_country_code'],
            'receiver_phone_number': data['sender_phone_number'],
            'hash': data['hash'],
          },
        ),
      );
      _notifications.show(
        0,
        senderName,
        data['message'],
        const NotificationDetails(
            android: AndroidNotificationDetails('channel id', 'channel name',
                importance: Importance.max),
            iOS: IOSNotificationDetails()),
        payload: 'message',
      );
      await LocalDatabase.insertMessage(
          data['sender_country_code'],
          data['sender_phone_number'],
          data['receiver_country_code'],
          data['receiver_phone_number'],
          'text',
          data['message'],
          'received',
          data['hash'],
          data['timestamp'],
          2);
      await _updateContact(data['sender_country_code'],
          data['sender_phone_number'], data['message']);
    } else {
      await LocalDatabase.insertMessage(
          data['sender_country_code'],
          data['sender_phone_number'],
          data['receiver_country_code'],
          data['receiver_phone_number'],
          'text',
          data['message'],
          'sent',
          data['hash'],
          data['timestamp'],
          0);
      await _updateContact(data['receiver_country_code'],
          data['receiver_phone_number'], data['message']);
    }
  }

  Future<void> _deletePrivateMessage(Map<String, dynamic> data) async {
    await LocalDatabase.deleteMessage(data['hash']);
    internalStreamController.sink
        .add({'event': 'delete_message', 'hash': data['hash']});
  }

  Future<void> _messageDelivered(data) async {
    await LocalDatabase.markMessageAsDelivered(data['hash']);
    internalStreamController.sink.add({'event': 'reload_messages'});
  }

  Future<void> _messageRead(data) async {
    await LocalDatabase.markMessageAsRead(data['hash']);
    internalStreamController.sink.add({'event': 'reload_messages'});
  }

  Future<void> _imageMessage(data) async {
    String userPhoneNumber =
        (await LocalDatabase.getUser())!['phone_number'] as String;
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    String filePath = '$appDocumentsPath/images/${data['hash']}.png';
    Uint8List bytes = base64.decode(data['image']);
    File file = await File(filePath).writeAsBytes(bytes);
    internalStreamController.sink.add(
      {
        'event': 'image_message',
        'sender_country_code': data['sender_county_code'],
        'sender_phone_number': data['sender_phone_number'],
        'receiver_country_code': data['receiver_country_code'],
        'receiver_phone_number': data['receiver_phone_number'],
        'message': file.path,
        'content_type': 'image',
        'hash': data['hash'],
        'timestamp': data['timestamp'],
      },
    );

    if (data['sender'] != userPhoneNumber) {
      String name = data['sender'];
      for (int i = 0; i < _contacts.length; ++i) {
        String pn = _contacts[i]['phone_number'] as String;
        if (pn.replaceAll(' ', '').contains(name)) {
          name = _contacts[i]['name'] as String;
          break;
        }
      }

      _channel.sink.add(
        jsonEncode(
          {
            'type': 'message_delivered',
            'sender_country_code': data['receiver_country_code'],
            'sender_phone_number': data['receiver_phone_number'],
            'receiver_country_code': data['sender_country_code'],
            'receiver_phone_number': data['sender_phone_number'],
            'hash': data['hash'],
          },
        ),
      );

      _notifications.show(
        0,
        name,
        '📸',
        const NotificationDetails(
          android: AndroidNotificationDetails('channel id', 'channel name',
              importance: Importance.max),
          iOS: IOSNotificationDetails(),
        ),
        payload: 'Image',
      );
      await LocalDatabase.insertMessage(
          data['sender_country_code'],
          data['sender_phone_number'],
          data['receiver_country_code'],
          data['receiver_phone_number'],
          'image',
          file.path,
          'received',
          data['hash'],
          data['timestamp'],
          2);
    } else {
      await LocalDatabase.insertMessage(
          data['sender_country_code'],
          data['sender_phone_number'],
          data['receiver_country_code'],
          data['receiver_phone_number'],
          'image',
          file.path,
          'sent',
          data['hash'],
          data['timestamp'],
          0);
    }
  }

  void _listen(StreamController controller) {
    controller.stream.listen(
      (event) async {
        Map<String, dynamic> data = jsonDecode(event);
        switch (data['type']) {
          case 'private_message':
            _addPrivateMessage(data);
            break;
          case 'delete_private_message':
            _deletePrivateMessage(data);
            break;
          case 'message_delivered':
            _messageDelivered(data);
            break;
          case 'message_read':
            _messageRead(data);
            break;
          case 'image_message':
            _imageMessage(data);
            break;
        }
      },
    );
  }

  Future<IOWebSocketChannel> _connect() async {
    String accessToken =
        (await LocalDatabase.getUser())!['access_token'] as String;
    return IOWebSocketChannel.connect(WSS_USER + accessToken + '/');
  }

  final stateManager = StateManager();

  @override
  void initState() {
    stateManager.setCurrentState(States.HOME);
    stateManager.setCurrentContactNumber(null);
    _connect().then((socket) {
      _channel = socket;
      streamController.addStream(socket.stream);
    });
    _checkPermissions();
    super.initState();
    _getContacts();
    _listen(streamController);

    var initializationSettingsAndroid = const AndroidInitializationSettings(
        '@mipmap/icon'); // <- default icon name is @mipmap/ic_launcher
    var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    _notifications.initialize(initializationSettings);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshHome() async {
    List<Map<String, Object?>> contacts = await LocalDatabase.getContacts();
    setState(() => _contacts = contacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bebba",
          style: TextStyle(
              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.cyan[900],
        actions: <Widget>[
          const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.search),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                const PopupMenuItem(child: Text('New Group')),
                const PopupMenuDivider(height: 0),
                const PopupMenuItem(
                  padding: EdgeInsets.only(left: 16),
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Contacts()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                Map<String, Object?> item = _contacts[index];
                return Column(
                  children: <Widget>[
                    ContactWidget(
                      meta: {
                        'profilePicture': 'assets/images/logo.png',
                        'name': item['name'],
                        'countryCode': item['country_code'],
                        'phoneNumber': item['phone_number'],
                        'lastMessage': item['last_message'] ?? '',
                        'refreshHome': _refreshHome,
                        'channel': _channel,
                        'streamController': streamController,
                        'internalStreamController': internalStreamController,
                      },
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
}
