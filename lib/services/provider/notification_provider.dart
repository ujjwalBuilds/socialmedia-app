import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  bool _hasNotification = false;

  bool get hasNotification => _hasNotification;

  void showNotification() {
    _hasNotification = true;
    notifyListeners();
  }

  void clearNotification() {
    _hasNotification = false;
    notifyListeners();
  }
}
