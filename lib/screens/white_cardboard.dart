import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/screens/document_scanner.dart';
import 'package:srbguide/service/document_generate.dart';
import 'package:srbguide/widget/text_form_field.dart';
import 'package:srbguide/widget/text_form_field2.dart';
import 'package:srbguide/widget/themed_icon.dart';

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
      appBar: AppBar(
        centerTitle: true,
        title: Text('Образац 1.'),
        actions: [
          IconButton(
            icon: ThemedIcon(
              lightIcon: 'assets/icons_24x24/expand.png',
              darkIcon: 'assets/icons_24x24/expand.png',
              size: 24.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DocumentScannerScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/circle-ellipsis-vertical.png',
              darkIcon: 'assets/icons_24x24/circle-ellipsis-vertical.png',
              size: 24.0,
            ),
            onSelected: (value) {
              if (value == 'save') {
                _saveData();
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Сохранено!',
                );
              } else if (value == 'send') {
                _onButtonPressed(true);
              } else if (value == 'download') {
                _onButtonPressed(false);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'save',
                child: ListTile(
                  leading:
                  ThemedIcon(
                    lightIcon: 'assets/icons_24x24/assept-document.png',
                    darkIcon: 'assets/icons_24x24/assept-document.png',
                    size: 24.0,
                  ),
                  title: Text('Сохранить'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'send',
                child: ListTile(
                  leading:
                  ThemedIcon(
                    lightIcon: 'assets/icons_24x24/paper-plane.png',
                    darkIcon: 'assets/icons_24x24/paper-plane.png',
                    size: 24.0,
                  ),
                  title: Text('Поделиться'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'download',
                child: ListTile(
                  leading:
                  ThemedIcon(
                    lightIcon: 'assets/icons_24x24/download.png',
                    darkIcon: 'assets/icons_24x24/download.png',
                    size: 24.0,
                  ),
                  title: Text('Скачать'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormFieldContainer(
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
              SizedBox(height: 2),
              TextFormFieldContainer(
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
              SizedBox(height: 2),
              TextFormFieldContainer(
                labelText: 'Датум рођења - Date of birth',
                child:
                ListTile(
                  title: Text(
                    'Дата рождения: ${_dateOfBirth != null ? _dateOfBirth!.toString().split(' ')[0] : 'Выберите дату'}',
                  ),
                  trailing:
                  ThemedIcon(
                    lightIcon: 'assets/icons_24x24/calendar.png',
                    darkIcon: 'assets/icons_24x24/calendar.png',
                    size: 24.0,
                  ),
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
              SizedBox(height: 2),
              TextFormFieldContainer(
                labelText: 'Пол - Sex',
                child:
                  DropdownButtonFormField<String>(
                    icon:
                    ThemedIcon(
                      lightIcon: 'assets/icons_24x24/caret-down.png',
                      darkIcon: 'assets/icons_24x24/caret-down.png',
                      size: 24.0,
                    ),
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
              SizedBox(height: 2),
              TextFormFieldContainer2(
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
              SizedBox(height: 2),
              TextFormFieldContainer(
                labelText: 'Држављанство - Nationality',
                child:
                  TextFormField(
                    controller: _nationalityController,
                    decoration: InputDecoration(labelText: 'Национальность'),
                  ),
              ),
              SizedBox(height: 3),
              TextFormFieldContainer2(
                labelText: 'Врста и број путне или друге исправе о идентитету',
                labelText2: 'Type and number of travel document or other ID',
                child:
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _documentNumberController,
                    decoration: InputDecoration(labelText: 'Номер документа'),
                  ),
              ),
              SizedBox(height: 2),
              TextFormFieldContainer2(
                labelText: 'Врста и број визе и место издавања',
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
                          icon:
                          ThemedIcon(
                            lightIcon: 'assets/icons_24x24/caret-down.png',
                            darkIcon: 'assets/icons_24x24/caret-down.png',
                            size: 24.0,
                          ),
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
                      trailing:
                      ThemedIcon(
                        lightIcon: 'assets/icons_24x24/calendar.png',
                        darkIcon: 'assets/icons_24x24/calendar.png',
                        size: 24.0,
                      ),
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
              SizedBox(height: 2),
              TextFormFieldContainer2(
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
              SizedBox(height: 2),
              TextFormFieldContainer2(
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
              SizedBox(height: 2),
              TextFormFieldContainer2(
                labelText: 'Датум пријаве',
                labelText2: 'Date of registration',
                child:
                ListTile(
                  title: Text(
                    'Дата регистрации: ${_registrationDate != null ? _registrationDate!.toString().split(' ')[0] : 'Выберите дату'}',
                  ),
                  trailing:
                  ThemedIcon(
                    lightIcon: 'assets/icons_24x24/calendar.png',
                    darkIcon: 'assets/icons_24x24/calendar.png',
                    size: 24.0,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _onButtonPressed(bool isSending) {
    if (_formKey.currentState!.validate() && isFormValid()) {
      final params = {
        'surname': _surnameController.text,
        'name': _nameController.text,
        'dateOfBirth': _dateOfBirth.toString().split(' ')[0],
        'sex': _gender,
        'placeOfBirth': _placeOfBirthController.text,
        'nationality': _nationalityController.text,
        'documentNumber': _documentNumberController.text,
        'dateOfEntry': '${_arrivalDate.toString().split(' ')[0]} ${_placeArrivalController.text}',
        'addressOfPlace': _addressController.text,
        'landlordInformation': _ownerInfoController.text,
        'dateOfRegistration': _registrationDate.toString().split(' ')[0],
      };
      DocumentGenerator.generateAndEventDocument(params, isSending);
    } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Ошибка!',
          text: 'Заполните все поля',
        );
      }
    }

  bool isFormValid() {
    return _surnameController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _dateOfBirth != null &&
        _gender != null &&
        _placeOfBirthController.text.isNotEmpty &&
        _nationalityController.text.isNotEmpty &&
        _documentNumberController.text.isNotEmpty &&
        _arrivalDate != null &&
        _placeArrivalController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _ownerInfoController.text.isNotEmpty &&
        _registrationDate != null;
  }
}