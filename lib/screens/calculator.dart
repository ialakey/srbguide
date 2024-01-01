import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/language_provider.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';

class VisaFreeCalculatorScreen extends StatefulWidget {
  @override
  _VisaFreeCalculatorScreenState createState() => _VisaFreeCalculatorScreenState();
}

class _VisaFreeCalculatorScreenState extends State<VisaFreeCalculatorScreen> {
  final TextEditingController _entryDateController = TextEditingController();
  final int visaFreeDays = 29;
  int remainingDays = 29;
  DateTime? exitDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late SharedPreferences _prefs;
  late String languageCode;

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _initDate();
  }

  _initLanguage() async {
    LanguageProvider languageProvider = LanguageProvider();
    await languageProvider.init();
    languageCode = languageProvider.selectedLocale.languageCode;
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
          DateFormat('EEEE, d MMMM y г.', languageCode).format(exitDate!);
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
    initializeDateFormatting(languageCode).then((_) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _entryDateController.text = DateFormat('EEEE, d MMMM y г.', languageCode).format(picked);
        exitDate = picked.add(Duration(days: visaFreeDays));
      });

      calculateRemainingDays();
      if (exitDate != null) {
        final String exitDateString = DateFormat('EEEE, d MMMM y г.', languageCode).format(exitDate!);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.confirm,
          title: '${AppLocalizations.of(context)!.translate('remaining_days')}: $remainingDays',
          text: '${AppLocalizations.of(context)!.translate('leave_serbia_by')}: $exitDateString'
              + '\n${AppLocalizations.of(context)!.translate('create_calendar_event')}',
          showConfirmBtn: true,
          confirmBtnText: AppLocalizations.of(context)!.translate('yes'),
          cancelBtnText: AppLocalizations.of(context)!.translate('no'),
          onConfirmBtnTap: () {
            _showDateTimePickerDialog(context, exitDate);
          },
          onCancelBtnTap: () {
            _saveDate();
            Navigator.of(context).pop();
          },
          showCancelBtn: false,
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
    String exitDateString = '';
    if (exitDate != null) {
      exitDateString = DateFormat('EEEE, d MMMM y г.', languageCode).format(exitDate!);
    }
    return Scaffold(
      appBar:
      CustomAppBar(
        title: AppLocalizations.of(context)!.translate('calculator_visarun'),
      ),
      drawer: AppDrawer(),
      key: _scaffoldKey,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  '${AppLocalizations.of(context)!.translate('select_entry_date_serbia')}:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: ThemedIcon(
                  lightIcon: 'assets/icons_24x24/calendar.png',
                  darkIcon: 'assets/icons_24x24/calendar.png',
                  size: 24.0,
                ),
                onTap: () async {
                  _selectEntryDate(context);
                },
              ),
            ),
            SizedBox(height: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ThemedIcon(
                          lightIcon: 'assets/icons_24x24/clock.gif',
                          darkIcon: 'assets/icons_24x24/clock.gif',
                          size: 32.0,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.translate('remaining_days')}: $remainingDays\n'
                              '${AppLocalizations.of(context)!.translate('leave_serbia_by')}: \n$exitDateString',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  title: Text(AppLocalizations.of(context)!.translate('select_date')),
                  subtitle: Text(selectedDateTime != null
                      ? DateFormat.yMMMd().format(selectedDateTime!)
                      : AppLocalizations.of(context)!.translate('choose_date')),
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
                  title: Text(AppLocalizations.of(context)!.translate('select_time')),
                  subtitle: Text(selectedDateTime != null
                      ? DateFormat.Hm().format(selectedDateTime!)
                      : AppLocalizations.of(context)!.translate('choose_time')),
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
                  label: Text(AppLocalizations.of(context)!.translate('create')),
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
      title: AppLocalizations.of(context)!.translate('visarun'),
      description: '${AppLocalizations.of(context)!.translate('need_make_visa_run_by')} $exitDate',
      startDate: noticeDate,
      endDate: noticeDate.add(const Duration(hours: 1)),
      allDay: false,
    );
  }
}
