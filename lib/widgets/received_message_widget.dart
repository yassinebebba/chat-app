import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math';

import 'custom_shape.dart';

class ReceivedMessageWidget extends StatefulWidget {
  Map<String, dynamic> meta;

  void setMessage(String value) {
    meta['message'] = value;
  }

  ReceivedMessageWidget({required this.meta});

  @override
  _ReceivedMessageWidget createState() => _ReceivedMessageWidget();
}

class _ReceivedMessageWidget extends State<ReceivedMessageWidget> {
  Color normalColor = Colors.grey[300]!;
  Color deletedNormalColor = Colors.grey[900]!;
  bool isSelected = false;
  double x = -140;

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
                normalColor = Colors.grey[300]!;
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
              x = -140;
            });
          },
          child: Transform.translate(
            offset: Offset(x, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 20, top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(height: 30),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(left: 10)),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: CustomPaint(
                            painter: CustomShape(normalColor),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: normalColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                            child: Text(
                              widget.meta['message'],
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
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
                normalColor = Colors.grey[300]!;
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
              x = -140;
            });
          },
          child: Transform.translate(
            offset: Offset(x, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 20, top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(height: 30),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(left: 10)),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: CustomPaint(
                            painter: CustomShape(normalColor),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: normalColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
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
          padding: const EdgeInsets.only(right: 18.0, left: 20, top: 15, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const SizedBox(height: 30),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: CustomPaint(
                        painter: CustomShape(deletedNormalColor),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: deletedNormalColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: const Text(
                          '🚫 Message deleted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
}
