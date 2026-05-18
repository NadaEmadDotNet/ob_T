import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/AddObligationPage.dart';
import 'package:obligation__tracker/pages/EditObligationPage.dart';
import 'package:obligation__tracker/pages/HomePage.dart';
import 'package:obligation__tracker/pages/SearchPage.dart';
import 'package:obligation__tracker/pages/StatisticsPage.dart';
import 'package:obligation__tracker/pages/UserSettingPage.dart';
import 'package:obligation__tracker/services/api_service.dart';

class ObligationsScreen extends StatefulWidget {
  const ObligationsScreen({super.key});

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  late Future<List<Map<String, dynamic>>> _obligationsFuture;

  @override
  void initState() {
    super.initState();
    _loadObligations();
  }

  void _loadObligations() {
    _obligationsFuture = ApiService.getObligations();
  }

  Future<void> _refresh() async {
    setState(_loadObligations);
    await _obligationsFuture;
  }

  int getTotalFromDocs(List<Map<String, dynamic>> docs) {
    return docs.fold(0, (sum, data) => sum + ((data['amount'] ?? 0) as num).toInt());
  }

  int getPaidFromDocs(List<Map<String, dynamic>> docs) {
    return docs.fold(0, (sum, data) => sum + ((data['paid'] ?? 0) as num).toInt());
  }

  int getRemainingFromDocs(List<Map<String, dynamic>> docs) {
    return getTotalFromDocs(docs) - getPaidFromDocs(docs);
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    return date.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      backgroundColor: const Color(0xFFAEECE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Obligations Tracker",
          style: TextStyle(
            color: Color(0xFF2F5F63),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF2F5F63), size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
              _refresh();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFAEECE4), Color(0xFFF8EEDC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _obligationsFuture,
              builder: (context, snapshot) {
                final docs = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      getTotalFromDocs(docs),
                      getPaidFromDocs(docs),
                      getRemainingFromDocs(docs),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Obligations List",
                        style: TextStyle(
                          color: Color(0xFF2F5F63),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildList(snapshot, docs),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddObligationPage(),
                            ),
                          );
                          if (result == true) _refresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5F63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          child: Text("Add New Obligation"),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    List<Map<String, dynamic>> docs,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text("Error: ${snapshot.error}"));
    }
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          "No obligations added yet.",
          style: TextStyle(color: Color(0xFF2F5F63), fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, idx) {
          final obligation = docs[idx];
          final docId = obligation["_id"].toString();
          final amount = ((obligation["amount"] ?? 0) as num).toInt();
          final paid = ((obligation["paid"] ?? 0) as num).toInt();
          final isPaid = obligation["isPaid"] == true || obligation["status"] == "paid";

          return _buildObligationCard(
            docId,
            obligation["title"] ?? "",
            obligation["category"] ?? "General",
            obligation["priority"] ?? "Low",
            amount,
            paid,
            isPaid,
            "",
            _formatDate(obligation["dueDate"]),
            idx,
            context,
            (bool newStatus) async {
              await ApiService.updateObligation(docId, {
                "isPaid": newStatus,
                "paid": newStatus ? amount : 0,
              });
              _refresh();
            },
            () async {
              await ApiService.deleteObligation(docId);
              _refresh();
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFE8F6F4),
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F5F63), Color(0xFFAEECE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFF2F5F63)),
              title: const Text(
                "Statistics",
                style: TextStyle(fontSize: 16, color: Color(0xFF2F5F63)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF2F5F63)),
              title: const Text(
                "Settings",
                style: TextStyle(fontSize: 16, color: Color(0xFF2F5F63)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Log Out",
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
              onTap: () async {
                await ApiService.clearToken();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int total, int paid, int remaining) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryBox(Icons.attach_money, "Total", "\$$total"),
        _buildSummaryBox(Icons.check_circle, "Total Paid", "\$$paid"),
        _buildSummaryBox(Icons.hourglass_bottom, "Remaining", "\$$remaining"),
      ],
    );
  }

  Widget _buildSummaryBox(IconData icon, String title, String value) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF2F5F63), size: 20),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F5F63),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2F5F63),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObligationCard(
    String objId,
    String title,
    String category,
    String priority,
    int amount,
    int paid,
    bool isPaid,
    String type,
    String date,
    int index,
    BuildContext context,
    Future<void> Function(bool) onStatusChanged,
    Future<void> Function() onDelete,
  ) {
    double progress = (amount > 0) ? (paid / amount).clamp(0.0, 1.0) : 0.0;

    Color priorityColor = priority.toLowerCase() == 'high'
        ? Colors.redAccent
        : (priority.toLowerCase() == 'medium'
            ? Colors.orangeAccent
            : Colors.blueAccent);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 148, 199, 194),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2F5F63),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF2F5F63),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Amount: \$$amount", style: const TextStyle(color: Colors.white)),
          Text("Paid: \$$paid", style: const TextStyle(color: Colors.white)),
          Text(
            "Date: $date",
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isPaid ? 1.0 : progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                isPaid ? const Color(0xFF4DB482) : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color.fromARGB(255, 194, 243, 237),
                      title: const Text(
                        'Payment Status',
                        style: TextStyle(color: Color(0xFF2F5F63)),
                      ),
                      content: Text(
                        isPaid
                            ? "This obligation is paid."
                            : "This obligation is not paid.",
                        style: const TextStyle(color: Color(0xFF2F5F63)),
                      ),
                      actions: [
                        if (isPaid)
                          TextButton(
                            onPressed: () async {
                              await onStatusChanged(false);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text(
                              'Mark as Not Paid',
                              style: TextStyle(color: Color(0xFFC24B4B)),
                            ),
                          ),
                        if (!isPaid)
                          TextButton(
                            onPressed: () async {
                              await onStatusChanged(true);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text(
                              'Mark as Paid',
                              style: TextStyle(color: Color(0xFF4DB482)),
                            ),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFF4DB482) : const Color(0xFFC24B4B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? "Paid" : "Not Paid",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Editpage(
                            docId: objId,
                            title: title,
                            category: category,
                            priority: priority,
                            amount: amount,
                            paid: paid,
                            isPaid: isPaid,
                            type: type,
                            date: DateTime.parse(date),
                            index: index,
                          ),
                        ),
                      );
                      if (result == true) _refresh();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color.fromARGB(255, 194, 243, 237),
                          title: const Text(
                            'Delete Confirmation',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                          content: const Text(
                            'Are you sure you want to delete this obligation?',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF2F5F63)),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await onDelete();
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFC24B4B)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
