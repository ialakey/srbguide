import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisaFreeCalculator extends StatefulWidget {
  @override
  _VisaFreeCalculatorState createState() => _VisaFreeCalculatorState();
}

class _VisaFreeCalculatorState extends State<VisaFreeCalculator> {
  final TextEditingController _entryDateController = TextEditingController();
  final int visaFreeDays = 30;
  int remainingDays = 30;
  DateTime? exitDate;

  Future<void> _selectEntryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _entryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        exitDate = picked.add(Duration(days: visaFreeDays));
      });
    }
  }

  void calculateRemainingDays() {
    if (_entryDateController.text.isNotEmpty) {
      DateTime entryDate = DateTime.parse(_entryDateController.text);
      DateTime currentDate = DateTime.now();

      if (currentDate.isBefore(exitDate!)) {
        setState(() {
          remainingDays = exitDate!.difference(currentDate).inDays;
        });
      } else {
        setState(() {
          remainingDays = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Калькулятор визарана'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () => _selectEntryDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _entryDateController,
                  decoration: InputDecoration(
                    labelText: 'Выберите день въезда в Сербию',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                calculateRemainingDays();
                if (exitDate != null) {
                  final String exitDateString =
                  DateFormat('yyyy-MM-dd').format(exitDate!);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Осталось дней до окончания безвизового периода'),
                        content: Text(
                            'Осталось дней: $remainingDays\n'
                                'Вы должны покинуть Сербию до: $exitDateString'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Рассчитать'),
            ),
          ],
        ),
      ),
    );
  }
}
