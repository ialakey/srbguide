import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

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

  String _gender = 'М';
  List<String> _genderOptions = ['М', 'Ж'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание белого кратона'),
      ),
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
                decoration: InputDecoration(labelText: 'Адрес прописки'),
              ),
              TextFormField(
                controller: _ownerInfoController,
                decoration: InputDecoration(labelText: 'Информация о владельце'),
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
              ElevatedButton(
                onPressed: () {},
                child: Text("Сохранить"),
              ),
              ElevatedButton(
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
                child: Text('Скачать'),
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
    final outputFilePath = '${directory.path}/output.docx';
    final outputFile = File(outputFilePath);
    await outputFile.writeAsBytes(generatedDoc!);

    OpenFile.open(outputFile.path);
  }
}