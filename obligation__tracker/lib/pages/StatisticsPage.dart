import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:obligation__tracker/services/api_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9CE6D7),
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: Colors.blue, size: 30),
            SizedBox(width: 8),
            Text(
              "Statistics",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getObligations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No obligations added yet"));
          }

          int completed = 0;
          int pending = 0;
          int overdue = 0;
          int obligationsThisMonth = 0;
          final Map<String, double> pieData = {};
          final now = DateTime.now();

          for (final data in docs) {
            final amount = (data['amount'] ?? 0).toDouble();
            final isPaid = data['isPaid'] == true || data['status'] == 'paid';
            final date = _parseDate(data['dueDate']);

            if (date.month == now.month && date.year == now.year) {
              obligationsThisMonth++;
            }

            if (isPaid) {
              completed++;
            } else if (date.isBefore(now)) {
              overdue++;
            } else {
              pending++;
            }

            final category = data['category'] ?? 'Other';
            pieData[category] = (pieData[category] ?? 0) + amount;
          }

          docs.sort((a, b) => _parseDate(b['dueDate']).compareTo(_parseDate(a['dueDate'])));

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF9CE6D7),
                  Color(0xFF77C8C0),
                  Color(0xFFF7EFE4),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCard(title: "Completed", number: completed.toString(), color: const Color(0xFFBBDEFB), icon: Icons.check_circle),
                        HoverCard(title: "Pending", number: pending.toString(), color: const Color(0xFFE1BEE7), icon: Icons.access_time),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCard(title: "Overdue", number: overdue.toString(), color: const Color(0xFFFFCDD2), icon: Icons.warning),
                        HoverCard(title: "Total this month", number: obligationsThisMonth.toString(), color: const Color(0xFFC8E6C9), icon: Icons.calendar_today),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("Obligations by Category", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: pieData.entries.toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final colors = [
                                Colors.blue,
                                Colors.red,
                                Colors.green,
                                Colors.orange,
                                Colors.purple,
                                Colors.cyan,
                                Colors.amber,
                              ];

                              return PieChartSectionData(
                                color: colors[index % colors.length],
                                value: data.value,
                                radius: 90,
                                showTitle: true,
                                title: data.key,
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text("Recent Obligations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Column(
                      children: docs.take(5).map((data) {
                        final title = data['title'] ?? 'New obligation';
                        final date = _parseDate(data['dueDate']);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.blue, size: 12),
                              const SizedBox(width: 8),
                              Expanded(child: Text(title)),
                              Text("${date.day}/${date.month}/${date.year}"),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final String title;
  final String number;
  final Color color;
  final IconData icon;

  const HoverCard({
    required this.title,
    required this.number,
    required this.color,
    required this.icon,
    super.key,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHover
            ? (Matrix4.identity()..translate(0, -10)..scale(1.05))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: _isHover ? 15 : 5,
              offset: Offset(0, _isHover ? 10 : 3),
            ),
          ],
        ),
        width: 160,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: Colors.black54),
            const SizedBox(height: 8),
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              widget.number,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
