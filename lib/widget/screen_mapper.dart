import 'package:flutter/material.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/guide.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/tg_chats.dart';
import 'package:srbguide/screens/white_cardboard.dart';

class ScreenMapper {
  static Widget getScreen(String screen) {
    switch (screen) {
      case 'VisaFreeCalculatorScreen':
        return VisaFreeCalculatorScreen();
      case 'CreateWhiteCardboardScreen':
        return CreateWhiteCardboardScreen();
      case 'GuideScreen':
        return GuideScreen();
      case 'MapScreen':
        return MapScreen();
      case 'TgChatScreen':
        return TgChatScreen();
      default:
        return VisaFreeCalculatorScreen();
    }
  }
}
