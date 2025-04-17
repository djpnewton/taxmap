import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

enum TaxType { corporate, income, capitalGains, wealth, inheritance, sales }

class Tax {
  final TaxType type;
  final double? rate;
  final String? notes;

  Tax({required this.type, required this.rate, required this.notes});
}

class TaxPersonal extends Tax {
  final bool territorial;
  final bool citizenshipBased;

  TaxPersonal({
    required super.type,
    required super.rate,
    required super.notes,
    this.territorial = false,
    this.citizenshipBased = false,
  });
}

class CountryTax {
  final String name;
  final Tax corporate;
  final TaxPersonal income;
  final TaxPersonal capitalGains;
  final TaxPersonal wealth;
  final TaxPersonal inheritance;
  final Tax sales;

  CountryTax({
    required this.name,
    required this.corporate,
    required this.income,
    required this.capitalGains,
    required this.wealth,
    required this.inheritance,
    required this.sales,
  });
}

/// Parses the YAML data from the assets/tax_data.yaml file and returns a list
/// of CountryTax objects.
Future<Map<String, CountryTax>> parseTaxData() async {
  final String yamlData = await rootBundle.loadString('assets/tax_data.yaml');
  final YamlMap parsedYaml = loadYaml(yamlData);

  final Map<String, CountryTax> countryTaxes = {};

  final countries = parsedYaml['countries'] as YamlMap;

  for (final entry in countries.entries) {
    final String name = entry.key;
    final YamlMap country = entry.value;
    final Tax sales = Tax(
      type: TaxType.sales,
      rate: country['sales']['rate'],
      notes: country['sales']['notes'],
    );
    final Tax corporate = Tax(
      type: TaxType.corporate,
      rate: country['corporate']['rate'],
      notes: country['corporate']['notes'],
    );
    final TaxPersonal income = TaxPersonal(
      type: TaxType.income,
      rate: country['income']['rate'],
      notes: country['income']['notes'],
      territorial: country['income']['territorial'] ?? false,
      citizenshipBased: country['income']['citizenship_based'] ?? false,
    );
    final TaxPersonal capitalGains = TaxPersonal(
      type: TaxType.capitalGains,
      rate: country['capital_gains']['rate'],
      notes: country['capital_gains']['notes'],
      territorial: country['capital_gains']['territorial'] ?? false,
      citizenshipBased: country['capital_gains']['citizenship_based'] ?? false,
    );
    final TaxPersonal wealth = TaxPersonal(
      type: TaxType.wealth,
      rate: country['wealth']['rate'],
      notes: country['wealth']['notes'],
      territorial: country['wealth']['territorial'] ?? false,
      citizenshipBased: country['wealth']['citizenship_based'] ?? false,
    );
    final TaxPersonal inheritance = TaxPersonal(
      type: TaxType.inheritance,
      rate: country['inheritance']['rate'],
      notes: country['inheritance']['notes'],
      territorial: country['inheritance']['territorial'] ?? false,
      citizenshipBased: country['inheritance']['citizenship_based'] ?? false,
    );
    final CountryTax countryTax = CountryTax(
      name: name,
      corporate: corporate,
      income: income,
      capitalGains: capitalGains,
      wealth: wealth,
      inheritance: inheritance,
      sales: sales,
    );
    countryTaxes[name] = countryTax;
  }
  return countryTaxes;
}
