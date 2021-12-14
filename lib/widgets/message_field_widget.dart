import 'package:flutter/material.dart';

class MessageFieldWidget extends StatefulWidget {
  @override
  _MessageFieldWidget createState() => _MessageFieldWidget();
}

class _MessageFieldWidget extends State<MessageFieldWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Widget cameraIcon = IconButton(
    icon: const Icon(Icons.camera_alt),
    onPressed: () {
      /* Your code */
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black)),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_rounded),
                      onPressed: () {
                        /* Your code */
                      },
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        isAlwaysShown: true,
                        child: TextField(
                          keyboardType: TextInputType.multiline,
                          scrollController: _scrollController,
                          autocorrect: true,
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
    );
  }

  void _replaceIcons(text) {
    if (text == '') {
      setState(
        () {
          cameraIcon = IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              /* Your code */
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
            onPressed: () {},
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
