import 'package:flutter/services.dart';
import 'package:docx_template/docx_template.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:io';

class DocumentGenerator {
  static Future<void> generateAndEventDocument(Map<String, Object?> params, bool isSend) async {
    final ByteData templateData = await rootBundle.load('assets/template/cardboard.docx');
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
