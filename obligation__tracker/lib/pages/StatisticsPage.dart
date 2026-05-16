import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    final uid = user.uid;
    final obligationsRef = FirebaseFirestore.instance
        .collection('obligations')
        .where('userId', isEqualTo: uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9CE6D7),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
      body: StreamBuilder<QuerySnapshot>(
        stream: obligationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No obligations added yet"));
          }

          final docs = snapshot.data!.docs;

          int completed = 0;
          int pending = 0;
          int overdue = 0;
          int obligationsThisMonth = 0;

          final Map<String, double> pieData = {};
          final now = DateTime.now();

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['amount'] ?? 0).toDouble();
            final bool isPaid = data['isPaid'] ?? false;
            final Timestamp dateTs = data['date'] ?? Timestamp.now();
            final date = dateTs.toDate();

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

          docs.sort((a, b) {
            final dateA = (a['date'] as Timestamp).toDate();
            final dateB = (b['date'] as Timestamp).toDate();
            return dateB.compareTo(dateA);
          });

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

                    /// TOP CARDS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCard(
                          title: "Completed",
                          number: completed.toString(),
                          color: const Color(0xFFBBDEFB),
                          icon: Icons.check_circle,
                        ),
                        HoverCard(
                          title: "Pending",
                          number: pending.toString(),
                          color: const Color(0xFFE1BEE7),
                          icon: Icons.access_time,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCard(
                          title: "Overdue",
                          number: overdue.toString(),
                          color: const Color(0xFFFFCDD2),
                          icon: Icons.warning,
                        ),
                        HoverCard(
                          title: "Total this month",
                          number: obligationsThisMonth.toString(),
                          color: const Color(0xFFC8E6C9),
                          icon: Icons.calendar_today,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Obligations by Category",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    /// PIE CHART (Fixed / Static)
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: pieData.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
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
                                radius: 90, // ثابت
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
                    const Text(
                      "Recent Obligations",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    Column(
                      children: docs.take(5).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'New obligation';
                        final date = (data['date'] as Timestamp).toDate();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  color: Colors.blue, size: 12),
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

/// HOVER CARD
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