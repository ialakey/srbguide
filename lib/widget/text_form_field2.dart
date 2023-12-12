import 'package:flutter/material.dart';

class TextFormFieldContainer2 extends StatelessWidget {
  final String labelText;
  final String labelText2;
  final Widget child;

  const TextFormFieldContainer2({
    required this.labelText,
    required this.labelText2,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            labelText2,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}
