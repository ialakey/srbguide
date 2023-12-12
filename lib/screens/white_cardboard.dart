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
              _buildTextFormFieldContainer(
                labelText: 'Презиме - Surname',
                child: TextFormField(
                  controller: _surnameController,
                  decoration: InputDecoration(labelText: 'Фамилия'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите фамилию';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer(
                labelText: 'Име - Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Имя'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer(
                labelText: 'Датум рођења - Date of birth',
                child:
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
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer(
                labelText: 'Пол - Sex',
                child:
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
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer2(
                labelText: 'Место и држава рођења',
                labelText2: 'Place and country of birth',
                child:
                TextFormField(
                  controller: _placeOfBirthController,
                  decoration: InputDecoration(labelText: 'Место рождения'),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer(
                labelText: 'Држављанство - Nationality',
                child:
                  TextFormField(
                    controller: _nationalityController,
                    decoration: InputDecoration(labelText: 'Национальность'),
                  ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer2(
                labelText: 'Врста и број путне или друге исправе о идентитету',
                labelText2: 'Type and number of travel document or other ID',
                child:
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _documentNumberController,
                    decoration: InputDecoration(labelText: 'Номер документа'),
                  ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer3(
                labelText1: 'Врста и број визе и место издавања',
                labelText2: 'Type and number of visa and place of issuance',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            if (newValue != null && newValue != 'Выбрать') {
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
                  ],
                ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer2(
                labelText: 'Адреса боравишта у Републици Србији',
                labelText2: 'Аddress of place of stay in the Republic of Serbia',
                child:
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'Адрес регистрации'),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer2(
                labelText: 'Податак о станодавцу (презиме и име и ЈМБГ, односно назив правног лица или предузетника и ПИБ)',
                labelText2: 'Surname, given name and personal identification number of the landlord/host ie, name of legal entity or entrepreneur and tax ID number).',
                child:
                  TextFormField(
                    controller: _ownerInfoController,
                    decoration: InputDecoration(labelText: 'Информация о владельце'),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
              ),
              SizedBox(height: 3),
              _buildTextFormFieldContainer2(
                labelText: 'Датум пријаве',
                labelText2: 'Date of registration',
                child:                       ListTile(
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
              ),
              SizedBox(height: 20),
                Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _saveData();
                        SnackbarUtils.showSnackbar(context, 'Данные сохранены!');
                      },
                      icon: Icon(Icons.check),
                      label: Text('Сохранить'),
                    ),
                    buildButton(Icons.telegram, 'Отправить', true),
                    buildButton(Icons.download, 'Скачать', false),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormFieldContainer({
    required String labelText,
    required Widget child,
  }) {
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
          SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  Widget _buildTextFormFieldContainer2({
    required String labelText,
    required String labelText2,
    required Widget child,
  }) {
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

  Widget _buildTextFormFieldContainer3({
    required String labelText1,
    required String labelText2,
    required Widget child,
  }) {
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
            labelText1,
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

  Widget buildButton(IconData icon, String label, bool isSending) {
    return TextButton.icon(
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
          generateAndEventDocument(params, isSending);
        }
      },
      icon: Icon(icon),
      label: Text(label),
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