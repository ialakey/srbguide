import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

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

  Future<void> _selectEntryDate(BuildContext context) async {

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
        final String exitDateString =
        DateFormat('EEEE, d MMMM y г.', 'ru').format(exitDate!);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Осталось дней: $remainingDays\n'
                  'Вы должны покинуть Сербию до: $exitDateString'),
              actions: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    _showDateTimePickerDialog(context, exitDate);
                  },
                  icon: Icon(Icons.notifications),
                  label: Text('Создать напоминание в календаре'),
                ),
                SizedBox(height: 20),
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
                'Выберите день въезда в Сербию: ${exitDate != null ? exitDate!.toString().split(' ')[0] : 'Выберите дату'}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                _selectEntryDate(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showDateTimePickerDialog(BuildContext context, DateTime? timeVisarun) async {
    DateTime? selectedDateTime = timeVisarun;
    showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext builder) {
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
                  initialDate: selectedDateTime!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      selectedDateTime!.hour,
                      selectedDateTime!.minute,
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
                  initialTime: TimeOfDay.fromDateTime(selectedDateTime!),
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
                  createCalendarEvent(selectedDateTime!);
                  Navigator.pop(context);
                }
              },
              label: Text('Создать'),
            ),
          ],
        );
      },
    );
  }


  Future<void> createCalendarEvent(DateTime noticeDate) async {
    try {
      DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
      var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      var calendars = calendarsResult.data;

      if (calendars != null && calendars.isNotEmpty) {
        var calendar = calendars.first;

        var event = Event(calendar.id,
            title: 'Визаран',
            description: 'Нужно сделать визаран',
            start: convertToTZDateTime(noticeDate),
            end: convertToTZDateTime(noticeDate.add(Duration(hours: 1))));

        var createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(
            event);
        if (createEventResult?.isSuccess ?? false) {
          _showSnackBar('Событие успешно создано в календаре!');
        } else {
          _showSnackBar('Вы не выбрали дату въезда в Сербию');
        }
      }
    } catch (e) {
      _showSnackBar('Произошла ошибка при создании события: $e');
    }
  }

  tz.TZDateTime convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('Europe/Belgrade');
    final convertedTime = tz.TZDateTime(location, dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute, dateTime.second);
    return convertedTime;
  }
}
