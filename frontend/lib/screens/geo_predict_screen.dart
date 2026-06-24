import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'result_screen.dart';

class GeoPredictScreen extends StatefulWidget {
  const GeoPredictScreen({super.key});
  @override
  State<GeoPredictScreen> createState() => _GeoPredictScreenState();
}

class _GeoPredictScreenState extends State<GeoPredictScreen> {
  LatLng? _selected;
  double _landArea      = 10.0;
  double _soilPerm      = 0.8;
  double _brineSalinity = 280.0;
  bool   _loading       = false;
  String? _error;

  // Key saltern regions in Sri Lanka for reference markers
  final List<Map<String, dynamic>> _knownRegions = [
    {'name': 'Puttalam', 'lat': 8.0362, 'lng': 79.8428},
    {'name': 'Hambantota', 'lat': 6.1241, 'lng': 81.1185},
    {'name': 'Mannar', 'lat': 8.9778, 'lng': 79.9045},
    {'name': 'Kalpitiya', 'lat': 8.2300, 'lng': 79.7650},
  ];

  Future<void> _analyse() async {
    if (_selected == null) {
      setState(() => _error = 'Please tap a location on the map first.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.predictGeo(
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
        landArea: _landArea,
        soilPermeability: _soilPerm,
        brineSalinity: _brineSalinity,
      );
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ResultScreen(result: result, isGeo: true,
                lat: _selected!.latitude, lng: _selected!.longitude)));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geo Analysis')),
      body: Column(
        children: [
          // ── Map ─────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(7.8731, 80.7718),
                    initialZoom: 7.0,
                    onTap: (_, point) {
                      final lat = point.latitude;
                      final lng = point.longitude;
                      if (5.9 <= lat && lat <= 9.9 && 79.5 <= lng && lng <= 82.0) {
                        setState(() { _selected = point; _error = null; });
                      } else {
                        setState(() => _error = 'Please select a location within Sri Lanka.');
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.salterniq.app',
                    ),
                    // Known saltern region markers
                    MarkerLayer(
                      markers: [
                        ..._knownRegions.map((r) => Marker(
                          point: LatLng(r['lat'], r['lng']),
                          width: 80, height: 40,
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(r['name'],
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9, color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                            const Icon(Icons.location_on,
                                color: AppTheme.accent, size: 16),
                          ]),
                        )),
                        // Selected pin
                        if (_selected != null) Marker(
                          point: _selected!,
                          width: 40, height: 50,
                          child: const Column(children: [
                            Icon(Icons.location_pin,
                                color: AppTheme.primary, size: 40),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Instruction overlay ──────────────
                if (_selected == null)
                  Positioned(
                    top: 12, left: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.93),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.touch_app_outlined,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Tap anywhere in Sri Lanka to analyse',
                            style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppTheme.textDark,
                            )),
                      ]),
                    ),
                  ),

                // ── Selected coords chip ─────────────
                if (_selected != null)
                  Positioned(
                    top: 12, left: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.93),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.location_pin,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selected!.latitude.toStringAsFixed(4)}, '
                              '${_selected!.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                          GestureDetector(
                            onTap: () => setState(() => _selected = null),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white60, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Parameters panel ─────────────────────
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Land Parameters',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),

                    _CompactSlider(
                      label: 'Land Area',
                      unit: 'acres',
                      value: _landArea,
                      min: 1, max: 20,
                      onChanged: (v) => setState(() => _landArea = v),
                    ),
                    _CompactSlider(
                      label: 'Soil Permeability',
                      unit: '',
                      value: _soilPerm,
                      min: 0.3, max: 1.0,
                      onChanged: (v) => setState(() => _soilPerm = double.parse(v.toStringAsFixed(2))),
                    ),
                    _CompactSlider(
                      label: 'Brine Salinity',
                      unit: 'g/L',
                      value: _brineSalinity,
                      min: 150, max: 350,
                      onChanged: (v) => setState(() => _brineSalinity = v),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.notViable.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(
                              color: AppTheme.notViable, fontSize: 12)),
                      ),
                    ],

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _analyse,
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.analytics_outlined, size: 18),
                      label: Text(_loading ? 'Fetching climate data...' : 'Analyse This Location'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSlider extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _CompactSlider({required this.label, required this.unit,
      required this.value, required this.min, required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(
        width: 120,
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600,
        )),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.border,
            thumbColor: AppTheme.primary,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ),
      SizedBox(
        width: 64,
        child: Text(
          '${value.toStringAsFixed(unit == '' ? 2 : 1)}${unit.isNotEmpty ? ' $unit' : ''}',
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ]),
  );
}
