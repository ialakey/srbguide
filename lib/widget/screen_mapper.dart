import 'package:flutter/material.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/exchange_rate.dart';
import 'package:srbguide/screens/guide.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/service.dart';
import 'package:srbguide/screens/tg_chats.dart';
import 'package:srbguide/screens/white_cardboard.dart';

class ScreenMapper {
  static Widget getScreen(String screen) {
    switch (screen) {
      case 'ServiceScreen':
        return ServiceScreen();
      case 'GuideScreen':
        return GuideScreen();
      case 'MapScreen':
        return MapScreen();
      case 'TgChatScreen':
        return TgChatScreen();
      case 'ExchangeRateScreen':
        return ExchangeRateScreen();
      default:
        return VisaFreeCalculatorScreen();
    }
  }
}
