import 'package:shared_preferences/shared_preferences.dart';

enum TaxFilterType { income, capitalGains }

class TaxFilter {
  TaxFilterType type;
  double rate;
  bool territorial;

  TaxFilter({
    required this.type,
    required this.rate,
    required this.territorial,
  });
}

class Settings {
  static const String _taxFilterKey = 'taxFilter';

  /// Saves the selected tax filter to shared preferences.
  static Future<void> saveTaxFilter(TaxFilter taxFilter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_taxFilterKey}Type', taxFilter.type.name);
    await prefs.setDouble('${_taxFilterKey}Rate', taxFilter.rate);
    await prefs.setBool('${_taxFilterKey}Territorial', taxFilter.territorial);
  }

  /// Loads the selected tax filter from shared preferences.
  static Future<TaxFilter> loadTaxFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final type =
        prefs.getString('${_taxFilterKey}Type') ?? TaxFilterType.income.name;
    final rate = prefs.getDouble('${_taxFilterKey}Rate') ?? 15;
    final territorial = prefs.getBool('${_taxFilterKey}Territorial') ?? false;
    return TaxFilter(
      type: TaxFilterType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => TaxFilterType.income,
      ),
      rate: rate,
      territorial: territorial,
    );
  }
}
