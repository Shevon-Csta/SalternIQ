import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await ApiService.getHistory();
      setState(() { _items = history; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prediction History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded,
                          color: AppTheme.textLight, size: 60),
                      const SizedBox(height: 12),
                      Text('No predictions yet',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text('Run your first analysis to see results here.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _HistoryCard(prediction: _items[i]),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic prediction;
  const _HistoryCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final viable = prediction['viable'] == 1;
    final prob   = ((prediction['viability_probability'] ?? 0) * 100);
    final yield_ = prediction['estimated_yield'] ?? 0.0;
    final date   = prediction['created_at']?.toString().substring(0, 16) ?? '';
    final hasGeo = prediction['latitude'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (viable ? AppTheme.viable : AppTheme.notViable)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(
                      viable ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      size: 14,
                      color: viable ? AppTheme.viable : AppTheme.notViable,
                    ),
                    const SizedBox(width: 4),
                    Text(viable ? 'Viable' : 'Not Viable',
                        style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: viable ? AppTheme.viable : AppTheme.notViable,
                        )),
                  ]),
                ),
                if (hasGeo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Geo',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ]),
              Text(date, style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textLight,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DataChip(icon: Icons.percent_rounded,
                  label: '${prob.toStringAsFixed(1)}% confidence'),
              const SizedBox(width: 8),
              if (viable)
                _DataChip(icon: Icons.inventory_2_outlined,
                    label: '${yield_.toStringAsFixed(2)} t/month'),
              const SizedBox(width: 8),
              _DataChip(icon: Icons.landscape_outlined,
                  label: '${prediction['land_area']?.toStringAsFixed(1) ?? '-'} acres'),
            ],
          ),
          if (hasGeo) ...[
            const SizedBox(height: 8),
            Text(
              '${(prediction['latitude'] as num).toStringAsFixed(4)}° N, '
              '${(prediction['longitude'] as num).toStringAsFixed(4)}° E',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textMid,
              ),
            ),
          ],
          if (prediction['notes'] != null && prediction['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(prediction['notes'],
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textMid,
                  fontStyle: FontStyle.italic,
                )),
          ],
        ],
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DataChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      Icon(icon, size: 12, color: AppTheme.textMid),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 11, color: AppTheme.textMid,
      )),
    ]),
  );
}
