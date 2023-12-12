import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisaFreeCalculator extends StatefulWidget {
  @override
  _VisaFreeCalculatorState createState() => _VisaFreeCalculatorState();
}

class _VisaFreeCalculatorState extends State<VisaFreeCalculator> {
  final TextEditingController _entryDateController = TextEditingController();
  final int visaFreeDays = 29;
  int remainingDays = 29;
  DateTime? exitDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initDate();
  }

  _initDate() async {
    await _loadDate();
    _setupInitialValues();
  }

  _loadDate() async {
    _prefs = await SharedPreferences.getInstance();
    final savedDate = _prefs.getString('exitDate');
    final savedRemainingDays = _prefs.getInt('remainingDays');
    if (savedDate != null && savedDate.isNotEmpty) {
      setState(() {
        exitDate = DateTime.parse(savedDate);
        remainingDays = savedRemainingDays ?? 29;
      });
    }
  }

  _setupInitialValues() {
    if (exitDate != null) {
      _entryDateController.text =
          DateFormat('EEEE, d MMMM y г.', 'ru').format(exitDate!);
      calculateRemainingDays();
    }
  }

  _saveDate() async {
    if (exitDate != null) {
      await _prefs.setString('exitDate', exitDate!.toIso8601String());
      await _prefs.setInt('remainingDays', remainingDays);
    }
  }

  _selectEntryDate(BuildContext context) {

    initializeDateFormatting('ru').then((_) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _entryDateController.text = DateFormat('EEEE, d MMMM y г.', 'ru').format(picked);
        exitDate = picked.add(Duration(days: visaFreeDays));
      });

      calculateRemainingDays();
      if (exitDate != null) {
        final String exitDateString = DateFormat('EEEE, d MMMM y г.', 'ru').format(exitDate!);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.confirm,
          title: 'Осталось дней: $remainingDays',
          text: 'Вы должны покинуть Сербию до: $exitDateString' + '\nСоздать событие в календаре?',
          showConfirmBtn: true,
          confirmBtnText: 'Да',
          cancelBtnText: 'Нет',
          onConfirmBtnTap: () {
            _showDateTimePickerDialog(context, exitDate);
          },
          onCancelBtnTap: () {
            _saveDate();
            Navigator.of(context).pop();
          },
          showCancelBtn: false,
        );
        // showDialog(
        //   context: context,
        //   builder: (BuildContext context) {
        //     return AlertDialog(
        //       title: Column(
        //         children: [
        //           Text('Осталось дней: $remainingDays'),
        //           SizedBox(height: 10),
        //           Text('Вы должны покинуть Сербию до:'),
        //           Text(exitDateString, style: TextStyle(fontWeight: FontWeight.bold)),
        //         ],
        //       ),
        //       actions: <Widget>[
        //         TextButton.icon(
        //           onPressed: () {
        //             _showDateTimePickerDialog(context, exitDate);
        //           },
        //           icon: Icon(Icons.notifications),
        //           label: Text('Создать напоминание в календаре'),
        //         ),
        //         TextButton(
        //           onPressed: () {
        //             _saveDate();
        //             Navigator.of(context).pop();
        //           },
        //           child: Text('OK'),
        //         ),
        //       ],
        //     );
        //   },
        // );
      }
    }
    });
  }

  void calculateRemainingDays() {
    if (_entryDateController.text.isNotEmpty) {
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
      key: _scaffoldKey,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              title: Text(
                'Выберите день въезда в Сербию:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                _selectEntryDate(context);
              },
            ),
            SizedBox(height: 10),
            Text(
              'Осталось дней: $remainingDays\n'
                  'Вы должны покинуть Сербию до: ${exitDate != null ? exitDate!.toString().split(' ')[0] : 'Выберите дату'}',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateTimePickerDialog(
      BuildContext context,
      DateTime? timeVisarun,
      ) async {
    DateTime? selectedDateTime = timeVisarun;

    showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext builder) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Выбрать дату'),
                  subtitle: Text(selectedDateTime != null
                      ? DateFormat.yMMMd().format(selectedDateTime!)
                      : 'Выберите дату'),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          selectedDateTime?.hour ?? 0,
                          selectedDateTime?.minute ?? 0,
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Выбрать время'),
                  subtitle: Text(selectedDateTime != null
                      ? DateFormat.Hm().format(selectedDateTime!)
                      : 'Выберите время'),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          selectedDateTime!.year,
                          selectedDateTime!.month,
                          selectedDateTime!.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.create),
                  onPressed: () {
                    if (selectedDateTime != null) {
                      Add2Calendar.addEvent2Cal(createCalendarEvent(selectedDateTime!));
                      Navigator.pop(context);
                    }
                  },
                  label: Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Event createCalendarEvent(DateTime noticeDate) {
    return Event(
      title: 'Визаран',
      description: 'Нужно сделать визаран до $exitDate',
      startDate: noticeDate,
      endDate: noticeDate.add(const Duration(hours: 1)),
      allDay: false,
    );
  }
}
