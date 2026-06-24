import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'result_screen.dart';

class ManualPredictScreen extends StatefulWidget {
  const ManualPredictScreen({super.key});
  @override
  State<ManualPredictScreen> createState() => _ManualPredictScreenState();
}

class _ManualPredictScreenState extends State<ManualPredictScreen> {
  // Land
  double _landArea        = 10.0;
  double _distToCoast     = 10.0;
  double _soilPerm        = 0.7;
  double _brineSalinity   = 270.0;

  // Climate
  double _temperature     = 29.0;
  double _rainfall        = 80.0;
  double _humidity        = 70.0;
  double _solar           = 5.5;
  double _wind            = 15.0;

  int _year  = 2024;
  int _month = 6;

  bool _loading = false;

  Future<void> _predict() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.predictManual({
        'year': _year,
        'month': _month,
        'land_area': _landArea,
        'distance_to_coast': _distToCoast,
        'soil_permeability': _soilPerm,
        'temperature': _temperature,
        'rainfall': _rainfall,
        'humidity': _humidity,
        'solar_radiation': _solar,
        'wind_speed': _wind,
        'brine_salinity': _brineSalinity,
      });
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ResultScreen(result: result, isGeo: false)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.notViable));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(),
            const SizedBox(height: 20),

            // ── Land Section ───────────────────────────
            _SectionCard(
              icon: Icons.terrain_rounded,
              title: 'Land Parameters',
              color: AppTheme.primary,
              children: [
                _SliderTile(
                  label: 'Land Area',
                  unit: 'acres',
                  value: _landArea,
                  min: 1, max: 20, divisions: 38,
                  onChanged: (v) => setState(() => _landArea = v),
                ),
                _SliderTile(
                  label: 'Distance to Coast',
                  unit: 'km',
                  value: _distToCoast,
                  min: 0.5, max: 30, divisions: 59,
                  onChanged: (v) => setState(() => _distToCoast = v),
                ),
                _SliderTile(
                  label: 'Soil Permeability',
                  unit: '',
                  value: _soilPerm,
                  min: 0.3, max: 1.0, divisions: 14,
                  onChanged: (v) => setState(() => _soilPerm = double.parse(v.toStringAsFixed(2))),
                ),
                _SliderTile(
                  label: 'Brine Salinity',
                  unit: 'g/L',
                  value: _brineSalinity,
                  min: 150, max: 350, divisions: 40,
                  onChanged: (v) => setState(() => _brineSalinity = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Climate Section ────────────────────────
            _SectionCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Climate Parameters',
              color: AppTheme.accent,
              children: [
                _SliderTile(
                  label: 'Temperature',
                  unit: '°C',
                  value: _temperature,
                  min: 25, max: 35, divisions: 20,
                  onChanged: (v) => setState(() => _temperature = v),
                ),
                _SliderTile(
                  label: 'Monthly Rainfall',
                  unit: 'mm',
                  value: _rainfall,
                  min: 0, max: 300, divisions: 60,
                  onChanged: (v) => setState(() => _rainfall = v),
                ),
                _SliderTile(
                  label: 'Humidity',
                  unit: '%',
                  value: _humidity,
                  min: 50, max: 90, divisions: 40,
                  onChanged: (v) => setState(() => _humidity = v),
                ),
                _SliderTile(
                  label: 'Solar Radiation',
                  unit: 'kWh/m²',
                  value: _solar,
                  min: 4.0, max: 7.0, divisions: 30,
                  onChanged: (v) => setState(() => _solar = double.parse(v.toStringAsFixed(1))),
                ),
                _SliderTile(
                  label: 'Wind Speed',
                  unit: 'km/h',
                  value: _wind,
                  min: 0, max: 30, divisions: 30,
                  onChanged: (v) => setState(() => _wind = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Evaporation preview ────────────────────
            _EvaporationPreview(
              temperature: _temperature, solar: _solar,
              wind: _wind, humidity: _humidity, rainfall: _rainfall,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _loading ? null : _predict,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.science_outlined),
              label: Text(_loading ? 'Analysing...' : 'Run Viability Analysis'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Adjust all parameters to match your land and current climate conditions.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.primaryDark),
        ),
      ),
    ]),
  );
}

// ── Section Card ──────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;
  const _SectionCard({required this.icon, required this.title,
      required this.color, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark,
            )),
          ]),
        ),
        const Divider(height: 1),
        ...children,
      ],
    ),
  );
}

// ── Slider Tile ───────────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.unit,
      required this.value, required this.min, required this.max,
      required this.divisions, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMid,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${value.toStringAsFixed(unit == '' ? 2 : 1)} $unit',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  )),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.border,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value, min: min, max: max, divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min', style: GoogleFonts.dmSans(fontSize: 10, color: AppTheme.textLight)),
            Text('$max', style: GoogleFonts.dmSans(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

// ── Evaporation Preview ───────────────────────────────────────
class _EvaporationPreview extends StatelessWidget {
  final double temperature, solar, wind, humidity, rainfall;
  const _EvaporationPreview({required this.temperature, required this.solar,
      required this.wind, required this.humidity, required this.rainfall});

  @override
  Widget build(BuildContext context) {
    final evap = 0.45 * temperature + 0.35 * solar + 0.25 * wind
        - 0.5 * humidity / 10 - 0.4 * rainfall / 30;
    final isGood = evap > 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isGood ? AppTheme.viable : AppTheme.notViable).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isGood ? AppTheme.viable : AppTheme.notViable).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Evaporation Index (preview)',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textMid,
                )),
            Text(evap.toStringAsFixed(2),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: isGood ? AppTheme.viable : AppTheme.notViable,
                )),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isGood ? AppTheme.viable : AppTheme.notViable).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isGood ? '✓ Above threshold' : '✗ Below threshold (>10)',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isGood ? AppTheme.viable : AppTheme.notViable,
                )),
          ),
        ],
      ),
    );
  }
}
