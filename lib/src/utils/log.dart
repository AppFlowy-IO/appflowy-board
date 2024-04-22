import "package:flutter/material.dart";

class Log {
  static const enableLog = false;

  static void trace(String? message) {
    if (enableLog) {
      debugPrint(
        "${_now()} AppFlowyBoard: 🔎 TRACE - $message",
      );
    }
  }

  static void debug(String? message) {
    if (enableLog) {
      debugPrint(
        "${_now()} AppFlowyBoard: 🐛 DEBUG - $message",
      );
    }
  }

  static void info(String? message) {
    if (enableLog) {
      debugPrint(
        "${_now()} AppFlowyBoard: ℹ️ INFO - $message",
      );
    }
  }

  static void warn(String? message) {
    if (enableLog) {
      debugPrint(
        "${_now()} AppFlowyBoard: ⚠️ WARN - $message",
      );
    }
  }

  static void error(String? message) {
    debugPrint(
      "${_now()} AppFlowyBoard: ❌ ERROR - $message",
    );
  }

  static String _now() {
    final dateTime = DateTime.now();
    return "${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} "
        "${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}";
  }

  static String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    }
    return "0$n";
  }
}
