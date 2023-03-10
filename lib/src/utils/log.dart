import 'package:flutter/material.dart';

// ignore: constant_identifier_names
const DART_LOG = "Dart_LOG";

class Log {
  static const enableLog = false;

  static void info(String? message) {
    if (enableLog) {
      debugPrint('AppFlowyBoard: âšī¸[Info]=> $message');
    }
  }

  static void debug(String? message) {
    if (enableLog) {
      debugPrint(
          'AppFlowyBoard: đ[Debug] - ${DateTime.now().second}=> $message');
    }
  }

  static void warn(String? message) {
    if (enableLog) {
      debugPrint(
          'AppFlowyBoard: đ[Warn] - ${DateTime.now().second} => $message');
    }
  }

  static void trace(String? message) {
    if (enableLog) {
      debugPrint(
          'AppFlowyBoard: âī¸[Trace] - ${DateTime.now().second}=> $message');
    }
  }

  static void error(String? message) {
    debugPrint('AppFlowyBoard: â[Error] - ${DateTime.now().second}=> $message');
  }
}
