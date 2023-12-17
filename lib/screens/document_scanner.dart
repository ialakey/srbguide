// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:camera/camera.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:quickalert/quickalert.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class DocumentScannerScreen extends StatefulWidget {
//   @override
//   _DocumentScannerScreenState createState() => _DocumentScannerScreenState();
// }
//
// class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
//   late CameraController _cameraController;
//   bool _isCameraInitialized = false;
//   String _extractedText = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _loadText();
//   }
//
//   Future<void> _loadText() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _extractedText = prefs.getString('extractedText') ?? '';
//     });
//   }
//
//   Future<void> _saveText(String text) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('extractedText', text);
//   }
//
//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//
//     if (cameras.isNotEmpty) {
//       _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
//       await _cameraController.initialize();
//       if (!mounted) return;
//
//       setState(() {
//         _isCameraInitialized = true;
//       });
//     }
//   }
//
//   Future<void> _processImage() async {
//     if (!_cameraController.value.isTakingPicture) {
//       try {
//         QuickAlert.show(
//           context: context,
//           type: QuickAlertType.loading,
//           title: 'Загрузка',
//           text: 'Извлекаем данные',
//         );
//
//         final XFile picture = await _cameraController.takePicture();
//         final inputImage = InputImage.fromFilePath(picture.path);
//         final textRecognizer = GoogleMlKit.vision.textRecognizer();
//         final RecognizedText visionText = await textRecognizer.processImage(inputImage);
//
//         String extractedText = visionText.text;
//
//         setState(() {
//           _extractedText = extractedText;
//           _saveText(extractedText);
//         });
//
//         Navigator.pop(context);
//
//       } catch (e) {
//         Navigator.pop(context);
//         setState(() {
//           _extractedText = 'Ошибка';
//         });
//         QuickAlert.show(
//           context: context,
//           type: QuickAlertType.error,
//           title: 'Ошибка',
//           text: 'Произошла ошибка при извлечении данных',
//         );
//       }
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
//
//     if (pickedImage != null) {
//       setState(() {
//         _extractedText = '';
//         _isCameraInitialized = false;
//       });
//
//       File? imageFile = File(pickedImage.path);
//       final inputImage = InputImage.fromFile(imageFile);
//       final textRecognizer = GoogleMlKit.vision.textRecognizer();
//       final RecognizedText visionText = await textRecognizer.processImage(inputImage);
//
//       String extractedText = visionText.text;
//
//       setState(() {
//         _extractedText = extractedText;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Сканирование test'),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Expanded(
//             child: Card(
//               elevation: 4,
//               margin: EdgeInsets.all(14),
//               child: _isCameraInitialized
//                   ? _cameraPreviewWidget()
//                   : Center(
//                 child: ElevatedButton(
//                   onPressed: _pickImage,
//                   child: Text('Выбрать из галереи'),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 20),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(horizontal: 20.0),
//               child: SelectableText(
//                 'Извлеченный текст:\n$_extractedText',
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _processImage,
//         child: Icon(Icons.camera),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
//
//   Widget _cameraPreviewWidget() {
//     return AspectRatio(
//       aspectRatio: _cameraController.value.aspectRatio,
//       child: CameraPreview(_cameraController),
//     );
//   }
// }