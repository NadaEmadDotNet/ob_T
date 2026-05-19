import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class StatisticsPage extends StatefulWidget {
  final bool embedded;

  const StatisticsPage({super.key, this.embedded = false});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final content = AppBackground(
      padding: EdgeInsets.fromLTRB(18, widget.embedded ? 18 : 90, 18, widget.embedded ? 96 : 20),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getObligations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList();
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) return const _EmptyAnalytics();

          final stats = _Stats.fromDocs(docs, _parseDate);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Staggered(index: 0, child: _HeroAnalytics(stats: stats)),
                const SizedBox(height: 16),
                _MetricGrid(stats: stats),
                const SizedBox(height: 16),
                _Staggered(index: 5, child: _PriorityBreakdown(stats: stats)),
                const SizedBox(height: 16),
                _Staggered(index: 6, child: _CompletionPanel(stats: stats)),
                const SizedBox(height: 16),
                _Staggered(index: 7, child: _CategoryPanel(pieData: stats.categorySpend)),
                const SizedBox(height: 16),
                _Staggered(index: 8, child: _RecentDueList(stats: stats, parseDate: _parseDate)),
              ],
            ),
          );
        },
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w900))),
      body: content,
    );
  }
}

class _Stats {
  final int completed;
  final int pending;
  final int overdue;
  final int high;
  final int medium;
  final int low;
  final int thisMonth;
  final Map<String, double> categorySpend;
  final List<Map<String, dynamic>> recent;

  const _Stats({
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.high,
    required this.medium,
    required this.low,
    required this.thisMonth,
    required this.categorySpend,
    required this.recent,
  });

  int get total => completed + pending + overdue;
  int get open => pending + overdue;

  factory _Stats.fromDocs(List<Map<String, dynamic>> docs, DateTime Function(dynamic) parseDate) {
    var completed = 0;
    var pending = 0;
    var overdue = 0;
    var high = 0;
    var medium = 0;
    var low = 0;
    var thisMonth = 0;
    final categorySpend = {for (final category in AppData.categories) category: 0.0};
    final now = DateTime.now();

    for (final data in docs) {
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      final isPaid = obligationIsPaid(data);
      final priority = obligationPriority(data)?.toLowerCase();
      final date = parseDate(data['dueDate']);
      final category = AppData.categories.contains(data['category']) ? data['category'].toString() : 'Others';

      if (date.month == now.month && date.year == now.year) thisMonth++;
      if (isPaid) {
        completed++;
      } else if (priority == 'overdue') {
        overdue++;
      } else {
        pending++;
      }

      if (priority == 'high') high++;
      if (priority == 'medium') medium++;
      if (priority == 'low') low++;
      categorySpend[category] = (categorySpend[category] ?? 0) + amount;
    }

    final recent = [...docs]..sort((a, b) => parseDate(a['dueDate']).compareTo(parseDate(b['dueDate'])));

    return _Stats(
      completed: completed,
      pending: pending,
      overdue: overdue,
      high: high,
      medium: medium,
      low: low,
      thisMonth: thisMonth,
      categorySpend: categorySpend..removeWhere((_, value) => value == 0),
      recent: recent.take(5).toList(),
    );
  }
}

class _HeroAnalytics extends StatelessWidget {
  final _Stats stats;

  const _HeroAnalytics({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF8F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepTeal.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistics', style: TextStyle(color: AppColors.ink, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('A calm analytics dashboard for every obligation.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _MiniMetric(label: 'Total', value: stats.total, color: AppColors.teal),
                    const SizedBox(width: 10),
                    _MiniMetric(label: 'Open', value: stats.open, color: AppColors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.teal),
                const SizedBox(height: 6),
                _AnimatedCounter(value: stats.completed, color: AppColors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedCounter(value: value, color: color),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final _Stats stats;

  const _MetricGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final metrics = [
      _MetricData('Overdue', stats.overdue, Icons.warning_rounded, AppColors.red),
      _MetricData('Completed', stats.completed, Icons.check_circle_rounded, AppColors.green),
      _MetricData('Pending', stats.pending, Icons.schedule_rounded, AppColors.orange),
      _MetricData('This month', stats.thisMonth, Icons.calendar_month_rounded, AppColors.teal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 680 ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) => _Staggered(index: index + 1, child: _StatCard(data: metrics[index])),
    );
  }
}

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatefulWidget {
  final _MetricData data;

  const _StatCard({required this.data});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _hover ? -5.0 : 0.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.data.color.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: widget.data.color.withValues(alpha: _hover ? 0.18 : 0.10),
              blurRadius: _hover ? 26 : 16,
              offset: Offset(0, _hover ? 14 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.data.icon, color: widget.data.color),
            const Spacer(),
            _AnimatedCounter(value: widget.data.value, color: AppColors.ink),
            Text(widget.data.label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PriorityBreakdown extends StatelessWidget {
  final _Stats stats;

  const _PriorityBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Overdue', stats.overdue, AppColors.red),
      ('High', stats.high, AppColors.orange),
      ('Medium', stats.medium, AppColors.yellow),
      ('Low', stats.low, AppColors.green),
    ];
    final maxValue = rows.map((row) => row.$2).fold<int>(1, (max, value) => value > max ? value : max);

    return _DashboardCard(
      title: 'Priority Breakdown',
      icon: Icons.stacked_bar_chart_rounded,
      child: SizedBox(
        height: 230,
        child: BarChart(
          BarChartData(
            maxY: maxValue.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.muted.withValues(alpha: 0.10), strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= rows.length) return const SizedBox.shrink();
                    return Text(rows[index].$1, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800));
                  },
                ),
              ),
            ),
            barGroups: rows.asMap().entries.map((entry) {
              final row = entry.value;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: row.$2 == 0 ? 0.08 : row.$2.toDouble(),
                    color: row.$3,
                    width: 28,
                    borderRadius: BorderRadius.circular(10),
                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxValue.toDouble(), color: row.$3.withValues(alpha: 0.08)),
                  ),
                ],
              );
            }).toList(),
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  final _Stats stats;

  const _CompletionPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = [
      stats.completed,
      stats.pending,
      stats.overdue,
      1,
    ].reduce((value, element) => value > element ? value : element).toDouble();

    return _DashboardCard(
      title: 'Completed vs Pending',
      icon: Icons.donut_large_rounded,
      child: SizedBox(
        height: 230,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.muted.withValues(alpha: 0.10), strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final labels = ['Done', 'Pending', 'Overdue'];
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                    return Text(labels[index], style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700));
                  },
                ),
              ),
            ),
            barGroups: [
              _bar(0, stats.completed.toDouble(), maxY, AppColors.green),
              _bar(1, stats.pending.toDouble(), maxY, AppColors.orange),
              _bar(2, stats.overdue.toDouble(), maxY, AppColors.red),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, double maxY, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y == 0 ? 0.08 : y,
          color: color,
          width: 34,
          borderRadius: BorderRadius.circular(10),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: color.withValues(alpha: 0.08)),
        ),
      ],
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  final Map<String, double> pieData;

  const _CategoryPanel({required this.pieData});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.teal,
      AppColors.orange,
      AppColors.green,
      AppColors.red,
      const Color(0xFF5E8CFF),
      const Color(0xFF9B6CFF),
      const Color(0xFF00A6A6),
      AppColors.yellow,
    ];

    return _DashboardCard(
      title: 'Spend by Category',
      icon: Icons.pie_chart_rounded,
      child: pieData.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No category data yet')),
            )
          : SizedBox(
              height: 270,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 58,
                  sections: pieData.entries.toList().asMap().entries.map((entry) {
                    final item = entry.value;
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: item.value,
                      radius: 82,
                      title: item.key,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    );
                  }).toList(),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeOutCubic,
              ),
            ),
    );
  }
}

class _RecentDueList extends StatelessWidget {
  final _Stats stats;
  final DateTime Function(dynamic) parseDate;

  const _RecentDueList({required this.stats, required this.parseDate});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Upcoming Focus',
      icon: Icons.event_note_rounded,
      child: Column(
        children: stats.recent.asMap().entries.map((entry) {
          final item = entry.value;
          final date = parseDate(item['dueDate']);
          final priority = obligationPriority(item);
          final color = priorityColor(priority);
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + entry.key * 70),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  Icon(categoryIcon(item['category']?.toString()), color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item['title']?.toString() ?? 'Obligation', style: const TextStyle(fontWeight: FontWeight.w900))),
                  Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepTeal.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final int value;
  final Color color;

  const _AnimatedCounter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        animated.round().toString(),
        style: TextStyle(color: color, fontSize: 25, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  final int index;
  final Widget child;

  const _Staggered({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 65),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 22 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, color: AppColors.teal, size: 58),
          SizedBox(height: 12),
          Text('No analytics yet', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19)),
          SizedBox(height: 4),
          Text('Add obligations to unlock your dashboard.', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}