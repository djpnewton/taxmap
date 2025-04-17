import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

enum TaxType { corporate, income, capitalGains, wealth, inheritance, sales }

abstract class Tax {
  final TaxType type;
  final double? rate;
  final String? notes;

  Tax({required this.type, required this.rate, required this.notes});
}

class TaxCorporate extends Tax {
  TaxCorporate({
    required super.type,
    required super.rate,
    required super.notes,
  });
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
  final Tax? corporate;
  final TaxPersonal? income;
  final TaxPersonal? capitalGains;
  final TaxPersonal? wealth;
  final TaxPersonal? inheritance;
  final Tax? sales;

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
    Tax? sales;
    if (country.containsKey('sales')) {
      sales = TaxCorporate(
        type: TaxType.sales,
        rate:
            country['sales'].containsKey('rate')
                ? country['sales']['rate']
                : null,
        notes:
            country['sales'].containsKey('notes')
                ? country['sales']['notes']
                : null,
      );
    }
    Tax? corporate;
    if (country.containsKey('corporate')) {
      corporate = TaxCorporate(
        type: TaxType.corporate,
        rate:
            country['corporate'].containsKey('rate')
                ? country['corporate']['rate']
                : null,
        notes:
            country['corporate'].containsKey('notes')
                ? country['corporate']['notes']
                : null,
      );
    }
    TaxPersonal? income;
    if (country.containsKey('income')) {
      income = TaxPersonal(
        type: TaxType.income,
        rate:
            country['income'].containsKey('rate')
                ? country['income']['rate']
                : null,
        notes:
            country['income'].containsKey('notes')
                ? country['income']['notes']
                : null,
        territorial:
            country['income'].containsKey('territorial')
                ? country['income']['territorial']
                : false,
        citizenshipBased:
            country['income'].containsKey('citizenship_based')
                ? country['income']['citizenship_based']
                : false,
      );
    }
    TaxPersonal? capitalGains;
    if (country.containsKey('capital_gains')) {
      capitalGains = TaxPersonal(
        type: TaxType.capitalGains,
        rate:
            country['capital_gains'].containsKey('rate')
                ? country['capital_gains']['rate']
                : null,
        notes:
            country['capital_gains'].containsKey('notes')
                ? country['capital_gains']['notes']
                : null,
        territorial:
            country['capital_gains'].containsKey('territorial')
                ? country['capital_gains']['territorial']
                : false,
        citizenshipBased:
            country['capital_gains'].containsKey('citizenship_based')
                ? country['capital_gains']['citizenship_based']
                : false,
      );
    }
    TaxPersonal? wealth;
    if (country.containsKey('wealth')) {
      wealth = TaxPersonal(
        type: TaxType.wealth,
        rate:
            country['wealth'].containsKey('rate')
                ? country['wealth']['rate']
                : null,
        notes:
            country['wealth'].containsKey('notes')
                ? country['wealth']['notes']
                : null,
        territorial:
            country['wealth'].containsKey('territorial')
                ? country['wealth']['territorial']
                : false,
        citizenshipBased:
            country['wealth'].containsKey('citizenship_based')
                ? country['wealth']['citizenship_based']
                : false,
      );
    }
    TaxPersonal? inheritance;
    if (country.containsKey('inheritance')) {
      inheritance = TaxPersonal(
        type: TaxType.inheritance,
        rate:
            country['inheritance'].containsKey('rate')
                ? country['inheritance']['rate']
                : null,
        notes:
            country['inheritance'].containsKey('notes')
                ? country['inheritance']['notes']
                : null,
        territorial:
            country['inheritance'].containsKey('territorial')
                ? country['inheritance']['territorial']
                : false,
        citizenshipBased:
            country['inheritance'].containsKey('citizenship_based')
                ? country['inheritance']['citizenship_based']
                : false,
      );
    }
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
