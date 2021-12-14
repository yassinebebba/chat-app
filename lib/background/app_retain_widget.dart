import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppRetainWidget extends StatelessWidget {
  const AppRetainWidget({required this.child});

  final Widget child;

  final _channel = const MethodChannel('com.yassinebebba.bebba/app_retain');

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          if (Navigator.of(context).canPop()) {
            return true;
          } else {
            _channel.invokeMethod('sendToBackground');
            return false;
          }
        } else {
          return true;
        }
      },
      child: child,
    );
  }
}
