import 'dart:convert';
import 'dart:isolate';

import 'package:bebba/controllers/local_database.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/io.dart';

import '../constants.dart';

void startCallback() async {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  int updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // You can use the getData function to get the data you saved.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'access_token');
    print('access_token: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    LocalDatabase.getUser().then(
      (value) {
        print(value!['access_token']);
        final _channel = IOWebSocketChannel.connect(
            WSS_USER + (value['access_token'] as String) + '/');
        final _notifications = FlutterLocalNotificationsPlugin();
        _channel.stream.listen(
          (event) async {
            String userPhoneNumber =
                (await LocalDatabase.getUser())!['phone_number'] as String;
            Map<String, dynamic> data = jsonDecode(event);
            String phoneNumber = data['sender'] == userPhoneNumber
                ? data['receiver']
                : data['sender'];
            if (data['sender'] != userPhoneNumber) {
              String name = data['sender'];
              _notifications.show(
                0,
                name,
                data['message'],
                const NotificationDetails(
                    android: AndroidNotificationDetails(
                        'channel id', 'channel name',
                        importance: Importance.max),
                    iOS: IOSNotificationDetails()),
                payload: 'message',
              );
            }
          },
        );
      },
    );
    FlutterForegroundTask.updateService(
        notificationTitle: 'FirstTaskHandler',
        notificationText: timestamp.toString(),
        callback: updateCount >= 10 ? updateCallback : null);

    // Send data to the main isolate.
    sendPort?.send(timestamp);
    sendPort?.send(updateCount);

    updateCount++;
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    print('onButtonPressed >> $id');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }
}

void updateCallback() {
  FlutterForegroundTask.setTaskHandler(SecondTaskHandler());
}

class SecondTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'SecondTaskHandler',
        notificationText: timestamp.toString());

    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }
}
