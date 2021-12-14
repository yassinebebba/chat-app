import 'dart:async';
import 'dart:convert';
import 'package:bebba/controllers/local_database.dart';
import 'package:bebba/screens/youtube.dart';
import 'package:bebba/state_manager/state_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:bebba/widgets/received_message_widget.dart';
import 'package:bebba/widgets/sent_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  Map<String, dynamic> meta;

  ChatPage({required this.meta});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<Widget> selectedMessages = [];

  Widget copyIcon = const SizedBox.shrink();
  Widget deleteIcon = const SizedBox.shrink();

  void canICopy() {
    if (selectedMessages.length == 1) {
      var obj;
      if (selectedMessages.first is SentMessageWidget) {
        obj = (selectedMessages.first as SentMessageWidget).meta;
      } else {
        obj = (selectedMessages.first as ReceivedMessageWidget).meta;
      }
      if (!obj['deleted']) {
        setState(() {
          copyIcon = Padding(
            padding: const EdgeInsets.only(right: 0),
            child: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: obj['message']));
                  canICopy();
                  Fluttertoast.showToast(msg: "Message copied", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1);
                },
                icon: const Icon(Icons.copy)),
          );
        });
      }
    } else {
      setState(() {
        copyIcon = const SizedBox.shrink();
      });
    }
  }

  void addMe(Widget widget) {
    setState(() {
      deleteIcon = Padding(
        padding: const EdgeInsets.only(right: 0),
        child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[Text('Messages will be deleted forever')],
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          _deleteBulkMessages();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Delete'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.delete)),
      );
    });
    selectedMessages.add(widget);
    canICopy();
  }

  void removeMe(Widget widget) {
    selectedMessages.remove(widget);
    canICopy();
    if (selectedMessages.isEmpty) {
      setState(() {
        deleteIcon = const SizedBox.shrink();
      });
    }
  }

  void _deleteBulkMessages() async {
    await Future.forEach(selectedMessages, (msg) async {
      Map<String, dynamic> sender = (await LocalDatabase.getUser())!;
      if (msg is SentMessageWidget) {
        var obj = (msg as SentMessageWidget).meta;
        if (!obj['deleted']) {
          widget.meta['channel'].sink.add(
            jsonEncode(
              {
                'type': 'delete_private_message',
                'sender_country_code': sender['country_code'],
                'sender_phone_number': sender['phone_number'],
                'receiver_country_code': widget.meta['countryCode'],
                'receiver_phone_number': widget.meta['phoneNumber'],
                'hash': obj['hash'],
              },
            ),
          );
        } else {
          await LocalDatabase.deleteMessageForever(obj['hash']);
          widget.meta['internalStreamController'].sink.add({'event': 'reload_messages'});
        }
      } else {
        var obj = (msg as ReceivedMessageWidget).meta;
        await LocalDatabase.deleteMessageForever(obj['hash']);
        widget.meta['internalStreamController'].sink.add({'event': 'reload_messages'});
      }
    });

    setState(() {
      deleteIcon = copyIcon = const SizedBox.shrink();
      selectedMessages.clear();
    });
  }

  Future<void> _sendImage(String img64) async {
    Map<String, dynamic> sender = (await LocalDatabase.getUser())!;
    var bytes = utf8.encode('${DateTime.now().microsecondsSinceEpoch}.$sender.$img64');
    var hash = sha256.convert(bytes).toString();

    widget.meta['channel'].sink.add(
      jsonEncode(
        {
          'type': 'image_message',
          'sender_country_code': sender['country_code'],
          'sender_phone_number': sender['phone_number'],
          'receiver_country_code': widget.meta['countryCode'],
          'receiver_phone_number': widget.meta['phoneNumber'],
          'image': img64,
          'hash': hash,
          'timestamp': DateTime.now().microsecondsSinceEpoch,
        },
      ),
    );
  }

  bool active = true;
  late StreamSubscription<dynamic> streamSubscription;
  final _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  late Widget cameraIcon = IconButton(
    icon: const Icon(Icons.camera_alt),
    onPressed: () async {
      XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        final bytes = File(imageFile.path).readAsBytesSync();
        String img64 = base64Encode(bytes);
        _sendImage(img64);
      }
    },
  );

  Widget microphoneIcon = RawMaterialButton(
    onPressed: () {},
    elevation: 2.0,
    fillColor: Colors.cyan[900],
    constraints: const BoxConstraints.expand(width: 42, height: 42),
    child: const Icon(
      Icons.mic,
      color: Colors.white,
      size: 20,
    ),
    shape: const CircleBorder(),
  );

  Widget emojiKeyboard = const SizedBox.shrink();
  bool showEmojiKeyboard = false;
  late FocusNode _messageFocusNode;

  void _addPrivateMessage(Map<String, dynamic> data) async {
    if (mounted) {
      final user = (await LocalDatabase.getUser())!;
      if (data['sender_country_code'] == user['country_code'] && data['sender_phone_number'] == user['phone_number']) {
        setState(
          () => _messages.insert(
            0,
            SentMessageWidget(
              meta: {
                'message': data['message'],
                'content_type': data['content_type'],
                'channel': widget.meta['channel'],
                'streamController': widget.meta['streamController'],
                'countryCode': widget.meta['countryCode'],
                'phoneNumber': widget.meta['phoneNumber'],
                'hash': data['hash'],
                'timestamp': data['timestamp'],
                'deleted': false,
                'status': 0,
                'internalStreamController': widget.meta['internalStreamController'],
                'addMe': addMe,
                'removeMe': removeMe,
              },
            ),
          ),
        );
        _messageController.clear();
        _replaceIcons(_messageController.text);
      } else {
        if (active) {
          widget.meta['channel'].sink.add(
            jsonEncode(
              {
                'type': 'message_read',
                'sender_country_code': user['country_code'],
                'sender_phone_number': user['phone_number'],
                'receiver_country_code': data['sender_country_code'],
                'receiver_phone_number': data['sender_phone_number'],
                'hash': data['hash'],
              },
            ),
          );
        }
        setState(
          () => _messages.insert(
            0,
            ReceivedMessageWidget(
              meta: {
                'message': data['message'],
                'content_type': data['content_type'],
                'hash': data['hash'],
                'timestamp': data['timestamp'],
                'deleted': false,
                'countryCode': widget.meta['countryCode'],
                'phoneNumber': widget.meta['phoneNumber'],
                'internalStreamController': widget.meta['internalStreamController'],
                'addMe': addMe,
                'removeMe': removeMe,
              },
            ),
          ),
        );
      }
    }
  }

  void _listen() {
    widget.meta['streamController'].stream.listen(
      (event) async {
        Map<String, dynamic> data = jsonDecode(event);
        switch (data['type']) {
          case 'private_message':
            data['content_type'] = 'text';
            _addPrivateMessage(data);
            break;
        }
      },
    );

    widget.meta['internalStreamController'].stream.listen(
      (event) async {
        switch (event['event']) {
          case 'delete_message':
            // TODO: HAS TO BE OPTIMISED TO UPDATE ONLY THE DLETED MESSAGE IN _messages
            _loadMessages();
            break;
          case 'reload_messages':
            _loadMessages();
            break;
          case 'image_message':
            _addPrivateMessage(event);
            break;
        }
      },
    );
  }

  void _loadMessages() async {
    List<Map<String, Object?>> messages = await LocalDatabase.getMessages(widget.meta['countryCode'], widget.meta['phoneNumber']);
    List<Widget> temp = [];
    for (int i = 0; i < messages.length; ++i) {
      if (messages[i]['type'] == 'received') {
        if (messages[i]['status'] != 3) {
          widget.meta['channel'].sink.add(
            jsonEncode(
              {
                'type': 'message_read',
                'sender_country_code': messages[i]['receiver_country_code'],
                'sender_phone_number': messages[i]['receiver_phone_number'],
                'receiver_country_code': messages[i]['sender_country_code'],
                'receiver_phone_number': messages[i]['sender_phone_number'],
                'hash': messages[i]['hash'],
              },
            ),
          );
        }
        LocalDatabase.markMessageAsRead(messages[i]['hash'] as String);
        temp.add(
          ReceivedMessageWidget(
            meta: {
              'message': messages[i]['content'] as String,
              'content_type': messages[i]['content_type'],
              'hash': messages[i]['hash'] as String,
              'countryCode': widget.meta['countryCode'],
              'phoneNumber': widget.meta['phoneNumber'],
              'deleted': messages[i]['deleted'] == 1,
              'timestamp': messages[i]['timestamp'],
              'internalStreamController': widget.meta['internalStreamController'],
              'addMe': addMe,
              'removeMe': removeMe,
            },
          ),
        );
      } else {
        Map<String, dynamic> sender = (await LocalDatabase.getUser())!;
        temp.add(
          SentMessageWidget(
            meta: {
              'message': messages[i]['content'],
              'content_type': messages[i]['content_type'],
              'sender_country_code': sender['country_code'],
              'sender_phone_number': sender['phone_number'],
              'hash': messages[i]['hash'],
              'timestamp': messages[i]['timestamp'],
              'deleted': messages[i]['deleted'] == 1,
              'status': messages[i]['status'],
              'addMe': addMe,
              'removeMe': removeMe,
              'channel': widget.meta['channel'],
              'streamController': widget.meta['streamController'],
              'internalStreamController': widget.meta['internalStreamController'],
            },
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _messages = temp);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        active = false;
        break;
      case AppLifecycleState.paused:
        active = false;
        break;
      case AppLifecycleState.detached:
        active = false;
        break;
      case AppLifecycleState.resumed:
        _loadMessages();
        active = true;
        break;
    }
  }

  final stateManager = StateManager();

  @override
  void initState() {
    stateManager.setCurrentState(States.CHAT);
    stateManager.setCurrentContactNumber(widget.meta['phoneNumber']);
    super.initState();
    _messageFocusNode = FocusNode();
    _listen();
    _loadMessages();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  List<dynamic> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[900],
        title: Text(widget.meta['name']),
        actions: <Widget>[
          deleteIcon,
          copyIcon,
          const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.search),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                const PopupMenuItem(child: Text('View Contact')),
                const PopupMenuDivider(height: 0),
                PopupMenuItem(
                  padding: const EdgeInsets.only(left: 16),
                  value: 0,
                  child: ListTile(
                    leading: const Icon(Icons.ondemand_video),
                    title: const Text('Youtube'),
                    onTap: () => {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Youtube(
                            meta: {
                              'channel': widget.meta['channel'],
                              'internalStreamController': widget.meta['internalStreamController'],
                            },
                          ),
                        ),
                      )
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/background.png"), fit: BoxFit.cover)),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            SizedBox(
              height: 50,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black)),
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_rounded),
                                onPressed: () {
                                  if (showEmojiKeyboard) {
                                    setState(() => emojiKeyboard = const SizedBox.shrink());
                                    showEmojiKeyboard = false;
                                  } else {
                                    setState(
                                      () => emojiKeyboard = Expanded(
                                        child: EmojiPicker(
                                          onEmojiSelected: (category, emoji) {
                                            int curPos = _messageController.selection.baseOffset;
                                            if (_messageController.text == '') {
                                              _messageController.text += emoji.emoji;
                                            } else {
                                              List<String> msg = _messageController.text.split('');
                                              msg.insert(_messageController.selection.baseOffset, emoji.emoji);
                                              _messageController.text = msg.join();
                                            }
                                            _messageController.selection =
                                                TextSelection.fromPosition(TextPosition(offset: curPos + emoji.emoji.length));
                                            _replaceIcons(_messageController.text);
                                          },
                                          onBackspacePressed: () {
                                            int curPos = _messageController.selection.baseOffset;

                                            if (_messageController.text != '' && curPos > 0) {
                                              List<String> msg = _messageController.text.split('');
                                              List<String> msgBeforeCurPos = msg.getRange(0, curPos).toList();
                                              List<String> msgAfterCurPos = msg.getRange(curPos, msg.length).toList();
                                              int charLen = TextEditingController(text: msgBeforeCurPos.join()).text.characters.last.length;
                                              for (int i = 0; i < charLen; ++i) {
                                                msgBeforeCurPos.removeLast();
                                              }
                                              _messageController.text = msgBeforeCurPos.join() + msgAfterCurPos.join();
                                              _messageController.selection = TextSelection.fromPosition(TextPosition(offset: curPos - charLen));
                                            }
                                            _replaceIcons(_messageController.text);
                                          },
                                          config: Config(
                                              columns: 7,
                                              emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                                              // Issue: https://github.com/flutter/flutter/issues/28894
                                              verticalSpacing: 0,
                                              horizontalSpacing: 0,
                                              initCategory: Category.RECENT,
                                              bgColor: Color(0xFFF2F2F2),
                                              indicatorColor: Colors.blue,
                                              iconColor: Colors.grey,
                                              iconColorSelected: Colors.blue,
                                              progressIndicatorColor: Colors.blue,
                                              showRecentsTab: true,
                                              recentsLimit: 28,
                                              noRecents: const Text("No Recents"),
                                              // noRecentsStyle: const TextStyle(fontSize: 20, color: Colors.black26),
                                              tabIndicatorAnimDuration: kTabScrollDuration,
                                              categoryIcons: const CategoryIcons(),
                                              buttonMode: ButtonMode.MATERIAL),
                                        ),
                                      ),
                                    );
                                    _messageFocusNode.requestFocus();
                                    showEmojiKeyboard = true;
                                  }
                                },
                              ),
                              Expanded(
                                child: Scrollbar(
                                  controller: _messageScrollController,
                                  isAlwaysShown: true,
                                  child: TextField(
                                    keyboardType: TextInputType.multiline,
                                    scrollController: _messageScrollController,
                                    autocorrect: true,
                                    focusNode: _messageFocusNode,
                                    minLines: 1,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Message',
                                    ),
                                    controller: _messageController,
                                    onChanged: (text) => _replaceIcons(text),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.file_copy_outlined),
                                onPressed: () {
                                  /* Your code */
                                },
                              ),
                              cameraIcon,
                            ],
                          ),
                        ),
                      ),
                      microphoneIcon,
                    ],
                  ),
                ),
              ),
            ),
            emojiKeyboard,
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    String msg = _getMessage();
    if (msg.isNotEmpty) {
      Map<String, dynamic> sender = (await LocalDatabase.getUser())!;
      var bytes = utf8.encode('${DateTime.now().microsecondsSinceEpoch}.$sender.$msg');
      var hash = sha256.convert(bytes).toString();

      widget.meta['channel'].sink.add(
        jsonEncode(
          {
            'type': 'private_message',
            'sender_country_code': sender['country_code'],
            'sender_phone_number': sender['phone_number'],
            'receiver_country_code': widget.meta['countryCode'],
            'receiver_phone_number': widget.meta['phoneNumber'],
            'message': msg,
            'hash': hash,
            'timestamp': DateTime.now().microsecondsSinceEpoch,
          },
        ),
      );
    }
  }

  String _getMessage() {
    String msg = _messageController.text.replaceAll('\n', '').trim();
    if (RegExp('^[\\s\n]+\$').hasMatch(msg)) {
      return '';
    }
    return msg;
  }

  void _replaceIcons(text) {
    if (text == '') {
      setState(
        () {
          cameraIcon = IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                File imageFile = File(pickedFile.path);
                final bytes = File(imageFile.path).readAsBytesSync();
                String img64 = base64Encode(bytes);
                _sendImage(img64);
              }
            },
          );
        },
      );
      setState(
        () {
          microphoneIcon = RawMaterialButton(
            onPressed: () {},
            elevation: 2.0,
            fillColor: Colors.cyan[900],
            constraints: const BoxConstraints.expand(width: 42, height: 42),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 20,
            ),
            shape: const CircleBorder(),
          );
        },
      );
    } else {
      setState(
        () {
          cameraIcon = const SizedBox.shrink();
        },
      );
      setState(
        () {
          microphoneIcon = RawMaterialButton(
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage();
              }
            },
            elevation: 2.0,
            fillColor: Colors.cyan[900],
            constraints: const BoxConstraints.expand(width: 42, height: 42),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
            shape: const CircleBorder(),
          );
        },
      );
    }
  }
}
