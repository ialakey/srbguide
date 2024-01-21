import 'package:flutter/material.dart';

class CustomErrorDialog extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String text;

  const CustomErrorDialog({
    super.key,
    required this.context,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
      width: 300,
      height: 100,
      child: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(text),
          ],
        ),
      )),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK'),
        ),
      ],
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required String text,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomErrorDialog(
          context: context,
          title: title,
          text: text,
        );
      },
    );
  }
}
