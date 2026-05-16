import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String searchType = "Title"; 

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  
  final List<String> categories = ["University", "Installments", "Shopping", "Home", "Bills", "Other"];
  final List<String> priorities = ["High", "Medium", "Low"];
  final List<String> statusOptions = ["Paid", "Unpaid"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search My Obligations"),
        backgroundColor: const Color(0xFFAEECE4),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_customize),
          onPressed: () => Navigator.pop(context), // العودة للـ Dashboard
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAEECE4), Color(0xFFF8EEDC)],
          ),
        ),
        child: Column(
          children: [
            _buildSearchInput(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('obligations')
                    .where('userId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No obligations found."));
                  }

                  
                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String query = searchController.text.toLowerCase().trim();

                    if (query.isEmpty) return true;

                    switch (searchType) {
                      case "Category":
                        return (data['category'] ?? "").toString().toLowerCase() == query;
                      case "Priority":
                        return (data['priority'] ?? "").toString().toLowerCase() == query;
                      case "Status":
                        bool isPaid = data['isPaid'] ?? false;
                        return (query == "paid" && isPaid) || (query == "unpaid" && !isPaid);
                      case "Date":
                        if (data['date'] == null) return false;
                        DateTime d = (data['date'] as Timestamp).toDate();
                        String formatted = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
                        return formatted == query;
                      default: // Title
                        return (data['title'] ?? "").toString().toLowerCase().contains(query);
                    }
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) => _buildCard(filteredDocs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              readOnly: searchType != "Title",
              onTap: () {
                if (searchType == "Date") _pickDate();
                if (searchType == "Category") _showOptions(categories);
                if (searchType == "Priority") _showOptions(priorities);
                if (searchType == "Status") _showOptions(statusOptions);
              },
              decoration: InputDecoration(
                hintText: "Search by $searchType",
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.tune, color: Colors.teal),
        onSelected: (val) {
          setState(() {
            searchType = val;
            searchController.clear();
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: "Title", child: Text("Search by Title")),
          const PopupMenuItem(value: "Category", child: Text("Select Category")),
          const PopupMenuItem(value: "Status", child: Text("Select Status")),
          const PopupMenuItem(value: "Priority", child: Text("Select Priority")),
          const PopupMenuItem(value: "Date", child: Text("Select Date")),
        ],
      ),
    );
  }

  Widget _buildCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    
    String displayDate = "No Date";
    if (data['date'] != null) {
      DateTime d = (data['date'] as Timestamp).toDate();
      displayDate = "${d.day}/${d.month}/${d.year}";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data['category']} • $displayDate"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("\$${data['amount'] ?? 0}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            Text(data['priority'] ?? 'Low', 
                style: TextStyle(color: _getPriorityColor(data['priority']), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  
  void _showOptions(List<String> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: options.map((opt) => ListTile(
          title: Text(opt, textAlign: TextAlign.center),
          onTap: () {
            setState(() => searchController.text = opt);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        searchController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Color _getPriorityColor(String? p) {
    if (p == "High") return Colors.red;
    if (p == "Medium") return Colors.orange;
    return Colors.green;
  }
}