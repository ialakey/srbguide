import 'package:flutter/material.dart';

class CustomSuccessDialog extends StatelessWidget {
  final BuildContext context;
  final String title;

  const CustomSuccessDialog({
    super.key,
    required this.context,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.check_circle),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: <Widget>[
        Center(
          child: ListTile(
            onTap: () {
              Navigator.of(context).pop();
            },
            title: Text('OK', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  static void show({
    required BuildContext context,
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomSuccessDialog(
          context: context,
          title: title,
        );
      },
    );
  }
}
