import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:srbguide/localization/app_localizations.dart';

class DialogHelper {
  static void show(
      BuildContext context,
      double currentTextSize,
      void Function(double) setTextSize,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('text_size')),
          content: SizedBox(
            width: 300,
            height: 100,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlutterSlider(
                        values: [currentTextSize],
                        min: 12,
                        max: 30,
                        step: FlutterSliderStep(step: 1),
                        axis: Axis.horizontal,
                        handler: FlutterSliderHandler(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        trackBar: FlutterSliderTrackBar(
                          activeTrackBar: BoxDecoration(
                            color: Colors.blue.withOpacity(0.5),
                          ),
                          inactiveTrackBar: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        tooltip: FlutterSliderTooltip(
                          textStyle: TextStyle(fontSize: 16),
                          boxStyle: FlutterSliderTooltipBox(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        onDragging: (handlerIndex, lowerValue, upperValue) {
                          setState(() {
                            currentTextSize = lowerValue;
                          });
                        },
                      ),
                      Text('${AppLocalizations.of(context)!.translate('current_size')}: ${currentTextSize.toStringAsFixed(0)}'),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: <Widget>[
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.translate('save'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              onTap: () {
                setTextSize(currentTextSize);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
