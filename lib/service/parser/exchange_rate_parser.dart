abstract class ExchangeRateParser {
  Future<void> parse();

  String getValueEur();
  String getCurrencyEur();
  String getExchangeEur();

  String getValueRub();
  String getCurrencyRub();
  String getExchangeRub();

  String getValueUsd();
  String getCurrencyUsd();
  String getExchangeUsd();
}