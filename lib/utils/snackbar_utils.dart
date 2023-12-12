import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showSnackbar(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: Duration(milliseconds: 850),
    )..show(context);
  }
}
