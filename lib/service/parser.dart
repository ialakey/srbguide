import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

Future<void> parsePromonet() async {
  String url = 'https://www.promonet.rs';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final document = htmlParser.parse(response.body);
    final table = document.querySelector('.tablepress');

    if (table != null) {
      final thead = table.querySelector('thead');
      if (thead != null) {
        final headerCells = thead.querySelectorAll('th');
        List<String> headers = headerCells.map((headerCell) => headerCell.text.trim()).toList();
        print('Заголовок: ${headers.join(" ")}');
      }
      final tbody = table.querySelector('tbody');
      if (tbody != null) {
        final rows = tbody.querySelectorAll('tr');
        for (var row in rows) {
          final cells = row.querySelectorAll('td');
          List<String> rowContent = cells.map((cell) => cell.text.trim()).toList();
          print('Содержимое строки: ${rowContent.join(" ")}');
        }
      }
    } else {
      print('Таблица с классом "tablepress" не найдена.');
    }
  } else {
    print('Ошибка при получении HTML: ${response.statusCode}');
  }
}
