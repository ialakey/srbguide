import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:share/share.dart';
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
  final TextEditingController _placeArrivalController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _arrivalDate;
  DateTime? _registrationDate;

  String _gender = 'M';
  List<String> _genderOptions = ['M', 'Ž'];
  String _selectedValue = 'Выбрать';
  List<String> locations = [
    'Выбрать',
    'Badovinci',
    'Banatski Brestovac',
    'Bačka Palanka',
    'Bačka Petrovac',
    'Bački Vinogradi',
    'Bajmok',
    'Bezdan',
    'Bogovadja',
    'Bolevec',
    'Bosilegrad',
    'Brodarevo',
    'Bratunac',
    'Budimpešta',
    'Dimitrovgrad',
    'Djala',
    'Dobrinci',
    'Đeneral Janković',
    'Gostun',
    'Ključ',
    'Kopaonik',
    'Kosjerić',
    'Kosovo Polje',
    'Novi Sad',
    'Priboj',
    'Sremska Raća',
    'Surčin',
    'Thermopile',
    'Vrnjci',
    'Vatin',
    'Vlaole',
    'Žabljak',
    'Zagubica',
    'Zaječar',
    'Zrenjanin',
    ];

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
    String? placeArrival = prefs.getString('placeArrival');

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
    if (placeArrival != null) {
      setState(() {
        _placeArrivalController.text = placeArrival;
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
    await prefs.setString('placeArrival', _placeArrivalController.text);
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
                maxLines: null,
                keyboardType: TextInputType.multiline,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _placeArrivalController,
                      decoration: InputDecoration(labelText: 'Место прибытия'),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedValue,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedValue = newValue;
                          _placeArrivalController.text = newValue;
                        });
                      }
                    },
                    items: locations.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
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
                maxLines: null,
                keyboardType: TextInputType.multiline,
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
                      'dateOfEntry': _arrivalDate.toString().split(' ')[0] + ' ' + _placeArrivalController.text,
                      'addressOfPlace': _addressController.text,
                      'landlordInformation': _ownerInfoController.text,
                      'dateOfRegistration': _registrationDate.toString().split(' ')[0],
                    };
                    generateAndEventDocument(params, false);
                  }
                },
                icon: Icon(Icons.download),
                label: Text('Скачать'),
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
                      'dateOfEntry': _arrivalDate.toString().split(' ')[0] + ' ' + _placeArrivalController.text,
                      'addressOfPlace': _addressController.text,
                      'landlordInformation': _ownerInfoController.text,
                      'dateOfRegistration': _registrationDate.toString().split(' ')[0],
                    };
                    generateAndEventDocument(params, true);
                  }
                },
                icon: Icon(Icons.send),
                label: Text('Отправить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> generateAndEventDocument(Map<String, Object?> params, bool isSend) async {
    final ByteData templateData = await rootBundle.load('assets/cardboard.docx');
    final Uint8List templateBytes = templateData.buffer.asUint8List();

    final docx = await DocxTemplate.fromBytes(templateBytes);

    final content = Content();
    params.forEach((key, value) {
      content.add(TextContent(key, value));
    });

    final generatedDoc = await docx.generate(content);

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final directory = await getTemporaryDirectory();
    final outputFilePath = '${directory.path}/Белый картон от $formattedDate.docx';
    final outputFile = File(outputFilePath);
    await outputFile.writeAsBytes(generatedDoc!);

    if (isSend) {
      Share.shareFiles([outputFile.path], text: 'Белый картон от $formattedDate');
    } else {
      OpenFile.open(outputFile.path);
    }
  }
}