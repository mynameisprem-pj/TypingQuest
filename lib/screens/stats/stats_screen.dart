import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/stats_service.dart';
import '../../services/profile_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool   _loading        = true;
  int    _bestWpm        = 0;
  double _avgAccuracy    = 0;
  int    _totalWords     = 0;
  int    _totalSeconds   = 0;
  int    _totalSessions  = 0;
  List<MapEntry<DateTime, double>> _weekData   = [];
  Map<String, int>                 _modeCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = StatsService();
    // Scalar reads hit SharedPreferences directly (no JSON parsing).
    _bestWpm       = stats.getBestWpm();
    _totalWords    = stats.getTotalWords();
    _totalSeconds  = stats.getTotalTimeSeconds();
    _totalSessions = stats.getTotalSessions();
    // Aggregate reads use the in-memory session cache (single parse).
    _avgAccuracy = await stats.getAverageAccuracy();
    _weekData    = await stats.getLast7DaysWpm();
    _modeCounts  = await stats.getModeSessionCounts();
    setState(() => _loading = false);
  }

  String _formatTime(int seconds) {
    if (seconds < 60)   return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  String _formatLargeNum(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService().activeProfile;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('MY STATS',
            style: AppTheme.heading(16, color: AppTheme.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile != null) _buildProfileHeader(profile),
                  const SizedBox(height: 24),

                  // Big 4 stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap:     true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing:  14,
                    childAspectRatio: 1.8,
                    children: [
                      _BigStat(icon: '⚡', label: 'Best WPM',
                          value: '$_bestWpm',                                   color: AppTheme.primary),
                      _BigStat(icon: '🎯', label: 'Avg Accuracy',
                          value: '${_avgAccuracy.toStringAsFixed(1)}%',         color: AppTheme.gold),
                      _BigStat(icon: '📝', label: 'Words Typed',
                          value: _formatLargeNum(_totalWords),                  color: AppTheme.success),
                      _BigStat(icon: '⏱️', label: 'Time Practiced',
                          value: _formatTime(_totalSeconds),                    color: const Color(0xFFCE93D8)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _SectionHeader('7-DAY WPM TREND'),
                  const SizedBox(height: 12),
                  _buildWeekChart(),
                  const SizedBox(height: 24),

                  _SectionHeader('SESSION OVERVIEW'),
                  const SizedBox(height: 12),
                  _buildSessionsOverview(),
                  const SizedBox(height: 24),

                  if (_modeCounts.isNotEmpty) ...[
                    _SectionHeader('PRACTICE MODES'),
                    const SizedBox(height: 12),
                    _buildModeBreakdown(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primary.withValues(alpha: 0.12),
          AppTheme.gold.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text(profile.avatar, style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(profile.name, style: AppTheme.heading(20)),
          Text(profile.className,
              style: AppTheme.body(13, color: AppTheme.textSecondary)),
          Text('$_totalSessions sessions completed',
              style: AppTheme.body(12, color: AppTheme.primary)),
        ]),
      ]),
    );
  }

  Widget _buildWeekChart() {
    if (_weekData.isEmpty) return const SizedBox();
    final maxWpm     = _weekData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final displayMax = maxWpm < 10 ? 30.0 : maxWpm * 1.2;
    const days       = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today      = DateTime.now().weekday;

    // RepaintBoundary isolates bar animation repaints from the rest of the
    // scroll view — prevents the whole screen from repainting on entry.
    return RepaintBoundary(
      child: Container(
        height:   160,
        padding:  const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _weekData.asMap().entries.map((entry) {
            final i       = entry.key;
            final dayData = entry.value;
            final barH    = displayMax > 0 ? dayData.value / displayMax : 0.0;
            final isToday = dayData.key.weekday == today &&
                dayData.key.day == DateTime.now().day;
            final color   = isToday
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.4);
            final dayName = days[dayData.key.weekday - 1];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (dayData.value > 0)
                      Text('${dayData.value.toInt()}',
                          style: AppTheme.body(9, color: color)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300 + i * 60),
                      curve:    Curves.easeOut,
                      height:   (barH * 90).clamp(2.0, 90.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            const BorderRadius.vertical(
                                top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dayName,
                        style: AppTheme.body(10,
                            color: isToday
                                ? AppTheme.primary
                                : AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSessionsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SmallStat('Total Sessions',  '$_totalSessions',           AppTheme.primary),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          _SmallStat('Words Typed',     _formatLargeNum(_totalWords), AppTheme.success),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          _SmallStat('Time Practiced',  _formatTime(_totalSeconds),   const Color(0xFFCE93D8)),
        ],
      ),
    );
  }

  Widget _buildModeBreakdown() {
    const icons  = {'solo':'🎮','timed':'⏱️','lesson':'📚','custom':'✏️','lan':'🏁'};
    const colors = {
      'solo':   AppTheme.primary,
      'timed':  AppTheme.gold,
      'lesson': AppTheme.success,
      'custom': Color(0xFFCE93D8),
      'lan':    Color(0xFFFF6B35),
    };
    const names  = {
      'solo':   'Solo Practice',
      'timed':  'Timed Challenge',
      'lesson': 'Lessons',
      'custom': 'Custom Text',
      'lan':    'LAN Race',
    };

    final totalCount =
        _modeCounts.values.fold<int>(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: _modeCounts.entries.map((entry) {
          final pct   = totalCount > 0 ? entry.value / totalCount : 0.0;
          final color = colors[entry.key] ?? AppTheme.primary;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text(icons[entry.key] ?? '🎮',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                    Text(names[entry.key] ?? entry.key,
                        style: AppTheme.body(13)),
                    Text('${entry.value} sessions',
                        style: AppTheme.body(12,
                            color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value:           pct,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor:      AlwaysStoppedAnimation(color),
                      minHeight:       5,
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.body(12, color: AppTheme.textSecondary)
            .copyWith(letterSpacing: 2),
      );
}

class _BigStat extends StatelessWidget {
  final String icon, label, value;
  final Color  color;
  const _BigStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTheme.heading(22, color: color)),
            Text(label,
                style: AppTheme.body(11, color: AppTheme.textSecondary)),
          ]),
        ]),
      );
}

class _SmallStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SmallStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: AppTheme.heading(20, color: color)),
        const SizedBox(height: 3),
        Text(label,
            style: AppTheme.body(11, color: AppTheme.textSecondary)),
      ]);
}