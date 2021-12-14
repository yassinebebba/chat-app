// import 'package:bebba/screens/chat_page.dart';
// import 'package:bebba/widgets/received_message_widget.dart';
// import 'package:bebba/widgets/sent_message_widget.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:bebba/controllers/user.dart';
//
// class MessageBoxWidget extends StatefulWidget {
//   @override
//   _MessageBoxWidget createState() => _MessageBoxWidget();
// }
//
// class _MessageBoxWidget extends State<MessageBoxWidget> {
//   final List<Widget> messages = <Widget>[
//     Container(
//       decoration: const BoxDecoration(
//           image: DecorationImage(
//               image: AssetImage("assets/bg_chat.jpg"), fit: BoxFit.cover)),
//       child: ListView(
//         children: const [
//           SentMessageWidget(message: "Hello"),
//           ReceivedMessageWidget(message: "Hi, how are you"),
//           SentMessageWidget(message: "I am great how are you doing"),
//           ReceivedMessageWidget(message: "I am also fine"),
//           SentMessageWidget(message: "Can we meet tomorrow?"),
//           ReceivedMessageWidget(
//               message: "Yes, of course we will meet tomorrow"),
//         ],
//       ),
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(8),
//       itemCount: messages.length,
//       itemBuilder: (BuildContext context, int index) {
//         return messages[index];
//       },
//     );
//   }
// }
