import 'package:flutter/material.dart';
import 'package:srbguide/screens/exchange_rate.dart';
import 'package:srbguide/screens/guide_navigation.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/service.dart';
import 'package:srbguide/screens/tg_chats.dart';

class ScreenMapper {
  static Widget getScreen(String screen) {
    switch (screen) {
      case 'ServiceScreen':
        return ServiceScreen();
      case 'GuideNavigationScreen':
        return GuideNavigationScreen();
      case 'MapScreen':
        return MapScreen();
      case 'TgChatScreen':
        return TgChatScreen();
      case 'ExchangeRateScreen':
        return ExchangeRateScreen();
      default:
        return ServiceScreen();
    }
  }
}
