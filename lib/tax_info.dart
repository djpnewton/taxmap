import 'package:flutter/material.dart';
import 'package:taxmap/tax_data.dart';

Widget _taxItem(Tax tax) {
  final type = switch (tax.type) {
    TaxType.capitalGains => 'Capital Gains',
    TaxType.corporate => 'Corporate',
    TaxType.income => 'Income',
    TaxType.inheritance => 'Estate',
    TaxType.sales => 'Sales',
    TaxType.wealth => 'Wealth',
  };
  final subtitle = IntrinsicHeight(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${tax.rate}'),
        if (tax.notes != null)
          const VerticalDivider(thickness: 1, color: Colors.grey),
        if (tax.notes != null)
          Text(
            '${tax.notes}',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    ),
  );
  return switch (tax) {
    (TaxCorporate _) => ListTile(
      dense: true,
      leading: Icon(Icons.info),
      title: Text(type),
      subtitle: subtitle,
    ),
    (TaxPersonal p) => ListTile(
      dense: true,
      leading: Icon(Icons.info),
      title: Text(type),
      subtitle: subtitle,
      trailing:
          p.territorial
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, color: Colors.green),
                  Text('Territorial'),
                ],
              )
              : p.citizenshipBased
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  Text('Citizenship Based'),
                ],
              )
              : null,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  countryName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
    },
  );
}
