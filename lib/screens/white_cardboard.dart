import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/utils/snackbar_utils.dart';

class InformationForm extends StatefulWidget {
  @override
  _InformationFormState createState() => _InformationFormState();
}

class _InformationFormState extends State<InformationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ownerInfoController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _arrivalDate;
  DateTime? _registrationDate;

  String _gender = 'M';
  List<String> _genderOptions = ['M', 'Ž'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? surname = prefs.getString('surname');
    String? name = prefs.getString('name');
    String? placeOfBirth = prefs.getString('placeOfBirth');
    String? nationality = prefs.getString('nationality');
    String? documentNumber = prefs.getString('documentNumber');
    String? address = prefs.getString('address');
    String? ownerInfo = prefs.getString('ownerInfo');
    String? dateOfBirthString = prefs.getString('dateOfBirth');
    String? arrivalDateString = prefs.getString('arrivalDate');
    String? registrationDateString = prefs.getString('registrationDate');

    if (surname != null) {
      setState(() {
        _surnameController.text = surname;
      });
    }
    if (name != null) {
      setState(() {
        _nameController.text = name;
      });
    }
    if (placeOfBirth != null) {
      setState(() {
        _placeOfBirthController.text = placeOfBirth;
      });
    }
    if (nationality != null) {
      setState(() {
        _nationalityController.text = nationality;
      });
    }
    if (documentNumber != null) {
      setState(() {
        _documentNumberController.text = documentNumber;
      });
    }
    if (address != null) {
      setState(() {
        _addressController.text = address;
      });
    }
    if (ownerInfo != null) {
      setState(() {
        _ownerInfoController.text = ownerInfo;
      });
    }
    if (dateOfBirthString != null) {
      setState(() {
        _dateOfBirth = DateTime.parse(dateOfBirthString);
      });
    }
    if (arrivalDateString != null) {
      setState(() {
        _arrivalDate = DateTime.parse(arrivalDateString);
      });
    }
    if (registrationDateString != null) {
      setState(() {
        _registrationDate = DateTime.parse(registrationDateString);
      });
    }
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('surname', _surnameController.text);
    await prefs.setString('name', _nameController.text);
    await prefs.setString('placeOfBirth', _placeOfBirthController.text);
    await prefs.setString('nationality', _nationalityController.text);
    await prefs.setString('documentNumber', _documentNumberController.text);
    await prefs.setString('address', _addressController.text);
    await prefs.setString('ownerInfo', _ownerInfoController.text);
    if (_dateOfBirth != null) {
      await prefs.setString('dateOfBirth', _dateOfBirth!.toIso8601String());
    }
    if (_arrivalDate != null) {
      await prefs.setString('arrivalDate', _arrivalDate!.toIso8601String());
    }
    if (_registrationDate != null) {
      await prefs.setString('registrationDate', _registrationDate!.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Имя'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text(
                  'Дата рождения: ${_dateOfBirth != null ? _dateOfBirth!.toString().split(' ')[0] : 'Выберите дату'}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && pickedDate != _dateOfBirth) {
                    setState(() {
                      _dateOfBirth = pickedDate;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: _genderOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Пол'),
              ),
              TextFormField(
                controller: _placeOfBirthController,
                decoration: InputDecoration(labelText: 'Место рождения'),
              ),
              TextFormField(
                controller: _nationalityController,
                decoration: InputDecoration(labelText: 'Национальность'),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                controller: _documentNumberController,
                decoration: InputDecoration(labelText: 'Номер документа'),
              ),
              ListTile(
                title: Text(
                  'Дата прибытия: ${_arrivalDate != null ? _arrivalDate!.toString().split(' ')[0] : 'Выберите дату'}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && pickedDate != _arrivalDate) {
                    setState(() {
                      _arrivalDate = pickedDate;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Адрес регистрации'),
              ),
              TextFormField(
                controller: _ownerInfoController,
                decoration: InputDecoration(labelText: 'Информация о владельце'),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              ListTile(
                title: Text(
                  'Дата регистрации: ${_registrationDate != null ? _registrationDate!.toString().split(' ')[0] : 'Выберите дату'}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && pickedDate != _registrationDate) {
                    setState(() {
                      _registrationDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _saveData();
                  SnackbarUtils.showSnackbar(context, 'Данные сохранены!');
                },
                icon: Icon(Icons.save),
                label: Text('Сохранить'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final params = {
                      'surname': _surnameController.text,
                      'name': _nameController.text,
                      'dateOfBirth': _dateOfBirth!.toString().split(' ')[0],
                      'sex': _gender,
                      'placeOfBirth': _placeOfBirthController.text,
                      'nationality': _nationalityController.text,
                      'documentNumber': _documentNumberController.text,
                      'dateOfEntry': _arrivalDate.toString().split(' ')[0],
                      'addressOfPlace': _addressController.text,
                      'landlordInformation': _ownerInfoController.text,
                      'dateOfRegistration': _registrationDate.toString().split(' ')[0],
                    };
                    generateAndDownloadDocument(params);
                  }
                },
                icon: Icon(Icons.download),
                label: Text('Скачать'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> generateAndDownloadDocument(Map<String, Object?> params) async {
    final ByteData templateData = await rootBundle.load('assets/cardboard.docx');
    final Uint8List templateBytes = templateData.buffer.asUint8List();

    final docx = await DocxTemplate.fromBytes(templateBytes);

    final content = Content();
    params.forEach((key, value) {
      content.add(TextContent(key, value));
    });

    final generatedDoc = await docx.generate(content);

    final directory = await getTemporaryDirectory();
    final outputFilePath = '${directory.path}/cardboard.docx';
    final outputFile = File(outputFilePath);
    await outputFile.writeAsBytes(generatedDoc!);

    OpenFile.open(outputFile.path);
  }
}