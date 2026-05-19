import 'package:flutter/material.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class SearchPage extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onChanged;

  const SearchPage({
    super.key,
    this.embedded = false,
    this.onChanged,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();
  String searchType = 'Title';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getObligations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  String _displayDate(dynamic value) {
    final d = _parseDate(value);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final content = AppBackground(
      padding: EdgeInsets.fromLTRB(18, widget.embedded ? 18 : 90, 18, widget.embedded ? 96 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            const Text('Search', style: TextStyle(color: AppColors.ink, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Find obligations by title, category, status, priority, or date.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
          ],
          _buildSearchInput(),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList();
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                final docs = _filtered(snapshot.data ?? []);
                if (docs.isEmpty) {
                  return const _SearchEmpty();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _SearchResultCard(data: docs[index], index: index),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Search', style: TextStyle(fontWeight: FontWeight.w900))),
      body: content,
    );
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> docs) {
    final query = searchController.text.toLowerCase().trim();
    if (query.isEmpty) return docs;

    return docs.where((data) {
      switch (searchType) {
        case 'Category':
          return (data['category'] ?? '').toString().toLowerCase() == query;
        case 'Priority':
          return obligationPriority(data)?.toLowerCase() == query;
        case 'Status':
          final status = (data['displayStatus'] ?? data['status'] ?? '').toString().toLowerCase();
          return status == query || (query == 'unpaid' && status == 'unpaid');
        case 'Date':
          return _displayDate(data['dueDate']) == query;
        default:
          return (data['title'] ?? '').toString().toLowerCase().contains(query);
      }
    }).toList();
  }

  Widget _buildSearchInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            readOnly: searchType != 'Title',
            onTap: () {
              if (searchType == 'Date') _pickDate();
              if (searchType == 'Category') _showOptions(AppData.categories);
              if (searchType == 'Priority') _showOptions(AppData.priorities);
              if (searchType == 'Status') _showOptions(AppData.statuses);
            },
            decoration: InputDecoration(
              hintText: 'Search by $searchType',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded, color: AppColors.teal),
            onSelected: (value) {
              setState(() {
                searchType = value;
                searchController.clear();
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Title', child: Text('Title')),
              PopupMenuItem(value: 'Category', child: Text('Category')),
              PopupMenuItem(value: 'Status', child: Text('Status')),
              PopupMenuItem(value: 'Priority', child: Text('Priority')),
              PopupMenuItem(value: 'Date', child: Text('Date')),
            ],
          ),
        ),
      ],
    );
  }

  void _showOptions(List<String> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => ActionChip(
                  avatar: searchType == 'Category'
                      ? Icon(categoryIcon(option), size: 18, color: AppColors.teal)
                      : null,
                  label: Text(option),
                  onPressed: () {
                    setState(() => searchController.text = option);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => searchController.text = _displayDate(picked));
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _SearchResultCard({required this.data, required this.index});

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final priority = obligationPriority(data);
    final category = data['category']?.toString() ?? 'Others';
    final date = _parseDate(data['dueDate']);
    final amount = ((data['amount'] ?? 0) as num).toDouble();
    final paid = ((data['paid'] ?? 0) as num).toDouble();
    final isPaid = obligationIsPaid(data);
    final progress = amount > 0 ? paid / amount : 0.0;
    final accent = isPaid ? AppColors.green : priorityColor(priority);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE9FBF5), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(categoryIcon(category), color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title']?.toString() ?? 'No title', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('$category - ${date.day}/${date.month}/${date.year}', style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    if (priority != null) PriorityBadge(priority: priority),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedMoneyProgress(
              value: isPaid ? 1 : progress,
              label: 'Amount paid',
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppColors.teal),
            SizedBox(height: 12),
            Text('No matching obligations', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}