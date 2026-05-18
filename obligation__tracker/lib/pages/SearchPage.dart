import 'package:flutter/material.dart';
import 'package:obligation__tracker/services/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  String searchType = "Title";
  late Future<List<Map<String, dynamic>>> _future;

  final List<String> categories = ["University", "Installments", "Shopping", "Home", "Bills", "Other"];
  final List<String> priorities = ["High", "Medium", "Low"];
  final List<String> statusOptions = ["Paid", "Unpaid"];

  @override
  void initState() {
    super.initState();
    _future = ApiService.getObligations();
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search My Obligations"),
        backgroundColor: const Color(0xFFAEECE4),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_customize),
          onPressed: () => Navigator.pop(context),
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data ?? [];
                  if (docs.isEmpty) return const Center(child: Text("No obligations found."));

                  final filteredDocs = docs.where((data) {
                    final query = searchController.text.toLowerCase().trim();
                    if (query.isEmpty) return true;

                    switch (searchType) {
                      case "Category":
                        return (data['category'] ?? "").toString().toLowerCase() == query;
                      case "Priority":
                        return (data['priority'] ?? "").toString().toLowerCase() == query;
                      case "Status":
                        final isPaid = data['isPaid'] == true || data['status'] == 'paid';
                        return (query == "paid" && isPaid) || (query == "unpaid" && !isPaid);
                      case "Date":
                        final d = _parseDate(data['dueDate']);
                        final formatted = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
                        return formatted == query;
                      default:
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
        itemBuilder: (context) => const [
          PopupMenuItem(value: "Title", child: Text("Search by Title")),
          PopupMenuItem(value: "Category", child: Text("Select Category")),
          PopupMenuItem(value: "Status", child: Text("Select Status")),
          PopupMenuItem(value: "Priority", child: Text("Select Priority")),
          PopupMenuItem(value: "Date", child: Text("Select Date")),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    final d = _parseDate(data['dueDate']);
    final displayDate = "${d.day}/${d.month}/${d.year}";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data['category']} - $displayDate"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("\$${data['amount'] ?? 0}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            Text(
              data['priority'] ?? 'Low',
              style: TextStyle(color: _getPriorityColor(data['priority']), fontSize: 10, fontWeight: FontWeight.bold),
            ),
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
