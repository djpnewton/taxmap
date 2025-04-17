import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'dart:convert';

import 'tax_data.dart';
import 'about_page.dart';

final log = Logger('Main');

// TODO: ontap highlight country and show details in a side bar or floating panel
// TODO: add a filter panel change how countries are colored based on your tax thresholds
// TODO: add a search bar to search for countries?
// TODO: add a news feed

void main() {
  runApp(const MyApp());
}

class Country {
  final String name;
  final List<Polygon> polygons;

  Country({required this.name, required this.polygons});
}

class HitValue {
  final String countryName;
  final CountryTax? countryTax;

  HitValue({required this.countryName, required this.countryTax});

  @override
  String toString() {
    return 'HitValue(countryName: $countryName)';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tax Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MyHomePage(title: 'Tax Map Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Polygon<HitValue>> _countryPolygons = [];
  // ignore: unused_field
  List<Country> _countries = [];
  Map<String, CountryTax> _countryTaxData = {};

  final LayerHitNotifier<HitValue> _hitNotifier = ValueNotifier(null);
  List<Polygon<HitValue>>? _hoverGons;

  @override
  void initState() {
    super.initState();
    _loadTaxData();
    _loadGeoJson();
  }

  Future<void> _loadTaxData() async {
    final taxData = await parseTaxData();
    setState(() {
      _countryTaxData = taxData;
    });
  }

  Polygon<HitValue> _makePolygon(List<LatLng> points, String countryName) {
    final countryTax = _countryTaxData[countryName.toLowerCase()];
    final personalIncomeRate = countryTax?.income?.rate;
    final color =
        personalIncomeRate == null
            ? Colors.grey
            : personalIncomeRate > 20
            ? Colors.red
            : personalIncomeRate > 15
            ? Colors.orange
            : Colors.green;
    // TODO: add colors/identifiers for other tax rates/conditions

    return Polygon<HitValue>(
      points: points,
      // ignore: deprecated_member_use
      color: color.withOpacity(0.5),
      borderColor: color,
      borderStrokeWidth: 1.0,
      hitValue: HitValue(countryName: countryName, countryTax: countryTax),
    );
  }

  Future<void> _loadGeoJson() async {
    final String geoJsonData = await rootBundle.loadString(
      'assets/countries.geo.json',
    );
    final Map<String, dynamic> geoJson = json.decode(geoJsonData);

    final List<Country> countries = [];
    final List<Polygon<HitValue>> countryPolygons = [];
    // Iterate through each feature in the GeoJSON
    for (final feature in geoJson['features']) {
      final name = feature['properties']['name'] as String;
      log.info(name);
      if (name == 'Antarctica') {
        continue; // Skip Antarctica
      }

      final List<Polygon<HitValue>> polygons = [];
      final Map<String, dynamic> geometry = feature['geometry'];
      if (geometry['type'] == 'MultiPolygon') {
        // Handle MultiPolygon
        final List<dynamic> multiPolygonGroup = geometry['coordinates'];
        for (final List<dynamic> polygonGroup in multiPolygonGroup) {
          for (final List<dynamic> coordinates in polygonGroup) {
            final List<LatLng> points =
                coordinates.map((coord) {
                  assert(coord is List);
                  assert(coord.length == 2);
                  return LatLng(
                    (coord[1] as num).toDouble(),
                    (coord[0] as num).toDouble(),
                  );
                }).toList();
            final polygon = _makePolygon(points, name);
            polygons.add(polygon);
            countryPolygons.add(polygon);
          }
        }
        countries.add(Country(name: name, polygons: polygons));
      }
      if (geometry['type'] == 'Polygon') {
        // Handle Polygon
        final List<dynamic> polygonGroup = geometry['coordinates'];
        for (final List<dynamic> coordinates in polygonGroup) {
          final List<LatLng> points =
              coordinates.map((coord) {
                assert(coord is List);
                assert(coord.length == 2);
                return LatLng(
                  (coord[1] as num).toDouble(),
                  (coord[0] as num).toDouble(),
                );
              }).toList();

          final polygon = _makePolygon(points, name);
          polygons.add(polygon);
          countryPolygons.add(polygon);
        }
        countries.add(Country(name: name, polygons: polygons));
      }
    }

    setState(() {
      _countryPolygons = countryPolygons;
      _countries = countries;
    });
  }

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

  void _tapModal() {
    final hitResult = _hitNotifier.value;
    if (hitResult != null) {
      final hitValue = hitResult.hitValues.first;
      final coord = hitResult.coordinate;
      final countryName = hitValue.countryName;
      final countryTax = hitValue.countryTax;
      log.info('Tapped on: $countryName');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(countryName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _taxList(countryTax),
                const SizedBox(height: 20),
                Text('Latitude: ${coord.latitude}'),
                Text('Longitude: ${coord.longitude}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Tax Map',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: FlutterMap(
        options: MapOptions(initialZoom: 2),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MouseRegion(
            hitTestBehavior: HitTestBehavior.deferToChild,
            cursor: SystemMouseCursors.click,
            onHover: (event) {
              // use onHover and onExit to show highlighted country
              // (wont work on touchscreens)
              final hit = _hitNotifier.value;
              if (hit != null) {
                final hitValue = hit.hitValues.first;
                final countryName = hitValue.countryName;
                log.info('Mouse hovered: $countryName');

                final hoverGons =
                    _countryPolygons
                        .where(
                          (polygon) =>
                              polygon.hitValue?.countryName == countryName,
                        )
                        .toList();
                setState(() => _hoverGons = hoverGons);
              }
            },
            onExit: (event) {
              log.info('Mouse exited');
              setState(() => _hoverGons = null);
            },
            child: GestureDetector(
              onTap: () => _tapModal(),
              child: PolygonLayer(
                polygons: [..._countryPolygons, ...?_hoverGons],
                hitNotifier: _hitNotifier,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
