import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:obligation__tracker/pages/AddObligationPage.dart';
import 'package:obligation__tracker/pages/EditObligationPage.dart';
import 'package:obligation__tracker/pages/HomePage.dart';
import 'package:obligation__tracker/pages/SearchPage.dart';
import 'package:obligation__tracker/pages/StatisticsPage.dart';
import 'package:obligation__tracker/pages/UserSettingPage.dart';

class ObligationsScreen extends StatefulWidget {
  const ObligationsScreen({super.key});

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final CollectionReference obligationsCollection = FirebaseFirestore.instance
      .collection('obligations');
  
  Stream<QuerySnapshot> getObligationsStream() {
    return obligationsCollection
        .where('userId', isEqualTo: user?.uid)
        .orderBy('date')
        .snapshots();
  }

  int getTotalFromDocs(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + ((data['amount'] ?? 0) as num).toInt();
    });
  }

  int getPaidFromDocs(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + ((data['paid'] ?? 0) as num).toInt();
    });
  }

  int getRemainingFromDocs(List<QueryDocumentSnapshot> docs) {
    return getTotalFromDocs(docs) - getPaidFromDocs(docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      backgroundColor: Color(0xFFAEECE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Obligations Tracker",
          style: TextStyle(
            color: Color(0xFF2F5F63),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF2F5F63), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFAEECE4), Color(0xFFF8EEDC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: getObligationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildSummaryRow(0, 0, 0);
                    }
                    final docs = snapshot.data?.docs ?? [];
                    return _buildSummaryRow(
                      getTotalFromDocs(docs),
                      getPaidFromDocs(docs),
                      getRemainingFromDocs(docs),
                    );
                  },
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Obligations List",
                    style: TextStyle(
                      color: Color(0xFF2F5F63),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getObligationsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No obligations added yet.",
                            style: TextStyle(
                              color: Color(0xFF2F5F63),
                              fontSize: 18,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          var obligation =
                              docs[idx].data() as Map<String, dynamic>;
                          var docId = docs[idx].id;

                          return _buildObligationCard(
                            docId,
                            obligation["title"] ?? "",
                            obligation["category"] ?? "General",
                            obligation["priority"] ?? "Normal",
                            (obligation["amount"] ?? 0).toInt(),
                            (obligation["paid"] ?? 0).toInt(),
                            obligation["isPaid"] ?? false,
                            "",
                            obligation["date"] != null
                                ? (obligation["date"] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .split(' ')[0]
                                : "",
                            idx,
                            context,
                            (bool newStatus) {
                              obligationsCollection.doc(docId).update({
                                "isPaid": newStatus,
                                "paid": newStatus ? obligation["amount"] : 0,
                              });
                            },
                            () {
                              obligationsCollection.doc(docId).delete();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddObligationPage(),
                        ),
                      );
                      if (result == true) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2F5F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      child: Text("Add New Obligation"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFFE8F6F4),
        child: ListView(
          children: [
            DrawerHeader(
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
              leading: Icon(Icons.bar_chart, color: Color(0xFF2F5F63)),
              title: Text(
                "Statistics",
                style: TextStyle(fontSize: 16, color: Color(0xFF2F5F63)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatisticsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Color(0xFF2F5F63)),
              title: Text(
                "Settings",
                style: TextStyle(fontSize: 16, color: Color(0xFF2F5F63)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserSettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                "Log Out",
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
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
          Icon(icon, color: Color(0xFF2F5F63), size: 20),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF2F5F63),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
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
    void Function(bool) onStatusChanged,
    VoidCallback onDelete,
  ) {
    print('obligation id $objId');
    double progress = (amount > 0) ? (paid / amount).clamp(0.0, 1.0) : 0.0;

    Color priorityColor = priority.toLowerCase() == 'high'
        ? Colors.redAccent
        : (priority.toLowerCase() == 'medium'
              ? Colors.orangeAccent
              : Colors.blueAccent);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 148, 199, 194),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF2F5F63),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Color(0xFF2F5F63),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text("Amount: \$$amount", style: TextStyle(color: Colors.white)),
          Text("Paid: \$$paid", style: TextStyle(color: Colors.white)),
          Text(
            "Date: $date",
            style: TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isPaid ? 1.0 : progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                isPaid ? Color(0xFF4DB482) : Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Color.fromARGB(255, 194, 243, 237),
                      title: Text(
                        'Payment Status',
                        style: TextStyle(color: Color(0xFF2F5F63)),
                      ),
                      content: Text(
                        isPaid
                            ? "This obligation is paid."
                            : "This obligation is not paid.",
                        style: TextStyle(color: Color(0xFF2F5F63)),
                      ),
                      actions: [
                        if (isPaid)
                          TextButton(
                            onPressed: () {
                              onStatusChanged(false);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Mark as Not Paid',
                              style: TextStyle(color: Color(0xFFC24B4B)),
                            ),
                          ),
                        if (!isPaid)
                          TextButton(
                            onPressed: () {
                              onStatusChanged(true);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Mark as Paid',
                              style: TextStyle(color: Color(0xFF4DB482)),
                            ),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isPaid ? Color(0xFF4DB482) : Color(0xFFC24B4B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? "Paid" : "Not Paid",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                    onPressed: () {
                      Navigator.push(
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
                            date: Timestamp.fromDate(DateTime.parse(date)),
                            index: index,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Color.fromARGB(255, 194, 243, 237),
                          title: Text(
                            'Delete Confirmation',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                          content: Text(
                            'Are you sure you want to delete this obligation?',
                            style: TextStyle(color: Color(0xFF2F5F63)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF2F5F63)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                onDelete();
                                Navigator.pop(context);
                              },
                              child: Text(
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