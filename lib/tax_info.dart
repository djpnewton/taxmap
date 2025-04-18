import 'package:flutter/material.dart';
import 'package:taxmap/tax_data.dart';

String _rateString(double? rate) {
  if (rate == null) return '';
  return '$rate%';
}

String _notesString(String? notes, bool territorial, bool citizenshipBased) {
  if (notes == null || notes.isEmpty) {
    if (territorial) return ' - territorial tax';
    if (citizenshipBased) return ' - CITIZENSHIP BASED TAX';
    return '';
  }
  if (territorial) return ' ($notes) - territorial tax';
  if (citizenshipBased) return ' ($notes) - CITIZENSHIP BASED TAX';
  return ' ($notes)';
}

Widget _taxItem(Tax tax) {
  final type = switch (tax.type) {
    TaxType.capitalGains => 'Capital Gains',
    TaxType.corporate => 'Corporate',
    TaxType.income => 'Income',
    TaxType.inheritance => 'Estate',
    TaxType.sales => 'Sales',
    TaxType.wealth => 'Wealth',
  };
  final territorialIcon = Icon(Icons.check, color: Colors.green);
  final citizenshipBased = Icon(Icons.warning, color: Colors.red);
  final icon = Icon(Icons.info);
  return switch (tax) {
    (TaxCorporate c) => ListTile(
      leading: icon,
      title: Text(type),
      subtitle: Text(
        '${_rateString(c.rate)}${_notesString(c.notes, false, false)}',
      ),
    ),
    (TaxPersonal p) => ListTile(
      leading:
          p.territorial
              ? territorialIcon
              : p.citizenshipBased
              ? citizenshipBased
              : icon,
      title: Text(type),
      subtitle: Text(
        '${_rateString(p.rate)}${_notesString(p.notes, p.territorial, p.citizenshipBased)}',
      ),
    ),
    _ => SizedBox(),
  };
}

Widget _taxList(CountryTax? countryTax) {
  if (countryTax == null) {
    return const Text('No tax data available');
  }
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (countryTax.income != null) _taxItem(countryTax.income!),
      if (countryTax.capitalGains != null) _taxItem(countryTax.capitalGains!),
      if (countryTax.wealth != null) _taxItem(countryTax.wealth!),
      if (countryTax.inheritance != null) _taxItem(countryTax.inheritance!),
      if (countryTax.corporate != null) _taxItem(countryTax.corporate!),
      if (countryTax.sales != null) _taxItem(countryTax.sales!),
    ],
  );
}

void taxInfo(BuildContext context, String countryName, CountryTax? countryTax) {
  Scaffold.of(context).showBottomSheet((context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(countryName, style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _taxList(countryTax),
        ],
      ),
    );
  });
}
