import 'package:flutter/material.dart';

class NotificationService {
  // Show a simple dialog with a message
  static Future<void> showDialogMessage(BuildContext context, String message, {String title = 'Notification', Function? callback}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Allow dismiss on tap outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if(callback != null){
                  callback();
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showDialogMessageWithActions(BuildContext context, String message, List<TextButton> actionButtons, {String title = 'Notification'}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Allow dismiss on tap outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actionButtons,
        );
      },
    );
  }

  // Show a snackbar with a message
  static void showSnackbar(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  // Show a bottom sheet with a custom message
  static void showBottomSheetMessage(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, style: TextStyle(fontSize: 18)),
        );
      },
    );
  }
}
