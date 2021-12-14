import 'package:flutter/material.dart';
import 'custom_shape.dart';
import 'dart:io';

class SentMessageWidget extends StatefulWidget {
  Map<String, dynamic> meta;

  SentMessageWidget({required this.meta});

  @override
  _SentMessageWidget createState() => _SentMessageWidget();
}

class _SentMessageWidget extends State<SentMessageWidget> {
  Color normalColor = Colors.cyan[900]!;
  Color deletedNormalColor = Colors.grey[900]!;
  bool isSelected = false;
  double x = 120;

  @override
  Widget build(BuildContext context) {
    if (!widget.meta['deleted']) {
      if (widget.meta['content_type'] == 'text') {
        var t = DateTime.fromMicrosecondsSinceEpoch(widget.meta['timestamp']);
        String time =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} - ${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

        return GestureDetector(
          onTap: () {
            if (isSelected) {
              widget.meta['removeMe'](widget);
              isSelected = false;
              setState(() {
                normalColor = Colors.cyan[900]!;
              });
            }
          },
          onLongPress: () {
            if (!isSelected) {
              setState(() {
                normalColor = Colors.lightBlue;
              });
              widget.meta['addMe'](widget);
              isSelected = true;
            }
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              if (details.globalPosition.dx >= 0) {
                x = details.globalPosition.dx - 220;
              }
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              x = 120;
            });
          },
          child: Transform.translate(
            offset: Offset(x, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 0, left: 50, top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(height: 30),
                  Flexible(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: normalColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  widget.meta['message'],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                            CustomPaint(painter: CustomShape(normalColor)),
                            _messageStatus(),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        var t = DateTime.fromMicrosecondsSinceEpoch(widget.meta['timestamp']);
        String time =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} - ${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

        return GestureDetector(
          onTap: () {
            if (isSelected) {
              widget.meta['removeMe'](widget);
              isSelected = false;
              setState(() {
                normalColor = Colors.cyan[900]!;
              });
            }
          },
          onLongPress: () {
            if (!isSelected) {
              setState(() {
                normalColor = Colors.lightBlue;
              });
              widget.meta['addMe'](widget);
              isSelected = true;
            }
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              if (details.globalPosition.dx >= 0) {
                x = details.globalPosition.dx - 220;
              }
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              x = 120;
            });
          },
          child: Transform.translate(
            offset: Offset(x, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 0, left: 50, top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(height: 30),
                  Flexible(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: normalColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(File(widget.meta['message'])),
                                ),
                              ),
                            ),
                            CustomPaint(painter: CustomShape(normalColor)),
                            _messageStatus(),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return GestureDetector(
        onTap: () {
          if (isSelected) {
            widget.meta['removeMe'](widget);
            isSelected = false;
            setState(() {
              deletedNormalColor = Colors.grey[900]!;
            });
          }
        },
        onLongPress: () {
          setState(() {
            deletedNormalColor = Colors.lightBlue;
          });
          widget.meta['addMe'](widget);
          isSelected = true;
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 18.0, left: 50, top: 15, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const SizedBox(height: 30),
              Flexible(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: deletedNormalColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '🚫 Message deleted',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        CustomPaint(painter: CustomShape(deletedNormalColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _messageStatus() {
    Widget icon = const Icon(
      Icons.offline_pin,
      color: Colors.white,
      size: 20,
    );
    switch (widget.meta['status']) {
      case 0:
        icon = const Icon(
          Icons.offline_pin,
          color: Colors.white,
          size: 20,
        );
        break;
      case 1:
        break;
      case 2:
        icon = const Icon(
          Icons.offline_pin,
          color: Colors.green,
          size: 20,
        );
        break;
      case 3:
        icon = const Icon(
          Icons.offline_pin,
          color: Colors.blue,
          size: 20,
        );
    }
    return icon;
  }
}
