import 'dart:async';
import 'dart:io';

import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/home.dart';
import 'package:bebba/screens/login.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'background/app_retain_widget.dart';
import 'foreground_service/foreground_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State<MyApp> with WidgetsBindingObserver {
  ReceivePort? _receivePort;

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 300000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'access_token', value: (await LocalDatabase.getUser())!['access_token'] as String);

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is DateTime) {
          print('receive timestamp: $message');
        } else if (message is int) {
          print('receive updateCount: $message');
        }
      });

      return true;
    }

    return false;
  }

  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // _startForegroundTask();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initForegroundTask();
  }

  @override
  void dispose() {
    _receivePort?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<Map<String, Object?>?> init() async {
    await LocalDatabase.init();
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    await Directory(appDocumentsDirectory.path + '/images/').create(recursive: true);
    return LocalDatabase.getUser();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Bebba';
    return MaterialApp(
      title: title,
      initialRoute: '/',
      home: AppRetainWidget(
        child: FutureBuilder(
          future: init(),
          builder: (BuildContext context, AsyncSnapshot<Map<String, Object?>?> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!['is_authenticated'] == 1) {
                return Home();
              } else {
                return const Login();
              }
            } else {
              return const Login();
            }
          },
        ),
      ),
    );
  }
}
