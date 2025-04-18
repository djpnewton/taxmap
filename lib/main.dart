import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:taxmap/tax_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'tax_data.dart';
import 'about_page.dart';
import 'settings.dart';

final log = Logger('Main');

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

  TaxFilter _taxFilter = TaxFilter(
    type: TaxFilterType.income,
    rate: 15,
    territorial: false,
  );

  @override
  void initState() {
    super.initState();
    Settings.loadTaxFilter().then((value) {
      setState(() {
        _taxFilter = value;
      });
    });
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
    var color = Colors.grey;
    final countryTax = _countryTaxData[countryName.toLowerCase()];
    if (countryTax != null) {
      double rate;
      bool isTerritorial = false;
      switch (_taxFilter.type) {
        case TaxFilterType.income:
          rate = countryTax.income?.rate ?? 0;
          isTerritorial = countryTax.income?.territorial ?? false;
          break;
        case TaxFilterType.capitalGains:
          rate = countryTax.capitalGains?.rate ?? 0;
          isTerritorial = countryTax.capitalGains?.territorial ?? false;
          break;
      }
      if (_taxFilter.territorial) {
        color = isTerritorial || rate == 0 ? Colors.blue : Colors.red;
      } else {
        color = rate > _taxFilter.rate ? Colors.red : Colors.green;
      }
    }
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

  void _tapCountry(BuildContext context) {
    final hitResult = _hitNotifier.value;
    if (hitResult != null) {
      final hitValue = hitResult.hitValues.first;
      final coord = hitResult.coordinate;
      final countryName = hitValue.countryName;
      final countryTax = hitValue.countryTax;
      log.info('Tapped on: $countryName');
      log.info('Coordinate: $coord');
      log.info('Country Tax: $countryTax');
      taxInfo(context, countryName, countryTax);
    }
  }

  void _updateFilter(
    TaxFilterType type,
    double threshold, [
    bool? territorialOnly,
  ]) {
    setState(() {
      _taxFilter.type = type;
      _taxFilter.rate = threshold;
      if (territorialOnly != null) {
        _taxFilter.territorial = territorialOnly;
      }
      Settings.saveTaxFilter(_taxFilter);
      _loadGeoJson();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              // Open the MacroDash website
              const url = 'https://macrodash.me';
              launchUrl(Uri.parse(url));
            },
            child: const Text(
              'Visit macrodash.me',
              style: TextStyle(
                fontSize: 12, // Small text
                color: Colors.white, // Text color
              ),
            ),
          ),
        ],
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
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Text(
                'Filter countries by tax rate:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<TaxFilterType>(
                value: _taxFilter.type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: TaxFilterType.income,
                    child: Text('Income Tax'),
                  ),
                  DropdownMenuItem(
                    value: TaxFilterType.capitalGains,
                    child: Text('Capital Gains Tax'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateFilter(
                      value,
                      _taxFilter.rate,
                      _taxFilter.territorial,
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Threshold:'),
                  Expanded(
                    child: Slider(
                      value: _taxFilter.rate,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: _taxFilter.rate.toStringAsFixed(1),
                      onChanged:
                          _taxFilter.territorial
                              ? null
                              : (value) {
                                _updateFilter(
                                  _taxFilter.type,
                                  value,
                                  _taxFilter.territorial,
                                );
                              },
                    ),
                  ),
                  Text('${_taxFilter.rate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CheckboxListTile(
                title: const Text('Territorial only'),
                value: _taxFilter.territorial,
                onChanged: (checked) {
                  if (checked != null) {
                    _updateFilter(_taxFilter.type, _taxFilter.rate, checked);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
      body: Builder(
        // Create an inner BuildContext so that the onPressed methods
        // can refer to the Scaffold with Scaffold.of()
        builder: (context) {
          return FlutterMap(
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
                  onTap: () => _tapCountry(context),
                  child: PolygonLayer(
                    polygons: [..._countryPolygons, ...?_hoverGons],
                    hitNotifier: _hitNotifier,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
