import 'exchange_rate_parser.dart';

class ExchangeOffice {
  final String name;
  final String url;
  final ExchangeRateParser parser;

  ExchangeOffice({required this.name, required this.url, required this.parser});
}