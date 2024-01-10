import 'package:flutter/material.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String text;
  final String iconPath;
  final String confirmBtnText;
  final String cancelBtnText;
  final Function()? onConfirmBtnTap;
  final Function()? onCancelBtnTap;

  const CustomConfirmationDialog({
    super.key,
    required this.context,
    required this.title,
    required this.text,
    required this.iconPath,
    required this.confirmBtnText,
    required this.cancelBtnText,
    required this.onConfirmBtnTap,
    required this.onCancelBtnTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          SizedBox(width: 8),
          ThemedIcon(
            iconPath: iconPath,
            size: 24.0,
          ),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(text),
      actions: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onCancelBtnTap,
                child: Row(
                  children: [
                    ThemedIcon(
                      iconPath: 'assets/icons_24x24/cancel.png',
                      size: 24.0,
                    ),
                    SizedBox(width: 8),
                    Text(cancelBtnText),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onConfirmBtnTap,
                child: Row(
                  children: [
                    ThemedIcon(
                      iconPath: 'assets/icons_24x24/checkbox.png',
                      size: 24.0,
                    ),
                    SizedBox(width: 8),
                    Text(confirmBtnText),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required String text,
    required String iconPath,
    required String confirmBtnText,
    required String cancelBtnText,
    required Function()? onConfirmBtnTap,
    required Function()? onCancelBtnTap,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomConfirmationDialog(
          context: context,
          title: title,
          text: text,
          iconPath: iconPath,
          confirmBtnText: confirmBtnText,
          cancelBtnText: cancelBtnText,
          onConfirmBtnTap: onConfirmBtnTap,
          onCancelBtnTap: onCancelBtnTap,
        );
      },
    );
  }
}
