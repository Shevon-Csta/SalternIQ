import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'manual_predict_screen.dart';
import 'geo_predict_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getDashboardStats();
      setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryDark, AppTheme.primary],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good day,',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white60, fontSize: 14,
                                  )),
                              Text(auth.userName,
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white, fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  )),
                              if (auth.farmName != 'My Saltern')
                                Text(auth.farmName,
                                    style: GoogleFonts.dmSans(
                                      color: AppTheme.accent, fontSize: 13,
                                    )),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: PopupMenuButton(
                              icon: const Icon(Icons.more_vert_rounded,
                                  color: Colors.white),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  child: const Row(children: [
                                    Icon(Icons.logout_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Sign Out'),
                                  ]),
                                  onTap: () => auth.logout(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Stats row ──────────────────────────
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_stats != null) ...[
                    _StatsRow(stats: _stats!),
                    const SizedBox(height: 24),
                  ],

                  // ── Quick actions ──────────────────────
                  Text('Analyse a Location',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Choose how you want to run a viability prediction',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),

                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'Geo Analysis',
                    subtitle: 'Tap a location on Sri Lanka map — we fetch real climate data automatically',
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GeoPredictScreen()))
                        .then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.tune_rounded,
                    title: 'Manual Analysis',
                    subtitle: 'Enter climate and land parameters manually for detailed control',
                    color: const Color(0xFF2563EB),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ManualPredictScreen()))
                        .then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 24),

                  // ── History preview ────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Predictions',
                          style: Theme.of(context).textTheme.headlineMedium),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen())),
                        child: Text('See all',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.primary, fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RecentPredictions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(
        label: 'Total Analyses',
        value: '${stats['total_predictions']}',
        icon: Icons.analytics_outlined,
        color: AppTheme.primary,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        label: 'Viable Sites',
        value: '${stats['viable_count']}',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.viable,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        label: 'Avg Yield',
        value: '${stats['avg_estimated_yield']}t',
        icon: Icons.inventory_2_outlined,
        color: AppTheme.accent,
      )),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: color,
        )),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, color: AppTheme.textMid,
        )),
      ],
    ),
  );
}

// ── Action Card ───────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              )),
              const SizedBox(height: 3),
              Text(subtitle, style: GoogleFonts.dmSans(
                fontSize: 12, color: AppTheme.textMid,
              )),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
      ]),
    ),
  );
}

// ── Recent Predictions ────────────────────────────────────────
class _RecentPredictions extends StatefulWidget {
  @override
  State<_RecentPredictions> createState() => _RecentPredictionsState();
}

class _RecentPredictionsState extends State<_RecentPredictions> {
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
      setState(() { _items = history.take(3).toList(); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Column(children: [
            const Icon(Icons.history_rounded, color: AppTheme.textLight, size: 40),
            const SizedBox(height: 8),
            Text('No predictions yet', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      );
    }
    return Column(
      children: _items.map((p) => _PredictionTile(prediction: p)).toList(),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final dynamic prediction;
  const _PredictionTile({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final viable = prediction['viable'] == 1;
    final prob = ((prediction['viability_probability'] ?? 0) * 100).toStringAsFixed(1);
    final date = prediction['created_at']?.toString().substring(0, 10) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (viable ? AppTheme.viable : AppTheme.notViable).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            viable ? Icons.check_rounded : Icons.close_rounded,
            color: viable ? AppTheme.viable : AppTheme.notViable,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(viable ? 'Viable Site' : 'Not Viable',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: viable ? AppTheme.viable : AppTheme.notViable,
                  )),
              Text('$prob% confidence · $date',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (viable)
          Text('${prediction['estimated_yield']?.toStringAsFixed(1) ?? '0'}t',
              style: GoogleFonts.dmSans(
                color: AppTheme.accent, fontWeight: FontWeight.w700,
              )),
      ]),
    );
  }
}
