import 'package:flutter/material.dart';

class GroupColor {
  static var items = [
    Colors.red,
    Colors.lime,
    Colors.green,
    Colors.amber,
    Colors.brown,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.grey
  ];
  static MaterialColor getColor(i) {
    return items[i];
  }
}

class MyTheme extends ChangeNotifier {
  static bool isDark = true;
  ThemeMode currentTheme() {
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void switchTheme(bool value) {
    isDark = value;
    notifyListeners();
  }
}
