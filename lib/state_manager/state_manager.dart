import 'package:flutter/material.dart';

class CustomState {
  int state;
  CustomState(this.state);
}


class States {
  static CustomState LOGIN = CustomState(0);
  static CustomState OTP = CustomState(1);
  static CustomState HOME = CustomState(2);
  static CustomState CHAT = CustomState(3);
  static CustomState ADD_CONTACT = CustomState(4);
  static CustomState YOUTUBE = CustomState(5);
}

class StateManager {
  // START SINGLETON BLOCK
  static final StateManager _singleton = StateManager._internal();

  StateManager._internal();

  factory StateManager() {
    return _singleton;
  }

  // END SINGLETON BLOCK

  CustomState CURRENT_SCREEN = States.HOME;
  String? CURRENT_CONTACT_NUMBER;

  void setCurrentState(CustomState value) => CURRENT_SCREEN = value;

  void setCurrentContactNumber(String? value) {
    CURRENT_SCREEN = States.CHAT;
    CURRENT_CONTACT_NUMBER = value;
  }
}
