import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isGeo;
  final double? lat, lng;

  const ResultScreen({
    super.key,
    required this.result,
    required this.isGeo,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final viable = result['viable'] == 1;
    final prob   = (result['viability_probability'] as num).toDouble();
    final yield_ = (result['estimated_yield_tons'] as num?)?.toDouble() ?? 0;
    final recs   = List<String>.from(result['recommendation'] ?? []);
    final climate = result['climate'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Analysis Result'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 18),
            label: Text('Home', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Verdict banner ─────────────────────
            _VerdictBanner(viable: viable, probability: prob),
            const SizedBox(height: 20),

            // ── Gauge + yield ──────────────────────
            Row(
              children: [
                Expanded(child: _GaugeCard(probability: prob, viable: viable)),
                const SizedBox(width: 14),
                Expanded(child: viable
                    ? _YieldCard(yield_: yield_)
                    : _NotViableCard()),
              ],
            ),
            const SizedBox(height: 20),

            // ── Climate summary (geo only) ─────────
            if (isGeo && climate != null) ...[
              _SectionTitle('Climate Data Retrieved'),
              const SizedBox(height: 10),
              _ClimateGrid(climate: climate),
              const SizedBox(height: 20),
            ],

            // ── Recommendations ────────────────────
            if (recs.isNotEmpty) ...[
              _SectionTitle(viable ? 'Recommendations' : 'Why Not Viable'),
              const SizedBox(height: 10),
              ...recs.asMap().entries.map((e) => _RecommendationTile(
                text: e.value,
                viable: viable,
                index: e.key,
              )),
              const SizedBox(height: 20),
            ],

            // ── Location (geo only) ────────────────
            if (isGeo && lat != null) ...[
              _SectionTitle('Location'),
              const SizedBox(height: 10),
              _LocationCard(lat: lat!, lng: lng!),
              const SizedBox(height: 20),
            ],

            // ── Annual yield projection ────────────
            if (viable) ...[
              _SectionTitle('12-Month Yield Projection'),
              const SizedBox(height: 10),
              _YieldChart(monthlyYield: yield_),
              const SizedBox(height: 20),
            ],

            // ── Actions ────────────────────────────
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: viable ? AppTheme.primary : AppTheme.notViable,
              ),
              child: Text(viable
                  ? 'Analyse Another Location'
                  : 'Try a Different Location'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Verdict Banner ────────────────────────────────────────────
class _VerdictBanner extends StatelessWidget {
  final bool viable;
  final double probability;
  const _VerdictBanner({required this.viable, required this.probability});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: viable
            ? [const Color(0xFF1B6B45), AppTheme.viable]
            : [const Color(0xFF8B2117), AppTheme.notViable],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              viable ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white, size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            viable ? 'VIABLE SITE' : 'NOT VIABLE',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          viable
              ? 'This location shows strong potential for saltern establishment.'
              : 'Current conditions do not support salt production at this location.',
          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white20,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${probability.toStringAsFixed(1)}% confidence',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
        ),
      ],
    ),
  );
}

// ── Gauge Card ────────────────────────────────────────────────
class _GaugeCard extends StatelessWidget {
  final double probability;
  final bool viable;
  const _GaugeCard({required this.probability, required this.viable});

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: [
      Text('Viability Score', style: GoogleFonts.dmSans(
        fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 8),
      Expanded(
        child: PieChart(PieChartData(
          startDegreeOffset: 270,
          sectionsSpace: 0,
          centerSpaceRadius: 28,
          sections: [
            PieChartSectionData(
              value: probability,
              color: viable ? AppTheme.viable : AppTheme.notViable,
              radius: 14,
              showTitle: false,
            ),
            PieChartSectionData(
              value: 100 - probability,
              color: AppTheme.border,
              radius: 14,
              showTitle: false,
            ),
          ],
        )),
      ),
      Text('${probability.toStringAsFixed(1)}%',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: viable ? AppTheme.viable : AppTheme.notViable,
          )),
    ]),
  );
}

// ── Yield Card ────────────────────────────────────────────────
class _YieldCard extends StatelessWidget {
  final double yield_;
  const _YieldCard({required this.yield_});

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.accent.withOpacity(0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.inventory_2_outlined, color: AppTheme.accent, size: 28),
        const SizedBox(height: 10),
        Text('${yield_.toStringAsFixed(2)}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.accent,
            )),
        Text('tons / month', style: GoogleFonts.dmSans(
          fontSize: 12, color: AppTheme.textMid,
        )),
        const SizedBox(height: 4),
        Text('Est. ${(yield_ * 12).toStringAsFixed(1)}t/year',
            style: GoogleFonts.dmSans(
              fontSize: 11, color: AppTheme.textLight,
            )),
      ],
    ),
  );
}

class _NotViableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.notViable.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.notViable.withOpacity(0.2)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.block_rounded, color: AppTheme.notViable, size: 28),
        const SizedBox(height: 10),
        Text('No Yield', style: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.notViable,
        )),
        Text('Conditions must improve before production is possible.',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textMid)),
      ],
    ),
  );
}

// ── Climate Grid ──────────────────────────────────────────────
class _ClimateGrid extends StatelessWidget {
  final Map<String, dynamic> climate;
  const _ClimateGrid({required this.climate});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.1,
    children: [
      _ClimateCell(icon: Icons.thermostat_rounded,
          label: 'Temp', value: '${(climate['temperature'] as num).toStringAsFixed(1)}°C',
          color: Colors.orange),
      _ClimateCell(icon: Icons.water_drop_outlined,
          label: 'Rainfall', value: '${(climate['rainfall'] as num).toStringAsFixed(1)}mm',
          color: Colors.blue),
      _ClimateCell(icon: Icons.air_rounded,
          label: 'Wind', value: '${(climate['wind_speed'] as num).toStringAsFixed(1)}km/h',
          color: Colors.teal),
      _ClimateCell(icon: Icons.opacity_outlined,
          label: 'Humidity', value: '${climate['humidity']}%',
          color: Colors.indigo),
      _ClimateCell(icon: Icons.wb_sunny_rounded,
          label: 'Solar', value: '${climate['solar_radiation']}kWh',
          color: Colors.amber),
      _ClimateCell(icon: Icons.waves_rounded,
          label: 'Evap.', value: '${(climate['evaporation_index'] as num).toStringAsFixed(2)}',
          color: AppTheme.primary),
    ],
  );
}

class _ClimateCell extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ClimateCell({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark,
        )),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 10, color: AppTheme.textLight,
        )),
      ],
    ),
  );
}

// ── Recommendation Tile ───────────────────────────────────────
class _RecommendationTile extends StatelessWidget {
  final String text;
  final bool viable;
  final int index;
  const _RecommendationTile({required this.text, required this.viable,
      required this.index});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: (viable ? AppTheme.viable : AppTheme.notViable).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            viable ? Icons.lightbulb_outline_rounded : Icons.warning_amber_rounded,
            size: 16,
            color: viable ? AppTheme.viable : AppTheme.notViable,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(
        fontSize: 13, color: AppTheme.textDark,
      ))),
    ]),
  );
}

// ── Location Card ─────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  final double lat, lng;
  const _LocationCard({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selected Coordinates', style: GoogleFonts.dmSans(
          fontSize: 11, color: AppTheme.textMid,
        )),
        Text('${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
            style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark,
            )),
      ]),
    ]),
  );
}

// ── Yield Chart ───────────────────────────────────────────────
class _YieldChart extends StatelessWidget {
  final double monthlyYield;
  const _YieldChart({required this.monthlyYield});

  static const _monthLabels = ['J','F','M','A','M','J','J','A','S','O','N','D'];
  // Seasonal multipliers for Sri Lanka dry zone
  static const _seasonality = [
    1.1, 1.15, 1.2, 1.1, 0.95, 0.7, 0.65, 0.7, 0.8, 0.9, 1.0, 1.05
  ];

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(12, (i) =>
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: monthlyYield * _seasonality[i],
            color: AppTheme.primary.withOpacity(0.7 + _seasonality[i] * 0.1),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          )
        ]));

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: BarChart(BarChartData(
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppTheme.border, strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Text(
              _monthLabels[v.toInt()],
              style: GoogleFonts.dmSans(fontSize: 10, color: AppTheme.textMid),
            ),
          )),
        ),
      )),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17));
}
